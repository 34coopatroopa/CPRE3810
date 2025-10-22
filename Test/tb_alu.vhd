library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu is
end tb_alu;

architecture sim of tb_alu is
    -- DUT signals
    signal A, B     : std_logic_vector(31 downto 0) := (others => '0');
    signal ALU_Sel  : std_logic_vector(3 downto 0) := (others => '0');
    signal Result   : std_logic_vector(31 downto 0);
    signal Zero     : std_logic;
begin
    -- Instantiate ALU
    DUT: entity work.alu
        port map (
            A => A,
            B => B,
            ALU_Sel => ALU_Sel,
            Result => Result,
            Zero => Zero
        );

    -- Stimulus process
    process
    begin
        ------------------------------------------------------------------
        -- Test 1: ADD
        ------------------------------------------------------------------
        A <= x"00000005"; 
        B <= x"00000003";
        ALU_Sel <= "0000";     -- ADD
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 2: SUB
        ------------------------------------------------------------------
        A <= x"00000009"; 
        B <= x"00000004";
        ALU_Sel <= "0001";     -- SUB
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 3: AND
        ------------------------------------------------------------------
        A <= x"0F0F0F0F";
        B <= x"00FF00FF";
        ALU_Sel <= "0010";     -- AND
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 4: OR
        ------------------------------------------------------------------
        ALU_Sel <= "0011";     -- OR
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 5: XOR
        ------------------------------------------------------------------
        ALU_Sel <= "0100";     -- XOR
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 6: SLT (signed less than)
        ------------------------------------------------------------------
        A <= x"FFFFFFF0";  -- -16
        B <= x"00000010";  -- 16
        ALU_Sel <= "0110";     -- SLT
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 7: SLTU (unsigned less than)
        ------------------------------------------------------------------
        A <= x"FFFFFFF0";  -- large unsigned
        B <= x"00000010";  -- smaller unsigned
        ALU_Sel <= "1010";     -- SLTU
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 8: SLL (logical left shift)
        ------------------------------------------------------------------
        A <= x"00000003";
        B <= x"00000002";
        ALU_Sel <= "0111";     -- SLL
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 9: SRL (logical right shift)
        ------------------------------------------------------------------
        A <= x"00000030";
        B <= x"00000002";
        ALU_Sel <= "1000";     -- SRL
        wait for 20 ns;

        ------------------------------------------------------------------
        -- Test 10: SRA (arithmetic right shift)
        ------------------------------------------------------------------
        A <= x"F0000000";      -- negative number (sign bit = 1)
        B <= x"00000004";
        ALU_Sel <= "1001";     -- SRA
        wait for 20 ns;

        wait;
    end process;
end sim;
