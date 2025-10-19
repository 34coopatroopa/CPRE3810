library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
        A        : in  std_logic_vector(31 downto 0);
        B        : in  std_logic_vector(31 downto 0);
        ALU_Sel  : in  std_logic_vector(3 downto 0);  -- control input
        Result   : out std_logic_vector(31 downto 0);
        Zero     : out std_logic                     -- asserted if Result == 0
    );
end alu;

architecture behavioral of alu is
begin

    -- fully combinational ALU process
    process(all)
        variable a_signed : signed(31 downto 0);
        variable b_signed : signed(31 downto 0);
        variable temp     : signed(31 downto 0);
    begin
        -- defaults
        a_signed := signed(A);
        b_signed := signed(B);
        temp     := (others => '0');

        case ALU_Sel is
            ----------------------------------------------------------------
            -- Arithmetic operations
            ----------------------------------------------------------------
            when "0000" =>  -- ADD / ADDI
                temp := a_signed + b_signed;

            when "0001" =>  -- SUB
                temp := a_signed - b_signed;

            ----------------------------------------------------------------
            -- Logical operations
            ----------------------------------------------------------------
            when "0010" =>  -- AND
                temp := signed(A and B);

            when "0011" =>  -- OR
                temp := signed(A or B);

            when "0100" =>  -- XOR
                temp := signed(A xor B);

            when "0101" =>  -- NOR
                temp := signed(not (A or B));

            ----------------------------------------------------------------
            -- Set less than (signed)
            ----------------------------------------------------------------
            when "0110" =>
                if a_signed < b_signed then
                    temp := to_signed(1, 32);
                else
                    temp := to_signed(0, 32);
                end if;

            ----------------------------------------------------------------
            -- Shift operations
            ----------------------------------------------------------------
            when "0111" =>  -- SLL (logical left)
                temp := shift_left(a_signed, to_integer(unsigned(B(4 downto 0))));

            when "1000" =>  -- SRL (logical right)
                temp := shift_right(signed(unsigned(A)), to_integer(unsigned(B(4 downto 0))));

            when "1001" =>  -- SRA (arithmetic right)
                temp := shift_right(a_signed, to_integer(unsigned(B(4 downto 0))));

            ----------------------------------------------------------------
            -- Default case
            ----------------------------------------------------------------
            when others =>
                temp := (others => '0');
        end case;

        Result <= std_logic_vector(temp);
        Zero   <= '1' when temp = 0 else '0';
    end process;

end behavioral;
