library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_detect is
end tb_detect;

architecture sim of tb_detect is

    signal clk : std_logic := '0';
    signal A   : std_logic := '0';
    signal B   : std_logic := '0';
    signal E   : std_logic;
    signal F   : std_logic;

begin

    ----------------------------------------------------------------
    -- Horloge : 50 MHz → période 20 ns
    ----------------------------------------------------------------
    clk <= not clk after 10 ns;

    ----------------------------------------------------------------
    -- Instance du DUT
    ----------------------------------------------------------------
    uut : entity work.detect
        port map (
            clk => clk,
            A   => A,
            B   => B,
            E   => E,
            F   => F
        );

    ----------------------------------------------------------------
    -- Génération des signaux A et B en quadrature
    -- A : période 80 ns
    -- B : décalé de 90° (20 ns)
    ----------------------------------------------------------------
    process
    begin
        -- état initial
        A <= '0';
        B <= '0';

        wait for 20 ns;
        B <= '1';

        wait for 20 ns;
        A <= '1';

        wait for 20 ns;
        B <= '0';

        wait for 20 ns;
        A <= '0';

        -- boucle
        wait;
    end process;

end sim;
