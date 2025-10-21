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
      ----------------------------------------------------------------
      -- R-type (0110011): ADD, SUB, AND, OR
      ----------------------------------------------------------------
      when "0110011" =>
        RegWrite <= '1';
        case funct3 is
          when "000" =>
            if funct7 = "0100000" then
              ALU_Sel <= "0001"; -- SUB
            else
              ALU_Sel <= "0000"; -- ADD
            end if;
          when "110" => ALU_Sel <= "0011"; -- OR
          when "111" => ALU_Sel <= "0010"; -- AND
          when others => ALU_Sel <= "0000";
        end case;

      ----------------------------------------------------------------
      -- I-type arithmetic (0010011): ADDI, ORI, ANDI
      ----------------------------------------------------------------
      when "0010011" =>
        RegWrite <= '1';
        case funct3 is
          when "000" => ALU_Sel <= "0000"; -- ADDI
          when "110" => ALU_Sel <= "0011"; -- ORI
          when "111" => ALU_Sel <= "0010"; -- ANDI
          when others => ALU_Sel <= "0000";
        end case;

      ----------------------------------------------------------------
      -- Loads (LW)
      ----------------------------------------------------------------
      when "0000011" =>
        RegWrite <= '1';
        MemRead  <= '1';
        ALU_Sel  <= "0000"; -- ADD for address

      ----------------------------------------------------------------
      -- Stores (SW)
      ----------------------------------------------------------------
      when "0100011" =>
        MemWrite <= '1';
        ALU_Sel  <= "0000"; -- ADD for address

      ----------------------------------------------------------------
      -- Branches (BEQ, BNE)
      ----------------------------------------------------------------
      when "1100011" =>
        Branch   <= '1';
        ALU_Sel  <= "0001"; -- SUB compare

      ----------------------------------------------------------------
      -- JAL (1101111)
      ----------------------------------------------------------------
      when "1101111" =>
        RegWrite <= '1'; -- writes PC+4

      ----------------------------------------------------------------
      -- JALR (1100111)
      ----------------------------------------------------------------
      when "1100111" =>
        RegWrite <= '1';
        ALU_Sel  <= "0000";

      ----------------------------------------------------------------
      -- LUI, AUIPC
      ----------------------------------------------------------------
      when "0110111" | "0010111" =>
        RegWrite <= '1';
        ALU_Sel  <= "0000";

      ----------------------------------------------------------------
      -- Default
      ----------------------------------------------------------------
      when others =>
        ALU_Sel  <= "0000";
        RegWrite <= '0';
        MemRead  <= '0';
        MemWrite <= '0';
        Branch   <= '0';
    end case;
  end process;
end architecture;
