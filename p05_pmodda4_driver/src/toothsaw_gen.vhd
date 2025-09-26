library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity toothsaw_gen is
port(
    clk      : in std_logic;
    wrt_done : in std_logic;
    din_dac  : out std_logic_vector(11 downto 0)
);
end toothsaw_gen;

architecture Behavioral of toothsaw_gen is
    
    signal datain        : integer range 0 to 2**12-1 := 0;
    signal wrt_done_prev : std_logic := '0';
    
begin

    din_dac <= std_logic_vector(to_unsigned(datain, 12));
    process(clk) begin
        if rising_edge(clk) then
            if(wrt_done = '1' and wrt_done_prev = '0') then
                datain <= datain + 1;
            end if;
            wrt_done_prev <= wrt_done;
        end if;
    end process;

end Behavioral;
