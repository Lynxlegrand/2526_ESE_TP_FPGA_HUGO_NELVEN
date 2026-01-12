library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pll;
use pll.all;

entity telecran is
    port (
        -- FPGA
        i_clk_50 : in std_logic;

        -- HDMI
        io_hdmi_i2c_scl : inout std_logic;
        io_hdmi_i2c_sda : inout std_logic;
        o_hdmi_tx_clk   : out std_logic;
        o_hdmi_tx_d     : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de    : out std_logic;
        o_hdmi_tx_hs    : out std_logic;
        i_hdmi_tx_int   : in std_logic;
        o_hdmi_tx_vs    : out std_logic;

        -- Reset
        i_rst_n : in std_logic;

        -- LEDs
        o_leds      : out std_logic_vector(9 downto 0);
        o_de10_leds : out std_logic_vector(7 downto 0);

        -- Encodeurs
        LEFT_A  : in std_logic;
        LEFT_B  : in std_logic;
        RIGHT_A : in std_logic;
        RIGHT_B : in std_logic
    );
end entity;

architecture rtl of telecran is

    ------------------------------------------------------------------
    -- COMPONENTS
    ------------------------------------------------------------------
    component pll
        port (
            refclk   : in  std_logic;
            rst      : in  std_logic;
            outclk_0 : out std_logic;
            locked   : out std_logic
        );
    end component;

    component I2C_HDMI_Config
        port (
            iCLK        : in  std_logic;
            iRST_N      : in  std_logic;
            I2C_SCLK    : out std_logic;
            I2C_SDAT    : inout std_logic;
            HDMI_TX_INT : in  std_logic
        );
    end component;

    component hdmi_controler
        generic (
            H_RES : natural := 1080;
            V_RES : natural := 720
        );
        port (
            i_clk         : in  std_logic;
            i_rst_n       : in  std_logic;
            o_hdmi_tx_clk : out std_logic;
            o_hdmi_tx_de  : out std_logic;
            o_hdmi_tx_hs  : out std_logic;
            o_hdmi_tx_vs  : out std_logic;
            o_x_counter   : out unsigned(10 downto 0);
            o_y_counter   : out unsigned(9 downto 0)
        );
    end component;

    component encodeur_controller
        generic (N_BITS : integer := 8);
        port (
            i_clk   : in  std_logic;
            i_rst_n : in  std_logic;
            i_a     : in  std_logic;
            i_b     : in  std_logic;
            o_led   : out std_logic_vector(9 downto 0);
            o_count : out unsigned(N_BITS-1 downto 0)
        );
    end component;

    component dpram
        generic (
            H_RES : natural := 1080;
            V_RES : natural := 720
        );
        port (
            i_clk_a  : in std_logic;
            i_we_a   : in std_logic;
            i_addr_a : in natural range 0 to H_RES*V_RES-1;
            i_data_a : in std_logic;

            i_clk_b  : in std_logic;
            i_addr_b : in natural range 0 to H_RES*V_RES-1;
            o_data_b : out std_logic
        );
    end component;

    ------------------------------------------------------------------
    -- INTERNAL SIGNALS
    ------------------------------------------------------------------
    signal s_clk_27 : std_logic;
    signal s_rst_n  : std_logic;

    signal s_hdmi_tx_de : std_logic;
    signal s_hdmi_pixel : std_logic_vector(23 downto 0);

    signal s_x_counter : unsigned(10 downto 0);
    signal s_y_counter : unsigned(9 downto 0);

    signal s_x_count_8 : unsigned(7 downto 0);
    signal s_y_count_8 : unsigned(7 downto 0);

    signal s_x_pos : unsigned(10 downto 0);
    signal s_y_pos : unsigned(9 downto 0);

    signal s_fb_wr_addr : natural range 0 to 1080*720-1;
    signal s_fb_rd_addr : natural range 0 to 1080*720-1;
    signal s_fb_rd_data : std_logic;

    -- Curseur overlay
    signal s_cursor_on : std_logic;

