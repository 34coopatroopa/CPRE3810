library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity tb_barrel_shifter is
end tb_barrel_shifter;

architecture sim of tb_barrel_shifter is
    -- DUT signals
    signal A       : word := (others => '0');
    signal shamt   : std_logic_vector(4 downto 0) := (others => '0');
    signal dir     : std_logic := '0';
    signal arith   : std_logic := '0';
    signal Result  : word;

begin
    -- Instantiate the Device Under Test (DUT)
    DUT: entity work.barrel_shifter
        port map (
            A => A,
            shamt => shamt,
            dir => dir,
            arith => arith,
            Result => Result
        );

    -- Stimulus process
    process
    begin
        -- Test 1: Logical Left Shift
        A <= x"00000003";        -- 000...0011
        shamt <= "00010";        -- shift by 2
        dir <= '0';              -- left shift
        arith <= '0';
        wait for 20 ns;

        -- Test 2: Logical Right Shift
        A <= x"00000030";        -- 000...110000
        shamt <= "00010";        -- shift by 2
        dir <= '1';              -- right shift
        arith <= '0';
        wait for 20 ns;

        -- Test 3: Arithmetic Right Shift (positive number)
        A <= x"000000F0";        -- 000...11110000
        shamt <= "00011";        -- shift by 3
        dir <= '1';
        arith <= '1';            -- arithmetic shift
        wait for 20 ns;

        -- Test 4: Arithmetic Right Shift (negative number)
        A <= x"F0000000";        -- 1111...0000 (negative in 2's complement)
        shamt <= "00100";        -- shift by 4
        dir <= '1';
        arith <= '1';
        wait for 20 ns;

        -- Test 5: Logical Right Shift (negative number)
        A <= x"F0000000";        -- same input, but logical shift
        shamt <= "00100";
        dir <= '1';
        arith <= '0';
        wait for 20 ns;

        wait;
    end process;
end sim;
