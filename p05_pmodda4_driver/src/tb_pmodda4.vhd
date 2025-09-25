----------------------------------------------------------------------------------
-- 23/09/2025
-- Samet GUL
-- https://github.com/sametgul
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_pmodda4 is
end tb_pmodda4;

architecture Behavioral of tb_pmodda4 is

    constant CLK_PERIOD : time      := 10 ns;
    signal   clk        : std_logic := '0';
    
    signal din_dac   : std_logic_vector(11 downto 0) := x"ABC";
    signal CSn       :  STD_LOGIC;                     
    signal MOSI      :  STD_LOGIC;                    
    signal SCLK      :  STD_LOGIC;                     
    signal wrt_done  :  STD_LOGIC;  
    
    signal data_out  : std_logic_vector(11 downto 0);                   

begin

    pSTIMULI: process begin
        wait for CLK_PERIOD*600;
        
        assert false
        report "SIM DONE"
        severity failure;
    end process;
    
    DUT: entity work.dig2an
    Port map(  
        clk100mhz => clk,
        din_dac   => din_dac,
        CS        => CSn,
        MOSI      => MOSI,
        SCLK      => SCLK,
        wrt_done  => wrt_done
    );


    pCLK_GEN: process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

end Behavioral;
