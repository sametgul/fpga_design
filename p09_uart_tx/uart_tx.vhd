library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx is
    generic(
        CLK_FREQ  : integer := 100_000_000;
        BAUD_RATE : integer := 115_200;
        STOP_BIT  : integer := 2
    );
    port(
        clk      : in  std_logic;
        start_tx : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        tx_out   : out std_logic;
        tx_done  : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is
    type t_state is (s_IDLE, s_START, s_DATA, s_END);
    signal state : t_state := s_IDLE;
    
    constant TIMER_LIM : integer := CLK_FREQ / BAUD_RATE;       -- CLK NEEDED FOR ONE BAUD PERIOD
    constant STOP_LIM  : integer := (CLK_FREQ / BAUD_RATE)*STOP_BIT;       -- CLK NEEDED FOR ONE BAUD PERIOD
    signal   timer     : integer range 0 to TIMER_LIM-1 := 0;
    signal   stop_timer: integer range 0 to STOP_LIM-1  := 0;
        
    signal   shreg   : std_logic_vector(7 downto 0) := (others => '0'); 
    signal   bit_cnt : integer range 0 to 7 := 0;
    
begin
    process(clk) begin
    if rising_edge(clk) then            
            case state is 
            when s_IDLE =>
            
                tx_done <= '0';
                tx_out  <= '1';
                
                    if (start_tx = '1') then
                        state  <= s_START;
                        tx_out <= '0';
                        shreg  <= data_in;
                    end if;
                    
            when s_START =>
            
                if (timer = TIMER_LIM-1) then
                    timer   <= 0;  
                                    
                    tx_out  <= shreg(0);
                    shreg   <= '0' & shreg(7 downto 1);
                    state   <= s_DATA;        
                else
                    timer   <= timer + 1;
                end if;  
                
            when s_DATA =>
            
                if (timer = TIMER_LIM-1) then
                    timer <= 0; 
                    
                        if(bit_cnt < 7) then
                            tx_out  <= shreg(0);
                            shreg   <= '0' & shreg(7 downto 1);
                            bit_cnt <= bit_cnt + 1;    
                        else
                            bit_cnt <= 0;
                            tx_out  <= '1';    --stop bit
                            tx_done <= '1';
                            state   <= s_END;           
                        end if;   
                           
                else
                    timer <= timer + 1;
                end if; 
            
                        
            when s_END =>
            
                if(stop_timer = STOP_LIM-1) then
                    tx_done    <= '0';
                    state      <= s_IDLE;
                    stop_timer <= 0;
                else
                    stop_timer <= stop_timer + 1;
                end if; 
                               
            end case;
        end if;
    end process;

end Behavioral;
