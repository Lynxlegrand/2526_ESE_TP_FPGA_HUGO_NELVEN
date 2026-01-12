library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity detect is
    Port (
        clk : in  STD_LOGIC;
        A   : in  STD_LOGIC;
        B   : in  STD_LOGIC;
        E   : out STD_LOGIC;
        F   : out STD_LOGIC
    );
end detect;

architecture Behavioral of detect is
    signal Q1A, Q2A : STD_LOGIC;
    signal Q1B, Q2B : STD_LOGIC;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            Q1A <= A;
            Q2A <= Q1A;
            Q1B <= B;
            Q2B <= Q1B;
        end if;
    end process;

    E <= Q1A xor Q2A;
    F <= Q1B xor Q2B;

end Behavioral;

