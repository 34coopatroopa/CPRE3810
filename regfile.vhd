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
  -- Synchronous write and architectural reset values
  --------------------------------------------------------------------------
  process(i_CLK)
    variable widx : integer;
  begin
    if rising_edge(i_CLK) then
      if i_RST = '1' then
        -- Clear all registers, then preload architectural reset values
        rf <= (others => (others => '0'));
        rf(2) <= x"7FFFFFF0";  -- Stack Pointer (sp)
        rf(5) <= x"10010000";  -- Global Pointer (gp)
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
  -- Asynchronous reads (no combinational feedback loops)
  --------------------------------------------------------------------------
  o_RS1 <= rf(to_idx(rs1_s));
  o_RS2 <= rf(to_idx(rs2_s));

end architecture Behavioral;
