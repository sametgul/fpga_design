
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_top is
end tb_top;

architecture Behavioral of tb_top is

    constant CLK_PERIOD : time      := 10 ns;
    signal   clk        : std_logic := '0';
    
    signal CSn : std_logic;
    signal MOSI: std_logic;
    signal SCLK: std_logic;

begin

    pCLK_GEN: process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    
    DUT: entity work.top
    port map(
        clk  => clk,
        CSn  => CSn ,
        MOSI => MOSI,
        SCLK => SCLK
    );


end Behavioral;
