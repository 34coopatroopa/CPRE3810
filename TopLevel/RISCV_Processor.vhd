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
  -- Toolflow-observed signals (MUST reflect *actual* RF write)
  ----------------------------------------------------------------
  signal s_DMemWr    : std_logic := '0';
  signal s_DMemAddr  : word := (others=>'0');
  signal s_DMemData  : word := (others=>'0');
  signal s_RegWr     : std_logic := '0';
  signal s_RegWrAddr : std_logic_vector(4 downto 0) := (others=>'0');
  signal s_RegWrData : word := (others=>'0');
  signal s_Halt      : std_logic := '0';
  signal s_Ovfl      : std_logic := '0';

  ----------------------------------------------------------------
  -- Datapath / pipeline signals
  ----------------------------------------------------------------
  signal pc_r, next_pc : word := (others=>'0');
  signal instr_f : word := (others=>'0');

  -- ID stage
  signal instr_id, pc4_id : word := (others=>'0');
  signal opcode_id : std_logic_vector(6 downto 0);
  signal rd_id, rs1_id, rs2_id : std_logic_vector(4 downto 0);
  signal funct3_id : std_logic_vector(2 downto 0);
  signal funct7_id : std_logic_vector(6 downto 0);
  signal imm_id : word := (others=>'0');
  signal ALU_Sel_id : std_logic_vector(3 downto 0) := (others=>'0');
  signal RegWrite_id, MemRead_id, MemWrite_id : std_logic := '0';
  signal rs1_val, rs2_val : word := (others=>'0');
  signal alu_b_id : word := (others=>'0');

  -- EX stage
  signal rd_ex, rs1_ex : std_logic_vector(4 downto 0) := (others=>'0');
  signal RegWrite_ex, MemRead_ex, MemWrite_ex : std_logic := '0';
  signal opcode_ex : std_logic_vector(6 downto 0) := (others=>'0');
  signal pc4_ex, rs2_ex, alu_A_ex, alu_B_ex : word := (others=>'0');
  signal ALU_Sel_ex : std_logic_vector(3 downto 0) := (others=>'0');
  signal alu_res_ex : word := (others=>'0');
  signal alu_zero_ex : std_logic := '0';

  -- WB stage
  signal rd_wb : std_logic_vector(4 downto 0) := (others=>'0');
  signal RegWrite_wb : std_logic := '0';
  signal RegData_wb : word := (others=>'0');

  signal dmem_q : word := (others=>'0');

  -- IMem mux
  signal imem_addr_mux : std_logic_vector(9 downto 0);
  signal imem_data_mux : std_logic_vector(N-1 downto 0);
