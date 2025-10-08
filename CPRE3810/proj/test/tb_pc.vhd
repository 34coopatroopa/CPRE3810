library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;  -- must define "word" (e.g., std_logic_vector(31 downto 0))

entity tb_pc is
end tb_pc;

architecture behavior of tb_pc is
    -- DUT component
    component pc
        port (
            iCLK  : in  std_logic;
            iRST  : in  std_logic;
            iNext : in  word;
            oPC   : out word
        );
    end component;

    -- Signals for testbench
    signal iCLK  : std_logic := '0';
    signal iRST  : std_logic := '0';
    signal iNext : word := (others => '0');
    signal oPC   : word;

    -- Clock period
    constant cCLK_PERIOD : time := 10 ns;

begin
    -- Instantiate the DUT
    uut: pc
        port map (
            iCLK  => iCLK,
            iRST  => iRST,
            iNext => iNext,
            oPC   => oPC
        );

    -- Clock generation process
    clk_process : process
    begin
        iCLK <= '0';
        wait for cCLK_PERIOD / 2;
        iCLK <= '1';
        wait for cCLK_PERIOD / 2;
    end process;

    -- Stimulus process
    stim_proc : process
    begin
        -- Initial reset
        iRST <= '1';
        iNext <= (others => '0');
        wait for 20 ns;

        -- Release reset
        iRST <= '0';
        wait for cCLK_PERIOD;

        -- Apply new values
        iNext <= std_logic_vector(to_unsigned(4, 32));
        wait for cCLK_PERIOD;

        iNext <= std_logic_vector(to_unsigned(8, 32));
        wait for cCLK_PERIOD;

        iNext <= std_logic_vector(to_unsigned(12, 32));
        wait for cCLK_PERIOD;

        -- Apply reset again mid-simulation
        iRST <= '1';
        wait for cCLK_PERIOD;
        iRST <= '0';

        -- More values
        iNext <= std_logic_vector(to_unsigned(16, 32));
        wait for cCLK_PERIOD;

        -- End simulation
        wait for 40 ns;
        assert false report "Simulation complete." severity note;
        wait;
    end process;
end behavior;
