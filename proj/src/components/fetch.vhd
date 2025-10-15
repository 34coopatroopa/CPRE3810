library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity fetch is
    port (
        iCLK, iRST : in  std_logic;
        iBranch    : in  std_logic;
        iZero      : in  std_logic;
        iJump      : in  std_logic;
        iImm       : in  word;
        oPC        : out word
    );
end entity;

architecture Behavioral of fetch is
    signal PC, NextPC : word := (others => '0');
begin
    process(iCLK, iRST)
    begin
        if iRST = '1' then
            PC <= (others => '0');
        elsif rising_edge(iCLK) then
            PC <= NextPC;
        end if;
    end process;

    -- Next PC logic
    process(PC, iBranch, iZero, iJump, iImm)
    begin
        if (iBranch = '1' and iZero = '1') or (iJump = '1') then
            NextPC <= std_logic_vector(signed(PC) + signed(iImm));
        else
            NextPC <= std_logic_vector(signed(PC) + 4);
        end if;
    end process;

    oPC <= PC;
end architecture;
