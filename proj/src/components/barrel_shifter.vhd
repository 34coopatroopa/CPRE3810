library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity barrel_shifter is
    port (
        A        : in  word;
        shamt    : in  std_logic_vector(4 downto 0);
        dir      : in  std_logic;  -- '0' = left, '1' = right
        arith    : in  std_logic;  -- '1' = arithmetic right
        Result   : out word
    );
end entity;

architecture Behavioral of barrel_shifter is
    signal tmp : word;
begin
    process(A, shamt, dir, arith)
        variable amt : integer range 0 to 31;
    begin
        amt := to_integer(unsigned(shamt));

        if dir = '0' then  -- Shift left
            tmp <= std_logic_vector(shift_left(unsigned(A), amt));
        else               -- Shift right
            if arith = '1' then
                tmp <= std_logic_vector(shift_right(signed(A), amt));
            else
                tmp <= std_logic_vector(shift_right(unsigned(A), amt));
            end if;
        end if;

        Result <= tmp;
    end process;
end architecture;
