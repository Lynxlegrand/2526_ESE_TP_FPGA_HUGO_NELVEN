library ieee;
use ieee.std_logic_1164.all;

entity dpram is
    generic (
        H_RES : natural := 1080;
        V_RES : natural := 720
    );
    port (
        -- Port A : écriture (encodeurs)
        i_clk_a   : in std_logic;
        i_we_a    : in std_logic;
        i_addr_a : in natural range 0 to H_RES*V_RES-1;
        i_data_a : in std_logic;
        
        -- Port B : lecture (HDMI)
        i_clk_b   : in std_logic;
        i_addr_b : in natural range 0 to H_RES*V_RES-1;
        o_data_b : out std_logic
    );
end entity;

architecture rtl of dpram is
    type ram_t is array (0 to H_RES*V_RES-1) of std_logic;
    shared variable ram : ram_t := (others => '0');
begin

    -- Port A : écriture
    process(i_clk_a)
    begin
        if rising_edge(i_clk_a) then
            if i_we_a = '1' then
                ram(i_addr_a) := i_data_a;
            end if;
        end if;
    end process;

    -- Port B : lecture
    process(i_clk_b)
    begin
        if rising_edge(i_clk_b) then
            o_data_b <= ram(i_addr_b);
        end if;
    end process;

end architecture;
