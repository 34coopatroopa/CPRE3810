library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
        A        : in  std_logic_vector(31 downto 0);
        B        : in  std_logic_vector(31 downto 0);
        ALU_Sel  : in  std_logic_vector(3 downto 0);
        Result   : out std_logic_vector(31 downto 0);
        Zero     : out std_logic
    );
end alu;

architecture Behavioral of alu is
begin
    process (A, B, ALU_Sel)
        variable tmp : signed(31 downto 0);
    begin
        tmp := (others => '0');

        case ALU_Sel is
            when "0000" => tmp := signed(A) + signed(B); -- ADD
            when "0001" => tmp := signed(A) - signed(B); -- SUB
            when "0010" => tmp := signed(A and B);       -- AND
            when "0011" => tmp := signed(A or B);        -- OR
            when "0100" => tmp := signed(A xor B);       -- XOR
            when "0101" => tmp := signed(not (A or B));  -- NOR
            when "0110" =>
                if signed(A) < signed(B) then
                    tmp := to_signed(1, 32);
                else
                    tmp := to_signed(0, 32);
                end if;
            when "0111" =>
                tmp := shift_left(signed(A), to_integer(unsigned(B(4 downto 0))));
            when "1000" =>
                tmp := signed(shift_right(unsigned(A), to_integer(unsigned(B(4 downto 0)))));
            when "1001" =>
                tmp := shift_right(signed(A), to_integer(unsigned(B(4 downto 0))));
            when others =>
                tmp := (others => '0');
        end case;

        Result <= std_logic_vector(tmp);
        if tmp = 0 then
            Zero <= '1';
        else
            Zero <= '0';
        end if;
    end process;
end Behavioral;