begin
  ----------------------------------------------------------------
  -- Program Counter
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST='1' then
      pc_r <= (others=>'0');
    elsif rising_edge(iCLK) then
      if s_Halt='0' then
        pc_r <= next_pc;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Instruction memory
  ----------------------------------------------------------------
  imem_addr_mux <= iInstAddr(11 downto 2) when iInstLd='1' else pc_r(11 downto 2);
  imem_data_mux <= iInstExt when iInstLd='1' else (others=>'0');

  IMem : entity work.mem
    generic map (DATA_WIDTH=>N, ADDR_WIDTH=>10)
    port map (clk=>iCLK, addr=>imem_addr_mux, data=>imem_data_mux, we=>iInstLd, q=>instr_f);

  ----------------------------------------------------------------
  -- IF/ID pipeline regs
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST='1' then
      instr_id <= (others=>'0');
      pc4_id   <= (others=>'0');
    elsif rising_edge(iCLK) then
      instr_id <= instr_f;
      pc4_id   <= std_logic_vector(unsigned(pc_r)+4);
    end if;
  end process;

  ----------------------------------------------------------------
  -- Decode
  ----------------------------------------------------------------
  opcode_id <= instr_id(6  downto 0);
  rd_id     <= instr_id(11 downto 7);
  funct3_id <= instr_id(14 downto 12);
  rs1_id    <= instr_id(19 downto 15);
  rs2_id    <= instr_id(24 downto 20);
  funct7_id <= instr_id(31 downto 25);

  u_imm : entity work.imm_gen port map(instr=>instr_id, imm=>imm_id);

  u_ctl : entity work.control
    port map(opcode=>opcode_id, funct3=>funct3_id, funct7=>funct7_id,
             ALU_Sel=>ALU_Sel_id, RegWrite=>RegWrite_id,
             MemRead=>MemRead_id, MemWrite=>MemWrite_id, Branch=>open);

  -- Register File
  u_rf : entity work.regfile
    port map(i_CLK=>iCLK, i_RST=>iRST, i_WE=>RegWrite_wb, i_RD=>rd_wb,
             i_D=>RegData_wb, i_RS1=>rs1_id, i_RS2=>rs2_id,
             o_RS1=>rs1_val, o_RS2=>rs2_val);

  -- B operand select
  alu_b_id <= imm_id when (opcode_id="0010011" or opcode_id="0000011" or
                           opcode_id="0100011" or opcode_id="1100111")
              else rs2_val;

  ----------------------------------------------------------------
  -- ID → EX pipeline regs
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
    if iRST='1' then
      rd_ex       <= (others=>'0');
      rs1_ex      <= (others=>'0');
      RegWrite_ex <= '0';
      MemRead_ex  <= '0';
      MemWrite_ex <= '0';
      opcode_ex   <= (others=>'0');
      pc4_ex      <= (others=>'0');
      rs2_ex      <= (others=>'0');
      ALU_Sel_ex  <= (others=>'0');
      alu_A_ex    <= (others=>'0');
      alu_B_ex    <= (others=>'0');
    elsif rising_edge(iCLK) then
      rd_ex       <= rd_id;
      rs1_ex      <= rs1_id;
      RegWrite_ex <= RegWrite_id;
      MemRead_ex  <= MemRead_id;
      MemWrite_ex <= MemWrite_id;
      opcode_ex   <= opcode_id;
      pc4_ex      <= pc4_id;
      rs2_ex      <= rs2_val;
      ALU_Sel_ex  <= ALU_Sel_id;
      alu_A_ex    <= rs1_val;
      alu_B_ex    <= alu_b_id;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Execute (ALU)
  ----------------------------------------------------------------
  u_alu : entity work.alu
    port map(A=>alu_A_ex, B=>alu_B_ex, ALU_Sel=>ALU_Sel_ex,
             Result=>alu_res_ex, Zero=>alu_zero_ex);

  oALUOut <= alu_res_ex;

  ----------------------------------------------------------------
  -- Data memory
  ----------------------------------------------------------------
  DMem : entity work.mem
    generic map(DATA_WIDTH=>N, ADDR_WIDTH=>10)
    port map(clk=>iCLK, addr=>alu_res_ex(11 downto 2),
             data=>rs2_ex, we=>MemWrite_ex, q=>dmem_q);

  ----------------------------------------------------------------
  -- Next PC logic
  ----------------------------------------------------------------
  process(all)
    variable pc_plus4, pc_branch, pc_jalr : unsigned(31 downto 0);
  begin
    pc_plus4  := unsigned(pc_r) + 4;
    pc_branch := unsigned(pc_r) + unsigned(imm_id);
    pc_jalr   := (unsigned(alu_A_ex) + unsigned(imm_id)) and (not to_unsigned(1,32));
    next_pc   <= std_logic_vector(pc_plus4);

    if opcode_id="1100011" then
      case funct3_id is
        when "000" => if alu_zero_ex='1' then next_pc<=std_logic_vector(pc_branch); end if; -- beq
        when "001" => if alu_zero_ex='0' then next_pc<=std_logic_vector(pc_branch); end if; -- bne
        when "100" => if signed(alu_A_ex)<signed(rs2_ex) then next_pc<=std_logic_vector(pc_branch); end if;
        when "101" => if signed(alu_A_ex)>=signed(rs2_ex) then next_pc<=std_logic_vector(pc_branch); end if;
        when "110" => if unsigned(alu_A_ex)<unsigned(rs2_ex) then next_pc<=std_logic_vector(pc_branch); end if;
        when "111" => if unsigned(alu_A_ex)>=unsigned(rs2_ex) then next_pc<=std_logic_vector(pc_branch); end if;
        when others => null;
      end case;
    elsif opcode_id="1101111" then
      next_pc <= std_logic_vector(pc_branch);  -- JAL
    elsif opcode_id="1100111" then
      next_pc <= std_logic_vector(pc_jalr);    -- JALR
    end if;
  end process;

  ----------------------------------------------------------------
  -- WB stage
  ----------------------------------------------------------------
  process(iCLK, iRST)
    variable wb_data_v : word;
  begin
    if iRST='1' then
      rd_wb       <= (others=>'0');
      RegWrite_wb <= '0';
      RegData_wb  <= (others=>'0');
    elsif rising_edge(iCLK) then
      if (opcode_ex="1101111" or opcode_ex="1100111") then
        wb_data_v := pc4_ex;
      elsif (MemRead_ex='1') then
        wb_data_v := dmem_q;
      else
        wb_data_v := alu_res_ex;
      end if;

      rd_wb       <= rd_ex;
      RegWrite_wb <= RegWrite_ex;
      RegData_wb  <= wb_data_v;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Trace pins
  ----------------------------------------------------------------
  s_RegWr     <= RegWrite_wb;
  s_RegWrAddr <= rd_wb;
  s_RegWrData <= RegData_wb;

  s_DMemWr    <= MemWrite_ex;
  s_DMemAddr  <= alu_res_ex;
  s_DMemData  <= rs2_ex;
  s_Ovfl      <= '0';

  ----------------------------------------------------------------
  -- Halt detection (EX stage)
  ----------------------------------------------------------------
  s_Halt <= '1' when (opcode_ex="1110011" and rs1_ex="00000" and rd_ex="00000") else '0';
end architecture;
