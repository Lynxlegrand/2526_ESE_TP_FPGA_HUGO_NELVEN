library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encodeur_controller is
    generic (
        N_BITS : integer := 8;  -- taille du compteur
        TIMEOUT_CYCLES : integer := 50_000  -- débounce
    );
    port (
        i_clk   : in std_logic;
        i_rst_n : in std_logic;
        i_a     : in std_logic;
        i_b     : in std_logic;
        o_led   : out std_logic_vector(9 downto 0);
        o_count : out unsigned(N_BITS-1 downto 0)
    );
end entity;

architecture rtl of encodeur_controller is

    -- Signaux internes pour debouncer
    signal A_clean, B_clean : std_logic;
    signal A_curr, A_prev : std_logic := '0';
    signal B_curr, B_prev : std_logic := '0';
    signal r_counter : unsigned(N_BITS-1 downto 0) := (others => '0');

    -- Chenillard LED
    signal leds : std_logic_vector(9 downto 0) := "0000000001";

    -- Compteurs pour debouncer
    signal cntA, cntB : integer := 0;
    signal syncA, syncB : std_logic := '0';

begin

    ------------------------------------------------------------------
    -- Debouncer interne A
    ------------------------------------------------------------------
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                cntA <= 0;
                syncA <= '0';
                A_clean <= '0';
            else
                if i_a = syncA then
                    if cntA < TIMEOUT_CYCLES then
                        cntA <= cntA + 1;
                    else
                        A_clean <= syncA;
                    end if;
                else
                    cntA <= 0;
                    syncA <= i_a;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Debouncer interne B
    ------------------------------------------------------------------
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                cntB <= 0;
                syncB <= '0';
                B_clean <= '0';
            else
                if i_b = syncB then
                    if cntB < TIMEOUT_CYCLES then
                        cntB <= cntB + 1;
                    else
                        B_clean <= syncB;
                    end if;
                else
                    cntB <= 0;
                    syncB <= i_b;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Logique quadrature
    ------------------------------------------------------------------
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                A_curr <= '0'; A_prev <= '0';
                B_curr <= '0'; B_prev <= '0';
                r_counter <= (others => '0');
                leds <= "0000000001";
            else
                -- mémorisation états
                A_prev <= A_curr;
                A_curr <= A_clean;
                B_prev <= B_curr;
                B_curr <= B_clean;

                -- Incrément
                if ((A_curr='1' and A_prev='0') and B_curr='0') or
                   ((A_curr='0' and A_prev='1') and B_curr='1') then
                    r_counter <= r_counter + 1;
                    leds <= leds(8 downto 0) & leds(9);
                -- Décrément
                elsif ((B_curr='1' and B_prev='0') and A_curr='0') or
                      ((B_curr='0' and B_prev='1') and A_curr='1') then
                    r_counter <= r_counter - 1;
                    leds <= leds(0) & leds(9 downto 1);
                end if;
            end if;
        end if;
    end process;

    -- Sorties
    o_count <= r_counter;
    o_led <= leds;

end architecture;
