library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity detect is
    Port (
        clk : in STD_LOGIC;
        A   : in STD_LOGIC;
        E   : out STD_LOGIC
    );
end detect;

architecture Behavioral of detect is
    signal Q1, Q2 : STD_LOGIC;
begin

    -- Première bascule D
    process(clk)
    begin
        if rising_edge(clk) then
            Q1 <= A;
        end if;
    end process;

    -- Deuxième bascule D
    process(clk)
    begin
        if rising_edge(clk) then
            Q2 <= Q1;
        end if;
    end process;

    -- XOR entre Q1 et Q2
    E <= Q1 xor Q2;

end Behavioral;
