library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem is
    generic (
        DATA_WIDTH : natural := 32;
        ADDR_WIDTH : natural := 10
    );
    port (
        clk   : in  std_logic;
        addr  : in  std_logic_vector(31 downto 0);  -- full 32-bit address
        data  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        we    : in  std_logic := '0';
        q     : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end mem;

architecture rtl of mem is
    subtype word_t  is std_logic_vector(DATA_WIDTH-1 downto 0);
    type    memory_t is array (0 to 2**ADDR_WIDTH - 1) of word_t;

    signal ram : memory_t := (others => (others => '0'));
    signal addr_index : integer range 0 to 2**ADDR_WIDTH - 1 := 0;
begin
    -- Safely compute index; clamp to valid range to prevent simulation crash
    process(addr)
        variable temp : unsigned(ADDR_WIDTH+1 downto 2);
        variable idx  : integer;
    begin
        temp := (others => '0');
        temp := unsigned(addr(ADDR_WIDTH+1 downto 2));
        idx  := to_integer(temp);
        if idx < 0 then
            addr_index <= 0;
        elsif idx > 2**ADDR_WIDTH - 1 then
            addr_index <= 2**ADDR_WIDTH - 1;
        else
            addr_index <= idx;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(addr_index) <= data;
            end if;
        end if;
    end process;

    q <= ram(addr_index);
end rtl;
