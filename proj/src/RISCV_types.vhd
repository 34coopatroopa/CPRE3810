library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package RISCV_types is

    --------------------------------------------------------------------------
    -- Common type definitions for RISC-V processor design
    --------------------------------------------------------------------------

    -- Core constants
    constant DATA_WIDTH : integer := 32;
    constant ADDR_WIDTH : integer := 32;

    -- 32-bit word
    subtype word is std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- Array of 32 words (used in regfile)
    type word_array is array (31 downto 0) of word;

    -- ALU operation type (for control signals)
    type alu_ops is (
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_OR,
        ALU_XOR,
        ALU_SLL,
        ALU_SRL,
        ALU_SRA,
        ALU_SLT,
        ALU_SLTU
    );

end package RISCV_types;

package body RISCV_types is
end package body RISCV_types;
