library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity alu is
    port (
        A, B      : in  word;
        ALU_Sel   : in  std_logic_vector(3 downto 0);
        Result    : out word;
        Zero      : out std_logic
    );
end entity;

architecture Behavioral of alu is
    signal temp : word := (others => '0');
begin
    process (A, B, ALU_Sel)
        variable sa : integer range 0 to 31;
    begin
        temp <= (others => '0');

        case ALU_Sel is
            when "0000" =>  -- ADD
                temp <= std_logic_vector(signed(A) + signed(B));

            when "0001" =>  -- SUB
                temp <= std_logic_vector(signed(A) - signed(B));

            when "0010" =>  -- AND
                temp <= A and B;

            when "0011" =>  -- OR
                temp <= A or B;

            when "0100" =>  -- XOR
                temp <= A xor B;

            when "0101" =>  -- SLL
                sa := to_integer(unsigned(B(4 downto 0)));
                temp <= std_logic_vector(shift_left(unsigned(A), sa));

            when "0110" =>  -- SRL
                sa := to_integer(unsigned(B(4 downto 0)));
                temp <= std_logic_vector(shift_right(unsigned(A), sa));

            when "0111" =>  -- SRA
                sa := to_integer(unsigned(B(4 downto 0)));
                temp <= std_logic_vector(shift_right(signed(A), sa));

            when others =>
                temp <= (others => '0');
        end case;

        Result <= temp;
        if temp = (31 downto 0 => '0') then  -- explicit 32-bit zero check
            Zero <= '1';
        else
            Zero <= '0';
        end if;
    end process;
end architecture;
