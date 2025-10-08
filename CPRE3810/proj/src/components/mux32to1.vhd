library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux32to1 is
  port (
    sel  : in  std_logic_vector(4 downto 0);                 -- 5-bit select
    din  : in  std_logic_vector(32*32-1 downto 0);           -- 1024-bit input bus
    dout : out std_logic_vector(31 downto 0)                 -- selected 32-bit output
  );
end entity;

architecture rtl of mux32to1 is
  type reg_array_t is array (0 to 31) of std_logic_vector(31 downto 0);
  signal regs : reg_array_t;
begin
  -- unpack flattened input bus into array
  gen_unpack: for i in 0 to 31 generate
    regs(i) <= din((i+1)*32-1 downto i*32);
  end generate;

  -- output is the selected word
  dout <= regs(to_integer(unsigned(sel)));
end architecture;
