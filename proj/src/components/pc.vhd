library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity pc is
    port (
        iCLK  : in  std_logic;
        iRST  : in  std_logic;
        iNext : in  word;
        oPC   : out word
    );
end entity;

architecture rtl of pc is
    signal reg_pc : word := (others => '0');
begin
    process(iCLK)
    begin
        if rising_edge(iCLK) then
            if iRST = '1' then
                reg_pc <= (others => '0');
            else
                reg_pc <= iNext;
            end if;
        end if;
    end process;

    oPC <= reg_pc;
end architecture;
