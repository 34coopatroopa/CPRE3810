library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity regfile is
  port (
    i_CLK : in  std_logic;
    i_RST : in  std_logic;
    i_WE  : in  std_logic;
    i_RD  : in  std_logic_vector(4 downto 0);
    i_D   : in  word;
    i_RS1 : in  std_logic_vector(4 downto 0);
    i_RS2 : in  std_logic_vector(4 downto 0);
    o_RS1 : out word;
    o_RS2 : out word
  );
end entity;

architecture Behavioral of regfile is
  type reg_array_t is array (0 to 31) of word;
  signal rf : reg_array_t := (others => (others => '0'));
begin
  -- sync write, async read; x0 hardwired to zero
  process(i_CLK)
    variable widx : integer;
  begin
    if rising_edge(i_CLK) then
      if i_RST='1' then
        rf <= (others => (others => '0'));
      else
        rf(0) <= (others => '0');
        if i_WE='1' then
          widx := to_integer(unsigned(i_RD));
          if widx /= 0 then
            rf(widx) <= i_D;
          end if;
        end if;
      end if;
    end if;
  end process;

  o_RS1 <= rf(to_integer(unsigned(i_RS1)));
  o_RS2 <= rf(to_integer(unsigned(i_RS2)));
end architecture;
