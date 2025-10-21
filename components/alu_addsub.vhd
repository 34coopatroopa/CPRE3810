library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

-- Simple add/sub block used by the ALU (optional helper)
entity alu_addsub is
    port (
        A         : in  word;
        B         : in  word;
        nAdd_Sub  : in  std_logic;  -- 0 = add, 1 = sub
        S         : out word
    );
end entity;

architecture rtl of alu_addsub is
begin
    process (A, B, nAdd_Sub)
    begin
        if nAdd_Sub = '1' then
            S <= std_logic_vector(signed(A) - signed(B));
        else
            S <= std_logic_vector(signed(A) + signed(B));
        end if;
    end process;
end architecture;
