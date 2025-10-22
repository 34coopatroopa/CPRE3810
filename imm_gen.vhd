library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imm_gen is
  port (
    instr : in  std_logic_vector(31 downto 0);
    imm   : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of imm_gen is
begin
  --------------------------------------------------------------------
  -- Immediate generator for RISC-V (RV32I)
  -- Works cleanly with QuestaSim, Quartus, and CPRE3810 toolflow
  --------------------------------------------------------------------
  process(instr)
    variable opcode     : std_logic_vector(6 downto 0);
    variable imm_signed : signed(31 downto 0);
  begin
    opcode := instr(6 downto 0);
    imm_signed := (others => '0');

    case opcode is

      ----------------------------------------------------------------
      -- I-type (ADDI, ANDI, ORI, XORI, SLTI, LW, JALR, etc.)
      ----------------------------------------------------------------
      when "0010011" | "0000011" | "1100111" =>
        imm_signed := resize(
          signed(instr(31 downto 20)),
          32
        );

      ----------------------------------------------------------------
      -- S-type (SW, SH, SB)
      ----------------------------------------------------------------
      when "0100011" =>
        imm_signed := resize(
          signed(instr(31 downto 25) & instr(11 downto 7)),
          32
        );

      ----------------------------------------------------------------
      -- B-type (BEQ, BNE, BLT, BGE, BLTU, BGEU)
      ----------------------------------------------------------------
      when "1100011" =>
        imm_signed := resize(
          signed(instr(31) & instr(7) &
                 instr(30 downto 25) &
                 instr(11 downto 8) & '0'),
          32
        );

      ----------------------------------------------------------------
      -- U-type (LUI, AUIPC)
      ----------------------------------------------------------------
      when "0110111" | "0010111" =>
        imm_signed := signed(instr(31 downto 12) & x"000");

      ----------------------------------------------------------------
      -- J-type (JAL)
      ----------------------------------------------------------------
      when "1101111" =>
        imm_signed := resize(
          signed(instr(31) &
                 instr(19 downto 12) &
                 instr(20) &
                 instr(30 downto 21) & '0'),
          32
        );

      ----------------------------------------------------------------
      -- Default
      ----------------------------------------------------------------
      when others =>
        imm_signed := (others => '0');
    end case;

    imm <= std_logic_vector(imm_signed);
  end process;
end architecture;
