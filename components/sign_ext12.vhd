library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_ext12 is
    port (
        imm12 : in  std_logic_vector(11 downto 0);
        imm32 : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of sign_ext12 is
begin
    imm32 <= (31 downto 12 => imm12(11)) & imm12;
end architecture;
