library ieee;
use ieee.std_logic_1164.all;

entity dffn is
    port(
        iCLK : in  std_logic;
        iRST : in  std_logic;
        iD   : in  std_logic;
        oQ   : out std_logic
    );
end entity dffn;

architecture structural of dffn is
    component dffg
        port(
            iCLK : in  std_logic;
            iRST : in  std_logic;
            iD   : in  std_logic;
            oQ   : out std_logic
        );
    end component;

    signal nRST : std_logic;
begin
    nRST <= not iRST;

    U1 : dffg
        port map(
            iCLK => iCLK,
            iRST => nRST,
            iD   => iD,
            oQ   => oQ
        );
end architecture structural;
