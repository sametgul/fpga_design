library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_pwm is
  generic(
    CLK_FREQ : integer := 100_000_000;
    PWM_FREQ : integer := 1000
  );
end tb_pwm;

architecture Behavioral of tb_pwm is
  constant CLK_PERIOD  : time := 10 ns;                               -- 100 MHz
  constant TIM_LIM     : integer := CLK_FREQ / PWM_FREQ;              -- ticks / period
  constant PWM_PERIOD  : time := TIM_LIM * CLK_PERIOD;                -- 1 ms @ 1 kHz

  signal clk        : std_logic := '0';
  signal duty_cycle : std_logic_vector(6 downto 0) := (others => '0'); -- 0..100
  signal pwm_out    : std_logic;
begin
  -- CLOCK Generation
  pCLK_GEN: process
  begin
    clk <= '0'; wait for CLK_PERIOD/2;
    clk <= '1'; wait for CLK_PERIOD/2;
  end process;

  -- DUT
  DUT : entity work.pwm_out
    generic map(
      CLK_FREQ => CLK_FREQ,
      PWM_FREQ => PWM_FREQ
    )
    port map(
      clk        => clk,
      duty_cycle => duty_cycle,
      pwm_out    => pwm_out
    );

  -- Minimal stimulus: 0% ? 100% with 10% steps
  pSTIMULI: process
  begin
    wait for 5*CLK_PERIOD;  

    for k in 0 to 10 loop
      duty_cycle <= std_logic_vector(to_unsigned(k*10, 7));
      wait for PWM_PERIOD;  -- One period with new duty cycle
    end loop;
    
      wait for 5*PWM_PERIOD; 


    assert false report "SIM DONE" severity failure;
  end process;
end Behavioral;
