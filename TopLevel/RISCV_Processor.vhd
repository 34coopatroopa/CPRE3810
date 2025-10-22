library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;  -- word = std_logic_vector(31 downto 0)

entity RISCV_Processor is
  generic ( N : integer := 32 );
  port (
    iCLK      : in  std_logic;
    iRST      : in  std_logic;

    -- instruction loader (testbench)
    iInstLd   : in  std_logic;
    iInstAddr : in  std_logic_vector(N-1 downto 0);
    iInstExt  : in  std_logic_vector(N-1 downto 0);

    -- debug
    oALUOut   : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture rtl of RISCV_Processor is
  -- Toolflow-observed pins (mirror the actual RF write & DMem write)
  signal s_DMemWr    : std_logic := '0';
  signal s_DMemAddr  : word := (others=>'0');
  signal s_DMemData  : word := (others=>'0');
  signal s_RegWr     : std_logic := '0';
  signal s_RegWrAddr : std_logic_vector(4 downto 0) := (others=>'0');
  signal s_RegWrData : word := (others=>'0');
  signal s_Halt      : std_logic := '0';
  signal s_Ovfl      : std_logic := '0';

  -- Single-cycle state
  signal pc_r, next_pc : word := (others=>'0');

  -- instruction memory (combinational read)
  signal instr_f : word := (others=>'0');
  signal imem_addr_mux : word;  -- full 32-bit address
  signal imem_data_mux : std_logic_vector(N-1 downto 0);

  -- decode fields (from instr_f)
  signal opcode   : std_logic_vector(6 downto 0);
  signal rd       : std_logic_vector(4 downto 0);
  signal rs1      : std_logic_vector(4 downto 0);
  signal rs2      : std_logic_vector(4 downto 0);
  signal funct3   : std_logic_vector(2 downto 0);
  signal funct7   : std_logic_vector(6 downto 0);  -- 31:25

  -- control / immediates
  signal imm      : word := (others=>'0');
  signal ALU_Sel  : std_logic_vector(3 downto 0) := (others=>'0');
  signal RegWrite : std_logic := '0';
  signal MemRead  : std_logic := '0';
  signal MemWrite : std_logic := '0';

  -- regfile values
  signal rs1_val, rs2_val : word := (others=>'0');

  -- ALU / MEM
  signal alu_A, alu_B   : word := (others=>'0');
  signal alu_res        : word := (others=>'0');
  signal alu_zero       : std_logic := '0';
  signal dmem_q         : word := (others=>'0');

  -- WB (combinational)
  signal wb_data   : word := (others=>'0');
  signal wb_rd     : std_logic_vector(4 downto 0) := (others=>'0');
  signal wb_we     : std_logic := '0';
begin
  ----------------------------------------------------------------
  -- Program Counter
  ----------------------------------------------------------------
  process(iCLK, iRST)
  begin
  if iRST = '1' then
    pc_r <= x"00400000";  -- start address
  elsif rising_edge(iCLK) then
    if s_Halt = '0' then
      pc_r <= next_pc;
    end if;
  end if;
  end process;

  ----------------------------------------------------------------
  -- Instruction memory (loader mux)
  ----------------------------------------------------------------
  imem_addr_mux <= iInstAddr when iInstLd='1' else pc_r;
  imem_data_mux <= iInstExt  when iInstLd='1' else (others => '0');

  IMem : entity work.mem
    generic map (DATA_WIDTH => N, ADDR_WIDTH => 10)
    port map (
      clk  => iCLK,
      addr => imem_addr_mux,   -- full 32-bit address
      data => imem_data_mux,
      we   => iInstLd,
      q    => instr_f
    );

  ----------------------------------------------------------------
  -- Decode (from instr_f)
  ----------------------------------------------------------------
  opcode <= instr_f(6  downto 0);
  rd     <= instr_f(11 downto 7);
  funct3 <= instr_f(14 downto 12);
  rs1    <= instr_f(19 downto 15);
  rs2    <= instr_f(24 downto 20);
  funct7 <= instr_f(31 downto 25);

  u_imm : entity work.imm_gen
    port map (instr => instr_f, imm => imm);

  u_ctl : entity work.control
    port map (
      opcode   => opcode,
      funct3   => funct3,
      funct7   => funct7,
      ALU_Sel  => ALU_Sel,
      RegWrite => RegWrite,
      MemRead  => MemRead,
      MemWrite => MemWrite,
      Branch   => open
    );

  ----------------------------------------------------------------
  -- Register file
  ----------------------------------------------------------------
  u_rf : entity work.regfile
    port map (
      i_CLK => iCLK,
      i_RST => iRST,
      i_WE  => wb_we,
      i_RD  => wb_rd,
      i_D   => wb_data,
      i_RS1 => rs1,
      i_RS2 => rs2,
      o_RS1 => rs1_val,
      o_RS2 => rs2_val
    );

  ----------------------------------------------------------------
  -- Execute (combinational)
  ----------------------------------------------------------------
  alu_A <= rs1_val;
  alu_B <= imm when (opcode = "0010011" or  -- I-type arithmetic
                     opcode = "0000011" or  -- LW
                     opcode = "0100011" or  -- SW
                     opcode = "1100111")    -- JALR
           else rs2_val;

  u_alu : entity work.alu
    port map (
      A        => alu_A,
      B        => alu_B,
      ALU_Sel  => ALU_Sel,
      Result   => alu_res,
      Zero     => alu_zero
    );

  oALUOut <= alu_res;

  ----------------------------------------------------------------
  -- Data memory
  ----------------------------------------------------------------
  DMem : entity work.mem
    generic map (DATA_WIDTH => N, ADDR_WIDTH => 10)
    port map (
      clk  => iCLK,
      addr => alu_res,    -- full 32-bit address
      data => rs2_val,
      we   => MemWrite,
      q    => dmem_q
    );

  ----------------------------------------------------------------
  -- Next PC (combinational)
  ----------------------------------------------------------------
  process(pc_r, rs1_val, rs2_val, imm, opcode, funct3, alu_zero)
    variable pc_plus4  : unsigned(31 downto 0);
    variable pc_branch : unsigned(31 downto 0);
    variable pc_jalr   : unsigned(31 downto 0);
  begin
    pc_plus4  := unsigned(pc_r) + 4;
    pc_branch := unsigned(pc_r) + unsigned(imm);
    pc_jalr   := (unsigned(rs1_val) + unsigned(imm)) and (not to_unsigned(1, 32));
    next_pc   <= std_logic_vector(pc_plus4);  -- default

    if opcode = "1100011" then  -- BRANCH
      case funct3 is
        when "000" => if alu_zero = '1' then next_pc <= std_logic_vector(pc_branch); end if;
        when "001" => if alu_zero = '0' then next_pc <= std_logic_vector(pc_branch); end if;
        when "100" => if signed(rs1_val) <  signed(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if;
        when "101" => if signed(rs1_val) >= signed(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if;
        when "110" => if unsigned(rs1_val) <  unsigned(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if;
        when "111" => if unsigned(rs1_val) >= unsigned(rs2_val) then next_pc <= std_logic_vector(pc_branch); end if;
        when others => null;
      end case;
    elsif opcode = "1101111" then       -- JAL
      next_pc <= std_logic_vector(pc_branch);
    elsif opcode = "1100111" then       -- JALR
      next_pc <= std_logic_vector(pc_jalr);
    end if;
  end process;

  ----------------------------------------------------------------
  -- Writeback (combinational select feeding RF WE/D/addr)
  ----------------------------------------------------------------
  wb_rd <= rd;
  wb_we <= RegWrite;

  process(opcode, pc_r, imm, dmem_q, alu_res)
    variable pc_plus4_v  : unsigned(31 downto 0);
    variable pc_plusimm  : unsigned(31 downto 0);
  begin
    pc_plus4_v := unsigned(pc_r) + 4;
    pc_plusimm := unsigned(pc_r) + unsigned(imm);

    if (opcode = "1101111" or opcode = "1100111") then      -- JAL/JALR: write PC+4
      wb_data <= std_logic_vector(pc_plus4_v);
    elsif (opcode = "0110111") then                          -- LUI
      wb_data <= imm;
    elsif (opcode = "0010111") then                          -- AUIPC
      wb_data <= std_logic_vector(pc_plusimm);
    elsif (opcode = "0000011") then                          -- LOAD
      wb_data <= dmem_q;
    else                                                     -- ALU ops / STORE / BRANCH
      wb_data <= alu_res;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Trace pins (actual writes)
  ----------------------------------------------------------------
  s_RegWr     <= wb_we;
  s_RegWrAddr <= wb_rd;
  s_RegWrData <= wb_data;

  s_DMemWr    <= MemWrite;
  s_DMemAddr  <= alu_res;
  s_DMemData  <= rs2_val;

  s_Ovfl      <= '0';
  s_Halt      <= '1' when (opcode = "1110011" and rs1 = "00000" and rd = "00000") else '0';
end architecture;
