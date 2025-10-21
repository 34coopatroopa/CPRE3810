library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;  -- subtype word = std_logic_vector(31 downto 0)

entity regfile is
  port (
    i_CLK : in  std_logic;
    i_RST : in  std_logic;
    i_WE  : in  std_logic;                     -- write enable
    i_RD  : in  std_logic_vector(4 downto 0);  -- write register index
    i_D   : in  word;                          -- write data
    i_RS1 : in  std_logic_vector(4 downto 0);  -- read register 1 index
    i_RS2 : in  std_logic_vector(4 downto 0);  -- read register 2 index
    o_RS1 : out word;                          -- read data 1
    o_RS2 : out word                           -- read data 2
  );
end entity;

architecture Behavioral of regfile is
  type reg_array_t is array (0 to 31) of word;
  signal rf : reg_array_t := (others => (others => '0'));

  function to_idx(s : std_logic_vector(4 downto 0)) return integer is
  begin
    return to_integer(unsigned(s));
  end function;

  -- helpers for bypass compare
  signal we_s    : std_logic;
  signal rd_s    : std_logic_vector(4 downto 0);
  signal rs1_s   : std_logic_vector(4 downto 0);
  signal rs2_s   : std_logic_vector(4 downto 0);
begin
  we_s  <= i_WE;
  rd_s  <= i_RD;
  rs1_s <= i_RS1;
  rs2_s <= i_RS2;

  --------------------------------------------------------------------------
  -- Synchronous write (x0 is hard-wired to zero)
  --------------------------------------------------------------------------
  process(i_CLK)
    variable widx : integer;
  begin
    if rising_edge(i_CLK) then
      if i_RST = '1' then
        rf <= (others => (others => '0'));
      else
        rf(0) <= (others => '0');  -- x0 always 0
        if we_s = '1' then
          widx := to_idx(rd_s);
          if widx /= 0 then
            rf(widx) <= i_D;
          end if;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Asynchronous reads with single-cycle RAW bypass
  --------------------------------------------------------------------------
  -- If reading the same register being written this cycle (and not x0),
  -- return the write data (i_D) directly. Otherwise return file contents.
  o_RS1 <= i_D when (we_s = '1' and rd_s = rs1_s and rd_s /= "00000")
           else rf(to_idx(rs1_s));

  o_RS2 <= i_D when (we_s = '1' and rd_s = rs2_s and rd_s /= "00000")
           else rf(to_idx(rs2_s));
end architecture Behavioral;
