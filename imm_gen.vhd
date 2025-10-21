library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity imm_gen is
  port (
    instr : in  word;
    imm   : out word
  );
end entity;

architecture rtl of imm_gen is
begin
  --------------------------------------------------------------------
  -- Immediate generator for RISC-V (RV32I)
  -- Works with VHDL-93 (no concatenation ambiguity)
  --------------------------------------------------------------------
  process(instr)
    variable opcode : std_logic_vector(6 downto 0);
    variable result : std_logic_vector(31 downto 0);
  begin
    opcode := instr(6 downto 0);
    result := (others => '0');

    case opcode is
      ----------------------------------------------------------------
      -- I-type (ADDI / ORI / ANDI / LW / JALR)
      ----------------------------------------------------------------
      when "0010011" | "0000011" | "1100111" =>
        -- bits [11:0] = instr[31:20], sign-extend from bit 11
        result(11 downto 0) := instr(31 downto 20);
        for i in 31 downto 12 loop
          result(i) := instr(31);
        end loop;

      ----------------------------------------------------------------
      -- S-type (SW)
      ----------------------------------------------------------------
      when "0100011" =>
        -- imm[11:5] = instr[31:25], imm[4:0] = instr[11:7]
        result(11 downto 5) := instr(31 downto 25);
        result(4 downto 0)  := instr(11 downto 7);
        -- sign-extend
        for i in 31 downto 12 loop
          result(i) := instr(31);
        end loop;

      ----------------------------------------------------------------
      -- B-type (branches)
      -- imm = { imm[12|10:5|4:1|11], 0 }
      ----------------------------------------------------------------
      when "1100011" =>
        result(12)           := instr(31);
        result(11)           := instr(7);
        result(10 downto 5)  := instr(30 downto 25);
        result(4 downto 1)   := instr(11 downto 8);
        result(0)            := '0';
        for i in 31 downto 13 loop
          result(i) := instr(31);
        end loop;

      ----------------------------------------------------------------
      -- U-type (LUI / AUIPC)
      -- imm = upper 20 bits << 12
      ----------------------------------------------------------------
      when "0110111" | "0010111" =>
        result(31 downto 12) := instr(31 downto 12);
        result(11 downto 0)  := (others => '0');

      ----------------------------------------------------------------
      -- J-type (JAL)
      -- imm = { imm[20|10:1|11|19:12], 0 }
      ----------------------------------------------------------------
      when "1101111" =>
        result(20)           := instr(31);
        result(19 downto 12) := instr(19 downto 12);
        result(11)           := instr(20);
        result(10 downto 1)  := instr(30 downto 21);
        result(0)            := '0';
        -- sign-extend
        for i in 31 downto 21 loop
          result(i) := instr(31);
        end loop;

      ----------------------------------------------------------------
      -- Default (unrecognized opcode)
      ----------------------------------------------------------------
      when others =>
        result := (others => '0');
    end case;

    imm <= result;
  end process;
end architecture;
