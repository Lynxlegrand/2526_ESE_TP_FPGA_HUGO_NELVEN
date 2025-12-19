library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity TP1_FPGA_CORDI_THEBAULT is
    port (
        i_clk : in std_logic;
        i_rst_n : in std_logic;
		  
		  
        o_led0 : out std_logic;
        o_led1 : out std_logic;
        o_led2 : out std_logic;
        o_led3 : out std_logic;
        o_led4 : out std_logic;
        o_led5 : out std_logic;
        o_led6 : out std_logic;
        o_led7 : out std_logic;
        o_led8 : out std_logic;
        o_led9 : out std_logic
       
    );
end entity TP1_FPGA_CORDI_THEBAULT;

architecture rtl of TP1_FPGA_CORDI_THEBAULT is

    signal counter : unsigned(25 downto 0) := (others => '0');
    signal leds    : std_logic_vector(9 downto 0) := "0000000001";

begin

    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
           
            counter <= (others => '0');
            leds    <= "0000000001";

        elsif rising_edge(i_clk) then

            if counter = 12_500_000 - 1 then   -- 0.25 seconde
                counter <= (others => '0');

                leds <= leds(0) & leds(9 downto 1);

            else
                counter <= counter + 1;
            end if;

        end if;
    end process;

    -- Assignation GPIO
    o_led0 <= leds(0);
    o_led1 <= leds(1);
    o_led2 <= leds(2);
    o_led3 <= leds(3);
    o_led4 <= leds(4);
    o_led5 <= leds(5);
    o_led6 <= leds(6);
    o_led7 <= leds(7);
    o_led8 <= leds(8);
    o_led9 <= leds(9);

end architecture;