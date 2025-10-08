library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

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

    -- I-type
    imm_i <= (31 downto 12 => instr(31)) & instr(31 downto 20);

    -- S-type
    imm_s <= (31 downto 12 => instr(31)) & instr(31 downto 25) & instr(11 downto 7);

    -- B-type
    imm_b <= (31 downto 12 => instr(31)) &
              instr(7) &
              instr(30 downto 25) &
              instr(11 downto 8) &
              "0";

    -- U-type
    imm_u <= instr(31 downto 12) & x"000";

    -- J-type
    imm_j <= (31 downto 20 => instr(31)) &
              instr(19 downto 12) &
              instr(20) &
              instr(30 downto 21) &
              "0";

    process(opcode)
    begin
        case opcode is
            when "0010011" | "0000011" =>  imm <= imm_i; -- I-type
            when "0100011"             =>  imm <= imm_s; -- S-type
            when "1100011"             =>  imm <= imm_b; -- B-type
            when "0110111" | "0010111" =>  imm <= imm_u; -- U-type (LUI/AUIPC)
            when "1101111"             =>  imm <= imm_j; -- J-type (JAL)
            when others                =>  imm <= (others => '0');
        end case;
    end process;
end architecture;
