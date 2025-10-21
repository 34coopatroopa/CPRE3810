-- ============================================================
-- onescomp.vhd
-- Performs bitwise NOT operation on an input vector.
-- This version is self-contained and does not use work.invg.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity onescomp is
    port (
        a : in  std_logic_vector(31 downto 0);
        y : out std_logic_vector(31 downto 0)
    );
end onescomp;

architecture rtl of onescomp is
begin
    -- Simple vector inversion: bitwise NOT
    y <= not a;
end rtl;
