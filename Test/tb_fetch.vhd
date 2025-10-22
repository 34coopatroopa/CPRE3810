library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;  -- defines "word" as std_logic_vector(31 downto 0)

entity tb_fetch is
end tb_fetch;

architecture behavior of tb_fetch is
    -- Component Declaration
    component fetch
        port (
            iCLK, iRST : in  std_logic;
            iBranch    : in  std_logic;
            iZero      : in  std_logic;
            iJump      : in  std_logic;
            iImm       : in  word;
            oPC        : out word
        );
    end component;

    -- Signals
    signal iCLK, iRST : std_logic := '0';
    signal iBranch    : std_logic := '0';
    signal iZero      : std_logic := '0';
    signal iJump      : std_logic := '0';
    signal iImm       : word := (others => '0');
    signal oPC        : word;

    constant cCLK_PERIOD : time := 10 ns;

begin
    -- Instantiate DUT
    uut: fetch
        port map (
            iCLK   => iCLK,
            iRST   => iRST,
            iBranch => iBranch,
            iZero   => iZero,
            iJump   => iJump,
            iImm    => iImm,
            oPC     => oPC
        );

    -- Clock generation
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
        -- Apply reset
        iRST <= '1';
        wait for 20 ns;
        iRST <= '0';
        wait for cCLK_PERIOD;

        -- Normal PC increment (no branch/jump)
        iBranch <= '0';
        iZero   <= '0';
        iJump   <= '0';
        iImm    <= (others => '0');
        wait for 4 * cCLK_PERIOD;

        -- Branch taken (branch + zero = 1)
        iBranch <= '1';
        iZero   <= '1';
        iImm    <= std_logic_vector(to_signed(8, 32)); -- PC + 8
        wait for 2 * cCLK_PERIOD;

        -- Branch not taken (branch=1, zero=0)
        iZero <= '0';
        wait for 2 * cCLK_PERIOD;

        -- Jump
        iBranch <= '0';
        iJump <= '1';
        iImm <= std_logic_vector(to_signed(16, 32)); -- PC + 16
        wait for 2 * cCLK_PERIOD;

        -- Normal increment again
        iJump <= '0';
        wait for 4 * cCLK_PERIOD;

        -- End simulation
        assert false report "Simulation complete." severity note;
        wait;
    end process;
end behavior;