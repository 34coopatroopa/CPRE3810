library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity control is
  port (
    opcode   : in  std_logic_vector(6 downto 0);
    funct3   : in  std_logic_vector(2 downto 0);
    funct7   : in  std_logic_vector(6 downto 0);
    ALU_Sel  : out std_logic_vector(3 downto 0);
    RegWrite : out std_logic;
    MemRead  : out std_logic;
    MemWrite : out std_logic;
    Branch   : out std_logic
  );
end entity;

architecture Behavioral of control is
begin
  process(opcode, funct3, funct7)
  begin
    -- defaults
    ALU_Sel  <= "0000";
    RegWrite <= '0';
    MemRead  <= '0';
    MemWrite <= '0';
    Branch   <= '0';

    case opcode is
      -- R-type (ADD/SUB/OR/AND)
      when "0110011" =>
        RegWrite <= '1';
        case funct3 is
          when "000" =>  -- ADD/SUB
            if funct7 = "0100000" then ALU_Sel <= "0001";  -- SUB
            else                        ALU_Sel <= "0000";  -- ADD
            end if;
          when "110" => ALU_Sel <= "0011";  -- OR
          when "111" => ALU_Sel <= "0010";  -- AND
          when others => ALU_Sel <= "0000";
        end case;

      -- I-type arithmetic (ADDI/ORI/ANDI)
      when "0010011" =>
        RegWrite <= '1';
        case funct3 is
          when "000" => ALU_Sel <= "0000";  -- ADDI
          when "110" => ALU_Sel <= "0011";  -- ORI
          when "111" => ALU_Sel <= "0010";  -- ANDI
          when others => ALU_Sel <= "0000";
        end case;

      -- LOAD (LW)
      when "0000011" =>
        RegWrite <= '1';
        MemRead  <= '1';
        ALU_Sel  <= "0000";  -- base + imm

      -- STORE (SW)
      when "0100011" =>
        MemWrite <= '1';
        ALU_Sel  <= "0000";  -- base + imm

      -- BRANCH (use SUB compare)
      when "1100011" =>
        Branch   <= '1';
        ALU_Sel  <= "0001";

      -- JAL
      when "1101111" =>
        RegWrite <= '1';     -- write PC+4 in WB

      -- JALR
      when "1100111" =>
        RegWrite <= '1';
        ALU_Sel  <= "0000";  -- base + imm for target

      -- LUI / AUIPC (handled by datapath/WB)
      when "0110111" | "0010111" =>
        RegWrite <= '1';
        ALU_Sel  <= "0000";

      when others =>
        null;
    end case;
  end process;
end architecture;
