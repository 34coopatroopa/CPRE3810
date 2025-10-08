library ieee;
use ieee.std_logic_1164.all;

entity dffg is
    port(
        iCLK : in  std_logic;
        iRST : in  std_logic;
        iD   : in  std_logic;
        oQ   : out std_logic
    );
end entity dffg;

architecture mixed of dffg is
begin
    process(iCLK, iRST)
    begin
        if iRST = '1' then
            oQ <= '0';
        elsif rising_edge(iCLK) then
            oQ <= iD;
        end if;
    end process;
end architecture mixed;
