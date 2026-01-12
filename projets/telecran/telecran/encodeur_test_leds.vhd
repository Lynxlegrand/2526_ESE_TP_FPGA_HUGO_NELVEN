library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encodeur_test_leds is
    port (
        i_clk   : in std_logic;
        i_rst_n : in std_logic;

        LEFT_A  : in std_logic;
        LEFT_B  : in std_logic;

        o_led   : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of encodeur_test_leds is

    ------------------------------------------------------------------
    -- Debouncer component
    ------------------------------------------------------------------
    component debouncer is
        generic ( TIMEOUT_CYCLES : integer );
        port (
            i_clk   : in std_logic;
            i_rst_n : in std_logic;
            i_noisy : in std_logic;
            o_clean : out std_logic
        );
    end component;

    ------------------------------------------------------------------
    -- Signaux propres encodeur
    ------------------------------------------------------------------
    signal A_clean, B_clean : std_logic;

    -- Registres pour fronts
    signal A_curr, A_prev : std_logic := '0';
    signal B_curr, B_prev : std_logic := '0';

    -- Chenillard
    signal leds : std_logic_vector(9 downto 0) := "0000000001";

begin

    ------------------------------------------------------------------
    -- DEBOUNCERS
    ------------------------------------------------------------------
    deb_A : debouncer
        generic map ( TIMEOUT_CYCLES => 50_000 )
        port map (
            i_clk   => i_clk,
            i_rst_n => i_rst_n,
            i_noisy => LEFT_A,
            o_clean => A_clean
        );

    deb_B : debouncer
        generic map ( TIMEOUT_CYCLES => 50_000 )
        port map (
            i_clk   => i_clk,
            i_rst_n => i_rst_n,
            i_noisy => LEFT_B,
            o_clean => B_clean
        );

    ------------------------------------------------------------------
    -- LOGIQUE QUADRATURE + CHENILLARD
    ------------------------------------------------------------------
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            leds <= "0000000001";
            A_curr <= '0'; A_prev <= '0';
            B_curr <= '0'; B_prev <= '0';

        elsif rising_edge(i_clk) then

            -- mémorisation états
            A_prev <= A_curr;
            A_curr <= A_clean;

            B_prev <= B_curr;
            B_curr <= B_clean;

            ------------------------------------------------------------------
            -- INCRÉMENT (LED gauche)
            ------------------------------------------------------------------
            if ((A_curr='1' and A_prev='0') and B_curr='0') or
               ((A_curr='0' and A_prev='1') and B_curr='1') then

                leds <= leds(8 downto 0) & leds(9);

            ------------------------------------------------------------------
            -- DÉCRÉMENT (LED droite)
            ------------------------------------------------------------------
            elsif ((B_curr='1' and B_prev='0') and A_curr='0') or
                  ((B_curr='0' and B_prev='1') and A_curr='1') then

                leds <= leds(0) & leds(9 downto 1);
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Sortie LED vectorielle
    ------------------------------------------------------------------
    o_led <= leds;

end architecture;
