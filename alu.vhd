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
end entity alu;

architecture Behavioral of alu is
begin
  process(A, B, ALU_Sel)
    variable a_s, b_s, tmp : signed(31 downto 0);
    variable a_u, b_u      : unsigned(31 downto 0);
    variable zero_flag     : std_logic;
  begin
    a_s := signed(A);  
    b_s := signed(B);
    a_u := unsigned(A); 
    b_u := unsigned(B);
    tmp := (others => '0');
    zero_flag := '0';

    case ALU_Sel is
      when "0000" => tmp := a_s + b_s;                                          -- ADD
      when "0001" => tmp := a_s - b_s;                                          -- SUB
      when "0010" => tmp := signed(A and B);                                    -- AND
      when "0011" => tmp := signed(A or  B);                                    -- OR
      when "0100" => tmp := signed(A xor B);                                    -- XOR

      when "0110" =>                                                           -- SLT (signed)
        if a_s < b_s then 
          tmp := to_signed(1, 32); 
        else 
          tmp := to_signed(0, 32);
        end if;

      when "1010" =>                                                           -- SLTU (unsigned)
        if a_u < b_u then 
          tmp := to_signed(1, 32); 
        else 
          tmp := to_signed(0, 32);
        end if;

      when "0111" => tmp := shift_left(a_s, to_integer(unsigned(B(4 downto 0))));                   -- SLL
      when "1000" => tmp := signed(shift_right(unsigned(A), to_integer(unsigned(B(4 downto 0)))));   -- SRL
      when "1001" => tmp := shift_right(a_s, to_integer(unsigned(B(4 downto 0))));                   -- SRA
      when others => tmp := (others => '0');
    end case;

    -- standard VHDL-93 conditional test
    if tmp = to_signed(0, 32) then
      zero_flag := '1';
    else
      zero_flag := '0';
    end if;

    Result <= std_logic_vector(tmp);
    Zero   <= zero_flag;
  end process;
end architecture Behavioral;
