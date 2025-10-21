library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;  -- word = std_logic_vector(31 downto 0)

entity imm_gen is
  port (
    instr : in  word;
    imm   : out word
  );
end entity;

architecture Behavioral of imm_gen is
  signal opcode : std_logic_vector(6 downto 0);
  signal imm_i, imm_s, imm_b, imm_u, imm_j : word;
begin
  opcode <= instr(6 downto 0);

  -- I-type (ADDI/ORI/SLTI*/JALR/LW): bits [31:20], sign-extended
  imm_i <= (31 downto 11 => instr(31)) & instr(30 downto 20);

  -- S-type (SW): bits [31:25] & [11:7], sign-extended
  imm_s <= (31 downto 11 => instr(31)) & instr(30 downto 25) & instr(11 downto 7);

  -- B-type (BEQ/BNE/BLT/BGE/BLTU/BGEU): {imm[12|10:5|4:1|11],0}, sign-extended
  imm_b <= (31 downto 12 => instr(31)) &
           instr(7) &
           instr(30 downto 25) &
           instr(11 downto 8) &
           '0';

  -- U-type (LUI/AUIPC): upper 20 bits << 12
  imm_u <= instr(31 downto 12) & x"000";

  -- J-type (JAL): {imm[20|10:1|11|19:12],0}, sign-extended
  imm_j <= (31 downto 20 => instr(31)) &
           instr(19 downto 12) &
           instr(20) &
           instr(30 downto 21) &
           '0';

  process(opcode, imm_i, imm_s, imm_b, imm_u, imm_j)
  begin
    case opcode is
      when "0010011" => imm <= imm_i; -- I-type (ADDI/ORI/etc.)
      when "0000011" => imm <= imm_i; -- LOAD (LW)
      when "0100011" => imm <= imm_s; -- STORE (SW)
      when "1100011" => imm <= imm_b; -- BRANCH
      when "0110111" => imm <= imm_u; -- LUI
      when "0010111" => imm <= imm_u; -- AUIPC
      when "1101111" => imm <= imm_j; -- JAL
      when "1100111" => imm <= imm_i; -- JALR
      when others    => imm <= (others => '0');
    end case;
  end process;
end architecture Behavioral;
