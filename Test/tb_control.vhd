library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity tb_control is
end tb_control;

architecture behavior of tb_control is
    -- DUT Declaration
    component control
        port (
            opcode    : in  std_logic_vector(6 downto 0);
            funct3    : in  std_logic_vector(2 downto 0);
            funct7    : in  std_logic_vector(6 downto 0);
            ALU_Sel   : out std_logic_vector(3 downto 0);
            RegWrite  : out std_logic;
            MemRead   : out std_logic;
            MemWrite  : out std_logic;
            Branch    : out std_logic
        );
    end component;

    -- Test signals
    signal opcode   : std_logic_vector(6 downto 0) := (others => '0');
    signal funct3   : std_logic_vector(2 downto 0) := (others => '0');
    signal funct7   : std_logic_vector(6 downto 0) := (others => '0');
    signal ALU_Sel  : std_logic_vector(3 downto 0);
    signal RegWrite : std_logic;
    signal MemRead  : std_logic;
    signal MemWrite : std_logic;
    signal Branch   : std_logic;

begin
    -- Instantiate DUT
    uut: control
        port map (
            opcode    => opcode,
            funct3    => funct3,
            funct7    => funct7,
            ALU_Sel   => ALU_Sel,
            RegWrite  => RegWrite,
            MemRead   => MemRead,
            MemWrite  => MemWrite,
            Branch    => Branch
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- R-type ADD (opcode=0110011, funct3=000, funct7=0000000)
        opcode <= "0110011"; funct3 <= "000"; funct7 <= "0000000";
        wait for 20 ns;

        -- R-type SUB (opcode=0110011, funct3=000, funct7=0100000)
        opcode <= "0110011"; funct3 <= "000"; funct7 <= "0100000";
        wait for 20 ns;

        -- R-type AND (funct3=111)
        opcode <= "0110011"; funct3 <= "111"; funct7 <= "0000000";
        wait for 20 ns;

        -- R-type OR (funct3=110)
        opcode <= "0110011"; funct3 <= "110"; funct7 <= "0000000";
        wait for 20 ns;

        -- I-type ADDI (opcode=0010011)
        opcode <= "0010011"; funct3 <= "000"; funct7 <= "0000000";
        wait for 20 ns;

        -- LW (opcode=0000011)
        opcode <= "0000011"; funct3 <= "010"; funct7 <= "0000000";
        wait for 20 ns;

        -- SW (opcode=0100011)
        opcode <= "0100011"; funct3 <= "010"; funct7 <= "0000000";
        wait for 20 ns;

        -- BEQ (opcode=1100011, funct3=000)
        opcode <= "1100011"; funct3 <= "000"; funct7 <= "0000000";
        wait for 20 ns;

        -- Default (invalid opcode)
        opcode <= "1111111"; funct3 <= "000"; funct7 <= "0000000";
        wait for 20 ns;

        assert false report "Simulation complete." severity note;
        wait;
    end process;
end behavior;