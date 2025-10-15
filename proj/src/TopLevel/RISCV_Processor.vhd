library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity RISCV_Processor is
    port (
        iCLK, iRST : in std_logic
    );
end entity;

architecture structure of RISCV_Processor is

    --------------------------------------------------------------------
    -- Internal signals
    --------------------------------------------------------------------
    signal s_PC, s_Inst, s_Imm, s_RegData1, s_RegData2, s_ALUResult, s_MemData, s_WriteData : word;
    signal s_Branch, s_MemWrite, s_MemRead, s_RegWrite, s_Zero : std_logic;
    signal s_ALU_Sel : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------------------------
    -- FETCH STAGE
    --------------------------------------------------------------------
    FETCH_STAGE : entity work.fetch
        port map (
            iCLK    => iCLK,
            iRST    => iRST,
            iBranch => s_Branch,
            iZero   => s_Zero,
            iJump   => '0',
            iImm    => s_Imm,
            oPC     => s_PC
        );

    --------------------------------------------------------------------
    -- INSTRUCTION MEMORY (READ-ONLY)
    --------------------------------------------------------------------
    IMem : entity work.mem
        port map (
            clk   => iCLK,
            addr  => s_PC(11 downto 2),
            data  => (others => '0'),
            we    => '0',
            q     => s_Inst    -- was odata => s_Inst
        );


    --------------------------------------------------------------------
    -- CONTROL UNIT
    --------------------------------------------------------------------
    CONTROL_UNIT : entity work.control
        port map (
            opcode   => s_Inst(6 downto 0),
            funct3   => s_Inst(14 downto 12),
            funct7   => s_Inst(31 downto 25),
            ALU_Sel  => s_ALU_Sel,
            RegWrite => s_RegWrite,
            MemRead  => s_MemRead,
            MemWrite => s_MemWrite,
            Branch   => s_Branch
        );

    --------------------------------------------------------------------
    -- REGISTER FILE
    --------------------------------------------------------------------
    REGFILE_INST : entity work.regfile
        port map (
            i_CLK => iCLK,
            i_RST => iRST,
            i_WE  => s_RegWrite,
            i_RD  => s_Inst(11 downto 7),
            i_D   => s_WriteData,
            i_RS1 => s_Inst(19 downto 15),
            i_RS2 => s_Inst(24 downto 20),
            o_RS1 => s_RegData1,
            o_RS2 => s_RegData2
        );

    --------------------------------------------------------------------
    -- IMMEDIATE GENERATOR
    --------------------------------------------------------------------
    IMM_GEN_INST : entity work.imm_gen
        port map (
            instr => s_Inst,
            imm  => s_Imm
        );

    --------------------------------------------------------------------
    -- ALU
    --------------------------------------------------------------------
    ALU_INST : entity work.alu
        port map (
            A        => s_RegData1,
            B        => s_RegData2,
            ALU_Sel  => s_ALU_Sel,
            Result   => s_ALUResult,
            Zero     => s_Zero
        );

    --------------------------------------------------------------------
    -- DATA MEMORY
    --------------------------------------------------------------------
    DMem : entity work.mem
    port map (
        clk   => iCLK,
        addr  => s_ALUResult(11 downto 2),
        data  => s_RegData2,
        we    => s_MemWrite,
        q     => s_MemData   -- was odata => s_MemData
    );


    --------------------------------------------------------------------
    -- WRITEBACK MUX (select between ALU result or Memory data)
    --------------------------------------------------------------------
    WB : process(s_MemRead, s_ALUResult, s_MemData)
    begin
        if s_MemRead = '1' then
            s_WriteData <= s_MemData;
        else
            s_WriteData <= s_ALUResult;
        end if;
    end process;

end architecture;
