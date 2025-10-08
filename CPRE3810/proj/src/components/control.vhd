library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity control is
    port (
        opcode : in  std_logic_vector(6 downto 0);
        funct3 : in  std_logic_vector(2 downto 0);
        funct7 : in  std_logic_vector(6 downto 0);
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
        -- default values
        ALU_Sel  <= "0000";
        RegWrite <= '0';
        MemRead  <= '0';
        MemWrite <= '0';
        Branch   <= '0';

        case opcode is
            when "0110011" =>  -- R-type
                RegWrite <= '1';
                case funct3 is
                    when "000" =>
                        if funct7 = "0100000" then
                            ALU_Sel <= "0001"; -- SUB
                        else
                            ALU_Sel <= "0000"; -- ADD
                        end if;
                    when "111" => ALU_Sel <= "0010"; -- AND
                    when "110" => ALU_Sel <= "0011"; -- OR
                    when others => ALU_Sel <= "0000";
                end case;

            when "0010011" =>  -- I-type (ADDI)
                RegWrite <= '1';
                ALU_Sel <= "0000";

            when "0000011" =>  -- LW
                RegWrite <= '1';
                MemRead  <= '1';
                ALU_Sel  <= "0000";

            when "0100011" =>  -- SW
                MemWrite <= '1';
                ALU_Sel  <= "0000";

            when "1100011" =>  -- BEQ/BNE
                Branch   <= '1';
                ALU_Sel  <= "0001"; -- use SUB for comparison

            when others =>
                ALU_Sel  <= "0000";
                RegWrite <= '0';
                MemRead  <= '0';
                MemWrite <= '0';
                Branch   <= '0';
        end case;
    end process;
end architecture;
