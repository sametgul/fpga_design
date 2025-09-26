library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
port(
    clk : in std_logic;
    CSn : out std_logic;
    MOSI: out std_logic;
    SCLK: out std_logic
);
end top;

architecture Behavioral of top is
    
    signal datain        : integer range 0 to 2**12-1 := 0;
    signal wrt_done      : std_logic;
    signal wrt_done_prev : std_logic := '0';
    signal din_dac       : std_logic_vector(11 downto 0) := (others => '0');
    
begin

    process(clk) begin
        if rising_edge(clk) then
            if(wrt_done = '1' and wrt_done_prev = '0') then
                datain <= datain + 1;
            end if;
            wrt_done_prev <= wrt_done;
        end if;
    end process;

    din_dac <= std_logic_vector(to_unsigned(datain, 12));
    DAC: entity work.dig2an
    Port map( 
        clk100mhz => clk,
        din_dac   => din_dac,
        CS        => CSn,
        MOSI      => MOSI,
        SCLK      => SCLK,
        wrt_done  => wrt_done
    );


end Behavioral;
