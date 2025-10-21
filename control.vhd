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
    ALU_Sel  <= "0000";  -- ADD
    RegWrite <= '0';
    MemRead  <= '0';
    MemWrite <= '0';
    Branch   <= '0';

    case opcode is
      ----------------------------------------------------------------
      -- R-type (ADD/SUB/OR/AND/XOR/SLL/SRL/SRA/SLT/SLTU)
      ----------------------------------------------------------------
      when "0110011" =>
        RegWrite <= '1';
        case funct3 is
          when "000" =>                         -- ADD / SUB
            if funct7 = "0100000" then
              ALU_Sel <= "0001";               -- SUB
            else
              ALU_Sel <= "0000";               -- ADD
            end if;
          when "110" => ALU_Sel <= "0011";     -- OR
          when "111" => ALU_Sel <= "0010";     -- AND
          when "100" => ALU_Sel <= "0100";     -- XOR
          when "001" => ALU_Sel <= "0111";     -- SLL
          when "101" =>                         -- SRL / SRA
            if funct7 = "0100000" then
              ALU_Sel <= "1001";               -- SRA
            else
              ALU_Sel <= "1000";               -- SRL
            end if;
          when "010" => ALU_Sel <= "0110";     -- SLT
          when "011" => ALU_Sel <= "1010";     -- SLTU
          when others => null;
        end case;

      ----------------------------------------------------------------
      -- I-type arithmetic/logical (ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI)
      ----------------------------------------------------------------
      when "0010011" =>
        RegWrite <= '1';
        case funct3 is
          when "000" => ALU_Sel <= "0000";     -- ADDI
          when "010" => ALU_Sel <= "0110";     -- SLTI
          when "011" => ALU_Sel <= "1010";     -- SLTIU
          when "100" => ALU_Sel <= "0100";     -- XORI
          when "110" => ALU_Sel <= "0011";     -- ORI
          when "111" => ALU_Sel <= "0010";     -- ANDI
          when "001" => ALU_Sel <= "0111";     -- SLLI
          when "101" =>                        -- SRLI / SRAI
            if funct7 = "0100000" then
              ALU_Sel <= "1001";               -- SRAI
            else
              ALU_Sel <= "1000";               -- SRLI
            end if;
          when others => null;
        end case;

      ----------------------------------------------------------------
      -- LOAD (LW)
      ----------------------------------------------------------------
      when "0000011" =>
        RegWrite <= '1';
        MemRead  <= '1';
        ALU_Sel  <= "0000";                    -- base + offset

      ----------------------------------------------------------------
      -- STORE (SW)
      ----------------------------------------------------------------
      when "0100011" =>
        MemWrite <= '1';
        ALU_Sel  <= "0000";                    -- base + offset

      ----------------------------------------------------------------
      -- BRANCH (BEQ/BNE/BLT/…)
      ----------------------------------------------------------------
      when "1100011" =>
        Branch   <= '1';
        ALU_Sel  <= "0001";                    -- use SUB for compare

      ----------------------------------------------------------------
      -- Jumps
      ----------------------------------------------------------------
      when "1101111" => RegWrite <= '1';       -- JAL
      when "1100111" =>                        -- JALR
        RegWrite <= '1';
        ALU_Sel  <= "0000";

      ----------------------------------------------------------------
      -- U-type
      ----------------------------------------------------------------
      when "0110111" => RegWrite <= '1';       -- LUI
      when "0010111" => RegWrite <= '1';       -- AUIPC

      when others => null;
    end case;
  end process;
end architecture;
