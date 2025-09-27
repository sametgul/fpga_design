# PWM OUTPUT

A small, synthesizable VHDL PWM block that drives a single output with a percentage-based duty input. The module is parameterized by the input clock frequency and the target PWM frequency. It uses **double-buffering** to update the duty cycle **glitch-free** at the start of each PWM period.

## Why `TIM_LIM` is calculated

`TIM_LIM` is the number of clock ticks in one PWM period:

```
TIM_LIM = CLK_FREQ / PWM_FREQ
```

With `CLK_FREQ = 100 MHz` and `PWM_FREQ = 1 kHz`, we get `TIM_LIM = 100_000`.
The free-running counter `timer` counts from `0` to `TIM_LIM-1`, and this fully defines the PWM timebase. If `CLK_FREQ` is not an exact multiple of `PWM_FREQ`, the integer division truncates; the actual PWM frequency will be close to the target (stable and deterministic).

## Duty clamping and rounding (why and how)

* **Clamping to 0..100**: The input `duty_cycle` is a 7-bit vector. Any value above 100 would otherwise overflow the “high time” calculation. We therefore clamp to `[0,100]`. This guarantees safe arithmetic and a well-defined behavior for out-of-range writes.

* **Rounded high-time**: Converting a percentage to ticks is done as:

  ```
  high_time = round(TIM_LIM * duty / 100)
            = (TIM_LIM * duty + 50) / 100
  ```

  Integer math without rounding systematically biases low (truncation). The `+50` term adds a half-LSB before dividing by 100, producing a proper **round-to-nearest** result. This improves linearity of perceived brightness and ensures 100% duty truly covers the entire period. Note that `high_time` is allowed to take the value `TIM_LIM` for the 100% case.

## Double-buffered `high_time` (glitch-free updates)

The design computes a combinational `high_time_calc` every cycle but **latches** it into `high_time` **only when the counter wraps** (`timer = TIM_LIM-1`). That means new duty values take effect **at the next PWM period**, not immediately. The benefit is you never get mid-period “needle” glitches when the duty is updated.

Sequence:

1. `duty_cycle` → convert & clamp → `duty_clamped`
2. Compute `high_time_calc = round(TIM_LIM * duty_clamped / 100)`
3. When `timer` rolls over, copy `high_time_calc` to `high_time`
4. Generate PWM: `pwm_out = '1'` when `timer < high_time`, else `'0'`

This yields a one-period latency for duty updates and a perfectly clean PWM waveform.

## Code (RTL)

```vhdl
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

```

## Testbench

This is a minimal testbench that:

* Defines the clock period (`CLK_PERIOD = 10 ns` → `100 MHz`).
* Recomputes `TIM_LIM = CLK_FREQ / PWM_FREQ` to derive `PWM_PERIOD = TIM_LIM * CLK_PERIOD` (e.g., `1 ms` at `1 kHz`).
* Steps the duty from 0% to 100% in 10% increments and waits **one PWM period** after each update so the new duty is latched at the next period boundary (consistent with the double-buffering).

```vhdl
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

  -- Minimal stimulus: 0% → 100% with 10% steps
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

```
### Expected waveform

The PWM high pulse widens in clean 10% steps at period boundaries, with no mid-period glitches, matching the double-buffered behavior:

![testbench](docs/testbench.png)

## Notes

* **Latency:** Duty updates take effect one PWM period later by design (glitch-free).
* **Synthesis:** The multiply-by-constant and division by 100 are optimized by modern tools (e.g., mapped to DSP or shift-add logic). Resource cost is minimal for typical FPGAs.
* **Extension:** To drive an RGB LED, instantiate three copies with independent duties. For smoother low-level brightness, add a 256-entry gamma LUT on the duty path before rounding.
