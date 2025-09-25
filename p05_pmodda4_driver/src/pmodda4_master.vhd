library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dig2an is
Port ( 
	clk100mhz : in  STD_LOGIC;
	din_dac   : in  STD_LOGIC_VECTOR (11 downto 0); -- data to write to DAC
	CS        : out STD_LOGIC;                      -- chip select (LOW when write DAC)
	MOSI      : out STD_LOGIC;                      -- DAC's data line
	SCLK      : out STD_LOGIC;                      -- DAC's clock line
	wrt_done  : out STD_LOGIC
);
end dig2an;

architecture Behavioral of dig2an is
	-- DAC state machine
	type state_type is (idle_dac, init_dac, func_dac, wrt_dac, sDone);
	signal state : state_type := idle_dac;
	-- DAC signals
	-- counter to track DAC's output
	signal count : integer range 0 to 32 := 0; -- to control DAC operation
	-- data to write to DAC
	signal data : std_logic_vector (31 downto 0) := x"00000000"; 
	-- command word to set up DAC, internal reference is used
	signal setup_dac : std_logic_vector (31 downto 0) := x"08000001";
	-- flag indicating initialization of the DAC 
	signal dac_init : std_logic := '0';

	-- local clock signals
	signal clkdiv : integer range 0 to 49 := 0; -- clock divider for 12.5 MHz DAC clock
	signal rsclk : std_logic := '0';            -- 12.5 MHz DAC clock

begin
	
	-- this process takes care of DAC clock generation
	clock_dac: process (clk100mhz) 
	begin
		if(rising_edge(clk100mhz)) then 
			if (clkdiv=3)then
				clkdiv <= 0;
				rsclk <= not(rsclk);
			else
				clkdiv <= clkdiv+1;
			end if;
		end if;
	end process clock_dac;
	
	
	dac_main: process (rsclk)
	
	begin
		if rising_edge(rsclk) then
			case state is		
				when idle_dac =>
					CS <= '1';
					MOSI <= '0';
					count <= 0;
					wrt_done <= '0';
					-- if DAC hasn't been initialized, do it first (it's done once only)
					if (dac_init = '0') then
						CS <= '1';
						state <= init_dac;
					else -- if initialization has been done, start writing it
						CS <= '1';
						state <= func_dac;
					end if;
				
				-- in this state initialization word is being written to DAC
				when init_dac =>
					if (count <= 31) then
						CS <= '0'; -- CS is set LOW when DAC is being written
						wrt_done <= '0';
						MOSI <= setup_dac(31-count);
						count <= count+1;
						state <= init_dac;
					elsif (count = 32) then
						CS <= '1';
						wrt_done <= '0';
						count <= 0;
						dac_init <= '1'; -- set the flag indicating that initialization is done
						MOSI <= '0';
						state <= func_dac;
					end if;
				
				when func_dac =>
					wrt_done <= '0';
					CS <= '1';
					MOSI <= '0';
					data <= x"030" & din_dac & x"00";					
					state <= wrt_dac;
				
				-- write DAC's command word to DAC
				when wrt_dac =>
					if (count <= 31) then
						CS <= '0';
						wrt_done <= '0';
						MOSI <= data(31-count);
						count <= count+1;
						state <= wrt_dac;
					elsif (count = 32) then
						CS <= '1';
						wrt_done <= '1'; -- set the flag indicating that write is done
						count <= 0;
						MOSI <= '0';
						state <= sDone;
					end if;	
				
				when sDone =>
						wrt_done <= '0'; -- clear write flag
						state    <= idle_dac;			
			end case;
		end if;
	end process dac_main;
	
SCLK <= rsclk; -- drive DAC with the locally generated 12.5 MHz clock signal 
	
end Behavioral;

