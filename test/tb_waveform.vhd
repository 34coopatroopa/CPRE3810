library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_waveform is
end tb_waveform;

architecture sim of tb_waveform is
    -- Clock/reset
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';

    -- Dummy instruction interface signals
    signal inst_ld   : std_logic := '0';
    signal inst_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal inst_ext  : std_logic_vector(31 downto 0) := (others => '0');

begin
    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    uut : entity work.RISCV_Processor
        port map (
            iCLK      => clk,
            iRST      => rst,
            iInstLd   => inst_ld,
            iInstAddr => inst_addr,
            iInstExt  => inst_ext
        );

    --------------------------------------------------------------------
    -- Clock
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    end process;

    --------------------------------------------------------------------
    -- Reset release
    --------------------------------------------------------------------
    rst_process : process
    begin
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait;
    end process;

    --------------------------------------------------------------------
    -- Run time
    --------------------------------------------------------------------
    sim_end : process
    begin
        wait for 5 us;
        assert false report "Simulation finished." severity failure;
    end process;

end sim;
