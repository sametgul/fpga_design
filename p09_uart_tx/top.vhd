library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
generic(
    CLK_FREQ  : integer := 12_000_000;
    BAUD_RATE : integer := 115_200;
    STOP_BIT  : integer := 1
);
port(
    sysclk          : in std_logic;
    led             : out std_logic;
    uart_rxd_out    : out std_logic
);
end top;

architecture Behavioral of top is
    signal timer : integer range 0 to CLK_FREQ-1 := 0;
    signal st    : std_logic := '0';
    signal cnt   : unsigned(7 downto 0) := (others => '0');
begin
    process(sysclk) begin
    if rising_edge(sysclk) then
        if(timer = CLK_FREQ-1) then
            st <= '1';
            timer <= 0;
            cnt <= cnt + 1;
        else
            timer <= timer + 1;
            st <= '0';
        end if;
    end if;
    end process;

      -- DUT
    inst_uart: entity work.uart_tx
    generic map(
      CLK_FREQ  => CLK_FREQ,
      BAUD_RATE => BAUD_RATE,
      STOP_BIT  => STOP_BIT
    )
    port map(
      clk      => sysclk,
      start_tx => st,
      data_in  => std_logic_vector(cnt),
      tx_out   => uart_rxd_out,
      tx_done  => led
    );


end Behavioral;
