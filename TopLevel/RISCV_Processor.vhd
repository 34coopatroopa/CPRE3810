library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic ( N : integer := 32 );
  port (
    iCLK      : in  std_logic;
    iRST      : in  std_logic;
    iInstLd   : in  std_logic;
    iInstAddr : in  std_logic_vector(N-1 downto 0);
    iInstExt  : in  std_logic_vector(N-1 downto 0);
    oALUOut   : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture rtl of RISCV_Processor is
  ----------------------------------------------------------------
  -- Toolflow-observed signals
  ----------------------------------------------------------------
  signal s_DMemWr    : std_logic := '0';
  signal s_DMemAddr  : word := (others => '0');
  signal s_DMemData  : word := (others => '0');
  signal s_RegWr     : std_logic := '0';
  signal s_RegWrAddr : std_logic_vector(4 downto 0) := (others => '0');
  signal s_RegWrData : word := (others => '0');
  signal s_Halt      : std_logic := '0';
  signal s_Ovfl      : std_logic := '0';

  ----------------------------------------------------------------
  -- Internal pipeline/data/control signals
  ----------------------------------------------------------------
  signal PC, next_PC : word := (others => '0');
  signal instr_f, instr_id : word := (others => '0');
  signal pc4_id, pc4_ex, pc4_mem, pc4_wb : word := (others => '0');

  -- Decode stage
  signal opcode_id : std_logic_vector(6 downto 0);
  signal rd_id, rs1_id, rs2_id : std_logic_vector(4 downto 0);
  signal funct3_id : std_logic_vector(2 downto 0);
  signal funct7_id : std_logic_vector(6 downto 0);
  signal imm_id : word := (others => '0');
  signal rs1_val_id, rs2_val_id : word := (others => '0');

  -- Control
  signal ALU_Sel_id : std_logic_vector(3 downto 0) := (others => '0');
  signal RegWrite_id, MemRead_id, MemWrite_id, Branch_id : std_logic := '0';

  -- Execute stage
  signal rd_ex : std_logic_vector(4 downto 0);
  signal opcode_ex : std_logic_vector(6 downto 0);
  signal funct3_ex : std_logic_vector(2 downto 0);
  signal ALU_Sel_ex : std_logic_vector(3 downto 0);
  signal RegWrite_ex, MemRead_ex, MemWrite_ex : std_logic := '0';
  signal rs1_val_ex, rs2_val_ex, imm_ex : word := (others => '0');

  signal alu_a, alu_b, alu_res : word := (others => '0');
  signal alu_zero : std_logic := '0';
  signal dmem_q : word := (others => '0');

  -- MEM + WB stages
  signal rd_mem, rd_wb : std_logic_vector(4 downto 0) := (others => '0');
  signal RegWrite_mem, RegWrite_wb : std_logic := '0';
  signal wb_data_mem, wb_data_wb : word := (others => '0');

  -- Control-flow
  signal take_branch_id, take_jal_id, take_jalr_ex, flush_now : std_logic := '0';
begin
  ----------------------------------------------------------------
  -- Program Counter
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST = '1' then
      PC <= (others => '0');
    elsif rising_edge(iCLK) then
      if s_Halt = '0' then
        PC <= next_PC;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Instruction Memory
  ----------------------------------------------------------------
  IMem : entity work.mem
    generic map (DATA_WIDTH => N, ADDR_WIDTH => 10)
    port map (
      clk  => iCLK,
      addr => PC(11 downto 2),
      data => (others => '0'),
      we   => '0',
      q    => instr_f
    );

  ----------------------------------------------------------------
  -- IF -> ID
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST = '1' then
      instr_id <= (others => '0');
      pc4_id   <= (others => '0');
    elsif rising_edge(iCLK) then
      instr_id <= instr_f;
      pc4_id   <= std_logic_vector(unsigned(PC) + 4);
    end if;
  end process;

  ----------------------------------------------------------------
  -- Instruction Decode
  ----------------------------------------------------------------
  opcode_id <= instr_id(6 downto 0);
  rd_id     <= instr_id(11 downto 7);
  funct3_id <= instr_id(14 downto 12);
  rs1_id    <= instr_id(19 downto 15);
  rs2_id    <= instr_id(24 downto 20);
  funct7_id <= instr_id(31 downto 25);

  ----------------------------------------------------------------
  -- Immediate Generation + Control
  ----------------------------------------------------------------
  u_imm : entity work.imm_gen
    port map (instr => instr_id, imm => imm_id);

  u_ctl : entity work.control
    port map (
      opcode   => opcode_id,
      funct3   => funct3_id,
      funct7   => funct7_id,
      ALU_Sel  => ALU_Sel_id,
      RegWrite => RegWrite_id,
      MemRead  => MemRead_id,
      MemWrite => MemWrite_id,
      Branch   => Branch_id
    );

  ----------------------------------------------------------------
  -- Register File
  ----------------------------------------------------------------
  u_rf : entity work.regfile
    port map (
      i_CLK => iCLK,
      i_RST => iRST,
      i_WE  => RegWrite_wb,
      i_RD  => rd_wb,
      i_D   => wb_data_wb,
      i_RS1 => rs1_id,
      i_RS2 => rs2_id,
      o_RS1 => rs1_val_id,
      o_RS2 => rs2_val_id
    );

  ----------------------------------------------------------------
  -- Branch and Jump Detection (in ID/EX)
  ----------------------------------------------------------------
  take_branch_id <= '1' when (opcode_id = "1100011" and (
                      (funct3_id = "000" and rs1_val_id =  rs2_val_id) or
                      (funct3_id = "001" and rs1_val_id /= rs2_val_id) or
                      (funct3_id = "100" and signed(rs1_val_id) <  signed(rs2_val_id)) or
                      (funct3_id = "101" and signed(rs1_val_id) >= signed(rs2_val_id)) or
                      (funct3_id = "110" and unsigned(rs1_val_id) <  unsigned(rs2_val_id)) or
                      (funct3_id = "111" and unsigned(rs1_val_id) >= unsigned(rs2_val_id))
                    )) else '0';
  take_jal_id  <= '1' when (opcode_id = "1101111") else '0';
  take_jalr_ex <= '1' when (opcode_ex = "1100111") else '0';
  flush_now    <= take_branch_id or take_jal_id or take_jalr_ex;

  ----------------------------------------------------------------
  -- ID -> EX (with flush)
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST = '1' then
      rd_ex       <= (others => '0');
      pc4_ex      <= (others => '0');
      opcode_ex   <= (others => '0');
      funct3_ex   <= (others => '0');
      ALU_Sel_ex  <= (others => '0');
      RegWrite_ex <= '0';
      MemRead_ex  <= '0';
      MemWrite_ex <= '0';
      rs1_val_ex  <= (others => '0');
      rs2_val_ex  <= (others => '0');
      imm_ex      <= (others => '0');
    elsif rising_edge(iCLK) then
      if flush_now = '1' then
        rd_ex       <= (others => '0');
        opcode_ex   <= (others => '0');
        RegWrite_ex <= '0';
        MemRead_ex  <= '0';
        MemWrite_ex <= '0';
      else
        rd_ex       <= rd_id;
        pc4_ex      <= pc4_id;
        opcode_ex   <= opcode_id;
        funct3_ex   <= funct3_id;
        ALU_Sel_ex  <= ALU_Sel_id;
        RegWrite_ex <= RegWrite_id;
        MemRead_ex  <= MemRead_id;
        MemWrite_ex <= MemWrite_id;
        rs1_val_ex  <= rs1_val_id;
        rs2_val_ex  <= rs2_val_id;
        imm_ex      <= imm_id;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- ALU
  ----------------------------------------------------------------
  alu_a <= rs1_val_ex;
  alu_b <= imm_ex when (opcode_ex = "0010011" or
                        opcode_ex = "0000011" or
                        opcode_ex = "0100011" or
                        opcode_ex = "1100111")
           else rs2_val_ex;

  u_alu : entity work.alu
    port map (
      A        => alu_a,
      B        => alu_b,
      ALU_Sel  => ALU_Sel_ex,
      Result   => alu_res,
      Zero     => alu_zero
    );

  oALUOut <= alu_res;

  ----------------------------------------------------------------
  -- Data Memory
  ----------------------------------------------------------------
  DMem : entity work.mem
    generic map (DATA_WIDTH => N, ADDR_WIDTH => 10)
    port map (
      clk  => iCLK,
      addr => alu_res(11 downto 2),
      data => rs2_val_ex,
      we   => MemWrite_ex,
      q    => dmem_q
    );

  ----------------------------------------------------------------
  -- Next PC logic
  ----------------------------------------------------------------
  process(all)
    variable pc_plus4, pc_branch, pc_jalr : unsigned(31 downto 0);
  begin
    pc_plus4  := unsigned(PC) + 4;
    pc_branch := unsigned(PC) + unsigned(imm_id);
    pc_jalr   := (unsigned(rs1_val_ex) + unsigned(imm_ex)) and x"FFFFFFFE";
    next_PC   <= std_logic_vector(pc_plus4);

    if take_branch_id = '1' or take_jal_id = '1' then
      next_PC <= std_logic_vector(pc_branch);
    elsif take_jalr_ex = '1' then
      next_PC <= std_logic_vector(pc_jalr);
    end if;
  end process;

  ----------------------------------------------------------------
  -- Two-stage Writeback Pipeline (EX→MEM→WB)
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST = '1' then
      rd_mem       <= (others => '0');
      pc4_mem      <= (others => '0');
      RegWrite_mem <= '0';
      wb_data_mem  <= (others => '0');
    elsif rising_edge(iCLK) then
      rd_mem       <= rd_ex;
      pc4_mem      <= pc4_ex;
      RegWrite_mem <= RegWrite_ex;

      if (opcode_ex = "1101111" or opcode_ex = "1100111") then
        wb_data_mem <= pc4_ex;
      elsif MemRead_ex = '1' then
        wb_data_mem <= dmem_q;
      else
        wb_data_mem <= alu_res;
      end if;
    end if;
  end process;

  -- MEM→WB stage
  process(iCLK, iRST)
  begin
    if iRST = '1' then
      rd_wb       <= (others => '0');
      RegWrite_wb <= '0';
      wb_data_wb  <= (others => '0');
    elsif rising_edge(iCLK) then
      rd_wb       <= rd_mem;
      RegWrite_wb <= RegWrite_mem;
      wb_data_wb  <= wb_data_mem;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Toolflow Traces + Halt
  ----------------------------------------------------------------
  s_RegWr     <= RegWrite_wb;
  s_RegWrAddr <= rd_wb;
  s_RegWrData <= wb_data_wb;
  s_DMemWr    <= MemWrite_ex;
  s_DMemAddr  <= alu_res;
  s_DMemData  <= rs2_val_ex;
  s_Ovfl      <= '0';

  s_Halt <= '1' when (opcode_id = "1110011" and funct3_id = "000" and
                      rs1_id = "00000" and rd_id = "00000") else '0';
end architecture;
