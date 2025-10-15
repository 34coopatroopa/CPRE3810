library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

-- ==========================================================
-- Register File (32 registers, 32-bit each)
-- Two read ports, one write port
-- ==========================================================

entity regfile is
    port (
        i_CLK : in  std_logic;
        i_RST : in  std_logic;
        i_WE  : in  std_logic;                     -- write enable
        i_RD  : in  std_logic_vector(4 downto 0);  -- write register index
        i_D   : in  word;                          -- write data
        i_RS1 : in  std_logic_vector(4 downto 0);  -- read register 1 index
        i_RS2 : in  std_logic_vector(4 downto 0);  -- read register 2 index
        o_RS1 : out word;                          -- read data 1
        o_RS2 : out word                           -- read data 2
    );
end entity regfile;

architecture structural of regfile is

    -- COMPONENT DECLARATIONS ------------------------------
    component decoder5to32
        port(
            i_S : in  std_logic_vector(4 downto 0);
            o_Y : out std_logic_vector(31 downto 0)
        );
    end component;

    component dffn
        port(
            iCLK : in  std_logic;
            iRST : in  std_logic;
            iD   : in  std_logic;
            oQ   : out std_logic
        );
    end component;

    component mux32to1
        port(
            i_S  : in  std_logic_vector(4 downto 0);
            i_D  : in  word_array;
            o_F  : out word
        );
    end component;
    ---------------------------------------------------------

    signal s_decoder_out : std_logic_vector(31 downto 0);
    signal s_reg_en      : std_logic_vector(31 downto 0);
    signal s_reg_out     : word_array;

begin
    -- Decode the write register number
    DEC : decoder5to32
        port map(
            i_S => i_RD,
            o_Y => s_decoder_out
        );

    -- Generate per-register write enables
    gen_enables : for i in 0 to 31 generate
        s_reg_en(i) <= i_WE and s_decoder_out(i);
    end generate;

    -- Instantiate 32 registers (each 32-bit)
    gen_regs : for i in 0 to 31 generate
        process(i_CLK, i_RST)
        begin
            if (i_RST = '1') then
                s_reg_out(i) <= (others => '0');
            elsif rising_edge(i_CLK) then
                if s_reg_en(i) = '1' then
                    s_reg_out(i) <= i_D;
                end if;
            end if;
        end process;
    end generate;

    -- Read muxes
    MUX1 : mux32to1
        port map(
            i_S => i_RS1,
            i_D => s_reg_out,
            o_F => o_RS1
        );

    MUX2 : mux32to1
        port map(
            i_S => i_RS2,
            i_D => s_reg_out,
            o_F => o_RS2
        );

end architecture structural;
