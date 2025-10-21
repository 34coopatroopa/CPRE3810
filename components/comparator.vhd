library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity comparator is
    port (
        A, B     : in  word;
        funct3   : in  std_logic_vector(2 downto 0);
        result   : out std_logic
    );
end entity;

architecture Behavioral of comparator is
begin
    process (A, B, funct3)
    begin
        case funct3 is
            when "000" =>                 -- BEQ
                if A = B then
                    result <= '1';
                else
                    result <= '0';
                end if;

            when "001" =>                 -- BNE
                if A /= B then
                    result <= '1';
                else
                    result <= '0';
                end if;

            when "100" =>                 -- BLT
                if signed(A) < signed(B) then
                    result <= '1';
                else
                    result <= '0';
                end if;

            when "101" =>                 -- BGE
                if signed(A) >= signed(B) then
                    result <= '1';
                else
                    result <= '0';
                end if;

            when "110" =>                 -- BLTU
                if unsigned(A) < unsigned(B) then
                    result <= '1';
                else
                    result <= '0';
                end if;

            when "111" =>                 -- BGEU
                if unsigned(A) >= unsigned(B) then
                    result <= '1';
                else
                    result <= '0';
                end if;

            when others =>
                result <= '0';
        end case;
    end process;
end architecture;
