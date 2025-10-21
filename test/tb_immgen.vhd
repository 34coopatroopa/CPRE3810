library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;  -- assumes subtype word = std_logic_vector(31 downto 0)

entity tb_imm_gen is
end entity;

architecture sim of tb_imm_gen is
    -- DUT signals
    signal instr : word := (others => '0');
    signal imm   : word;

    -- convenience procedure to print hex
    procedure print_imm(msg : string; val : std_logic_vector) is
        variable L : line;
    begin
        write(L, string'("[INFO] " & msg & " => "));
        hwrite(L, val);
        writeline(output, L);
    end procedure;

begin
    -- DUT instance
    DUT : entity work.imm_gen
        port map (
            instr => instr,
            imm   => imm
        );

    -- Stimulus
    process
    begin
        ------------------------------------------------------------
        -- Test 1: ADDI x1, x0, 1  (I-type)
        ------------------------------------------------------------
        instr <= x"00100093";  -- imm=1
        wait for 10 ns;
        print_imm("ADDI x1,x0,1 imm", imm);

        ------------------------------------------------------------
        -- Test 2: ADDI x5, x0, -4  (I-type, negative imm)
        ------------------------------------------------------------
        instr <= x"FFC00293";  -- imm = 0xFFFFFFFC
        wait for 10 ns;
        print_imm("ADDI x5,x0,-4 imm", imm);

        ------------------------------------------------------------
        -- Test 3: SW x5, 8(x1)  (S-type)
        ------------------------------------------------------------
        instr <= x"0050A423";  -- imm = 8
        wait for 10 ns;
        print_imm("SW x5,8(x1) imm", imm);

        ------------------------------------------------------------
        -- Test 4: BEQ x0, x1, -16 (B-type)
        ------------------------------------------------------------
        instr <= x"FE208EE3";  -- imm = 0xFFFFFFF0
        wait for 10 ns;
        print_imm("BEQ x0,x1,-16 imm", imm);

        ------------------------------------------------------------
        -- Test 5: LUI x2, 0x12345 (U-type)
        ------------------------------------------------------------
        instr <= x"12345037";  -- imm = 0x12345000
        wait for 10 ns;
        print_imm("LUI x2,0x12345 imm", imm);

        ------------------------------------------------------------
        -- Test 6: JAL x1, 0x100  (J-type)
        ------------------------------------------------------------
        instr <= x"000100EF";  -- imm = 0x00000100
        wait for 10 ns;
        print_imm("JAL x1,0x100 imm", imm);

        ------------------------------------------------------------
        -- Finish
        ------------------------------------------------------------
        report "All imm_gen tests completed." severity note;
        wait;
    end process;

end architecture;
