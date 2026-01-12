library ieee;
use ieee.std_logic_1164.all;

entity I2C_HDMI_Config_wrapper is
    port (
        iCLK        : in  std_logic;
        iRST_N      : in  std_logic;
        I2C_SCLK    : out std_logic;
        I2C_SDAT    : inout std_logic;
        HDMI_TX_INT : in  std_logic;
        READY       : out std_logic
    );
end entity;

architecture rtl of I2C_HDMI_Config_wrapper is
begin

    -- Instanciation du module Verilog
    I2C_HDMI_Config_inst : entity work.I2C_HDMI_Config
        port map (
            iCLK        => iCLK,
            iRST_N      => iRST_N,
            I2C_SCLK    => I2C_SCLK,
            I2C_SDAT    => I2C_SDAT,
            HDMI_TX_INT => HDMI_TX_INT,
            READY       => READY
        );

end architecture;