begin

    ------------------------------------------------------------------
    -- LEDS
    ------------------------------------------------------------------
    o_leds      <= (others => '0');
    o_de10_leds <= (others => '0');

    ------------------------------------------------------------------
    -- PLL
    ------------------------------------------------------------------
    pll0 : pll
        port map (
            refclk   => i_clk_50,
            rst      => not i_rst_n,
            outclk_0 => s_clk_27,
            locked   => s_rst_n
        );

    ------------------------------------------------------------------
    -- HDMI I2C
    ------------------------------------------------------------------
    I2C_HDMI_Config0 : I2C_HDMI_Config
        port map (
            iCLK        => i_clk_50,
            iRST_N      => i_rst_n,
            I2C_SCLK    => io_hdmi_i2c_scl,
            I2C_SDAT    => io_hdmi_i2c_sda,
            HDMI_TX_INT => i_hdmi_tx_int
        );

    ------------------------------------------------------------------
    -- HDMI controller
    ------------------------------------------------------------------
    hdmi0 : hdmi_controler
        generic map (
            H_RES => 1080,
            V_RES => 720
        )
        port map (
            i_clk         => s_clk_27,
            i_rst_n       => s_rst_n,
            o_hdmi_tx_clk => o_hdmi_tx_clk,
            o_hdmi_tx_de  => s_hdmi_tx_de,
            o_hdmi_tx_hs  => o_hdmi_tx_hs,
            o_hdmi_tx_vs  => o_hdmi_tx_vs,
            o_x_counter   => s_x_counter,
            o_y_counter   => s_y_counter
        );

    o_hdmi_tx_de <= s_hdmi_tx_de;

    ------------------------------------------------------------------
    -- Encodeurs
    ------------------------------------------------------------------
    left_encoder : encodeur_controller
        port map (
            i_clk   => s_clk_27,
            i_rst_n => s_rst_n,
            i_a     => LEFT_A,
            i_b     => LEFT_B,
            o_led   => open,
            o_count => s_x_count_8
        );

    right_encoder : encodeur_controller
        port map (
            i_clk   => s_clk_27,
            i_rst_n => s_rst_n,
            i_a     => RIGHT_A,
            i_b     => RIGHT_B,
            o_led   => open,
            o_count => s_y_count_8
        );

    ------------------------------------------------------------------
    -- Mise à l’échelle encodeur → écran
    ------------------------------------------------------------------
    s_x_pos <= resize(s_x_count_8, 11) sll 2;
    s_y_pos <= resize(s_y_count_8, 10) sll 2;

    ------------------------------------------------------------------
    -- Framebuffer read address
    ------------------------------------------------------------------
    s_fb_rd_addr <= to_integer(s_y_counter) * 1080 + to_integer(s_x_counter);

    ------------------------------------------------------------------
    -- DPRAM
    ------------------------------------------------------------------
    framebuffer : dpram
        generic map (
            H_RES => 1080,
            V_RES => 720
        )
        port map (
            i_clk_a  => s_clk_27,
            i_we_a   => '1',
            i_addr_a => s_fb_wr_addr,
            i_data_a => '1',
            i_clk_b  => s_clk_27,
            i_addr_b => s_fb_rd_addr,
            o_data_b => s_fb_rd_data
        );

    ------------------------------------------------------------------
    -- Écriture traînée 2x2 en RAM
    ------------------------------------------------------------------
    process(s_clk_27)
        variable x, y : natural;
    begin
        if rising_edge(s_clk_27) then
            for dx in 0 to 1 loop
                for dy in 0 to 1 loop
                    x := to_integer(s_x_pos) + dx;
                    y := to_integer(s_y_pos) + dy;
                    if x < 1080 and y < 720 then
                        s_fb_wr_addr <= y * 1080 + x;
                    end if;
                end loop;
            end loop;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Curseur 4x4 (overlay)
    ------------------------------------------------------------------
    process(s_x_counter, s_y_counter, s_x_pos, s_y_pos)
    begin
        if (to_integer(s_x_counter) >= to_integer(s_x_pos) and
            to_integer(s_x_counter) <  to_integer(s_x_pos) + 4 and
            to_integer(s_y_counter) >= to_integer(s_y_pos) and
            to_integer(s_y_counter) <  to_integer(s_y_pos) + 4) then
            s_cursor_on <= '1';
        else
            s_cursor_on <= '0';
        end if;
    end process;

    ------------------------------------------------------------------
    -- Génération HDMI (priorités)
    ------------------------------------------------------------------
    process(s_clk_27)
    begin
        if rising_edge(s_clk_27) then
            if s_rst_n = '0' then
                s_hdmi_pixel <= (others => '0');

            elsif s_hdmi_tx_de = '1' then

                if s_cursor_on = '1' then
                    s_hdmi_pixel <= x"FF0000"; -- curseur rouge
                elsif s_fb_rd_data = '1' then
                    s_hdmi_pixel <= x"FFFFFF"; -- traînée
                else
                    s_hdmi_pixel <= x"000000"; -- fond
                end if;

            else
                s_hdmi_pixel <= x"000000";
            end if;
        end if;
    end process;

    o_hdmi_tx_d <= s_hdmi_pixel;

end architecture;
