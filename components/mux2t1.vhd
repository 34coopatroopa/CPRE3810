library ieee;
use ieee.std_logic_1164.all;

entity mux2t1 is
    port(
        i_S  : in  std_logic;
        i_D0 : in  std_logic;
        i_D1 : in  std_logic;
        o_F  : out std_logic
    );
end entity mux2t1;

architecture structural of mux2t1 is

    -- Declare all primitive components used
    component invg
        port(
            i_A : in  std_logic;
            o_F : out std_logic
        );
    end component;

    component andg2
        port(
            i_A : in  std_logic;
            i_B : in  std_logic;
            o_F : out std_logic
        );
    end component;

    component org2
        port(
            i_A : in  std_logic;
            i_B : in  std_logic;
            o_F : out std_logic
        );
    end component;

    -- Internal signals
    signal s_Sn   : std_logic;
    signal s_AND1 : std_logic;
    signal s_AND2 : std_logic;

begin

    -- Invert select signal
    U1 : invg
        port map(
            i_A => i_S,
            o_F => s_Sn
        );

    -- AND gates for data selection
    U2 : andg2
        port map(
            i_A => i_D0,
            i_B => s_Sn,
            o_F => s_AND1
        );

    U3 : andg2
        port map(
            i_A => i_D1,
            i_B => i_S,
            o_F => s_AND2
        );

    -- OR gate to combine outputs
    U4 : org2
        port map(
            i_A => s_AND1,
            i_B => s_AND2,
            o_F => o_F
        );

end architecture structural;
