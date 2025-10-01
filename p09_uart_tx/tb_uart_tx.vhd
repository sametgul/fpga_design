library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_uart_tx is
end tb_uart_tx;

architecture sim of tb_uart_tx is
  constant CLK_PERIOD : time := 10 ns; -- 100 MHz

  signal clk      : std_logic := '0';
  signal start_tx : std_logic := '0';
  signal data_in  : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_out   : std_logic;
  signal tx_done  : std_logic;

begin
  -- Clock generator
  clk_process : process begin
      clk <= '0'; wait for CLK_PERIOD/2;
      clk <= '1'; wait for CLK_PERIOD/2;
  end process;

  -- DUT
  DUT: entity work.uart_tx
    generic map(
      CLK_FREQ  => 100_000_000,
      BAUD_RATE => 115_200,
      STOP_BIT  => 2
    )
    port map(
      clk      => clk,
      start_tx => start_tx,
      data_in  => data_in,
      tx_out   => tx_out,
      tx_done  => tx_done
    );

  -- Stimulus
  stim_proc: process
  begin
    wait for 10*CLK_PERIOD;

    -- send 0xAB
    data_in  <= x"AB";
    start_tx <= '1';
    wait for CLK_PERIOD;
    start_tx <= '0';

    wait until tx_done = '1';  -- wait until stop bits
    wait until tx_done = '0';  -- back to idle
    wait for CLK_PERIOD;

    -- send 0xCD
    data_in  <= x"CD";
    start_tx <= '1';
    wait for CLK_PERIOD;
    start_tx <= '0';

    wait until tx_done = '1';
    wait until tx_done = '0';

    -- end sim
    wait for 10*CLK_PERIOD;
    
    assert false report "SIM DONE" severity failure;
  end process;

end sim;
