library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_out is
  generic(
    CLK_FREQ : integer := 100_000_000;
    PWM_FREQ : integer := 1000
  );
  port(
    clk        : in  std_logic;
    duty_cycle : in  std_logic_vector(6 downto 0);   -- 0..100 expected
    pwm_out    : out std_logic
  );
end pwm_out;

architecture rtl of pwm_out is
  constant TIM_LIM : integer := CLK_FREQ / PWM_FREQ;

  signal timer        : integer range 0 to TIM_LIM-1 := 0;
  signal duty_conv    : integer range 0 to 127 := 0;
  signal duty_clamped : integer range 0 to 100 := 0;

  -- HIGH TIME in a period (0..TIM_LIM, %100 included)
  signal high_time    : integer range 0 to TIM_LIM := 0;

  -- Rounded high time calculation for the next period
  signal high_time_calc : integer range 0 to TIM_LIM := 0;
begin
  -- Input conversion and clamping
  duty_conv    <= to_integer(unsigned(duty_cycle));
  duty_clamped <= 100 when duty_conv > 100 else duty_conv;

  -- high = round(TIM_LIM * duty / 100)
  high_time_calc <= (TIM_LIM * duty_clamped + 50) / 100;

  process(clk)
  begin
    if rising_edge(clk) then
      if timer = TIM_LIM-1 then
        timer     <= 0;
        -- Lock the hight at the beginning of the new period
        high_time <= high_time_calc;
      else
        timer <= timer + 1;
      end if;

      -- PWM output
      if timer < high_time then
        pwm_out <= '1';
      else
        pwm_out <= '0';
      end if;
    end if;
  end process;
end architecture;
