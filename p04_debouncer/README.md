# DEBOUNCER

A simple, parameterizable button debouncer built as a finite state machine (FSM) with a clocked timeout counter. It supports both active-low and active-high buttons via a generic.

I want deterministic behavior on edges: when the raw input toggles, we enter a transition state and wait a fixed time (debounce window). If the input stays stable until the timer expires, we commit to the new stable state; if it bounces back, we cancel.

## FSM Design

States:

* `sONE` and `sZERO` — **stable** states (idle and pressed, respectively)
* `sONEtoZERO` and `sZEROtoONE` — **transition** states (debounce window running)
* `sINIT` — boot/reset alignment

### Why `sINIT` is written this way?

On power-up/reset, the button **might already be pressed**. If we blindly start in a fixed stable state, we’d produce a wrong level for the first `DEBTIME_MS`.
So in `sINIT` we **sample the real input** (respecting `ACTIVE_LOW`) and jump to the correct stable state immediately (`sONE` if idle, `sZERO` if pressed). That removes the startup glitch.

### Transition logic (the core idea)

* From `sONE`, if input reads “pressed,” go to `sONEtoZERO`, **enable the timer**, and wait.

  * If input flips back before timeout → bounce → return to `sONE`.
  * If timer expires while still pressed → accept → go to `sZERO`.
* Symmetric behavior for `sZERO → sZEROtoONE → sONE`.

The timeout counter is sized as:

```
TIM_LIM = (CLK_FREQ / 1000) * DEBTIME_MS
```

Example: 12 MHz, 5 ms → `TIM_LIM = 60_000`.


## Generics

```vhdl
generic (
  CLK_FREQ   : integer := 12_000_000; -- Hz
  DEBTIME_MS : integer := 5;          -- ms
  ACTIVE_LOW : boolean := true        -- true for idle='1'/pressed='0'
);
```

* **Rule of thumb** for buttons: 5–20 ms is common; 10 ms is a safe default.
* If you’re using CMOD A7’s buttons, keep `ACTIVE_LOW = true`.

### Here is the whole code:


```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debouncer is
generic(
    CLK_FREQ   : integer := 12_000_000;    -- Hz
    DEBTIME_MS : integer := 5;             -- ms   
    ACTIVE_LOW : boolean := true           
);
port(
    clk     : in  std_logic;
    sig_in  : in  std_logic;
    sig_out : out std_logic
);
end debouncer;

architecture Behavioral of debouncer is

    type t_state is (sINIT, sONE, sONEtoZERO, sZERO, sZEROtoONE);
    signal state : t_state := sINIT;
    
    signal tim_en  : std_logic := '0';
    signal tim_tick: std_logic := '0';
    
    constant TIM_LIM : integer := CLK_FREQ/(1000)*DEBTIME_MS;
    signal   timer   : integer range 0 to TIM_LIM-1 := 0;
begin

    pMAIN: process(clk) begin
        if rising_edge(clk) then
            case state is 
                when sINIT =>
                    if ACTIVE_LOW = true then
                        -- ACTIVE_LOW: normal='1', pressed='0'
                        if sig_in = '1' then
                            state   <= sONE;
                            sig_out <= '1';
                        else
                            state   <= sZERO;
                            sig_out <= '0';
                        end if;
                    else
                        -- ACTIVE_HIGH: normal='0', pressed='1'
                        if sig_in = '0' then
                            state   <= sZERO;
                            sig_out <= '0';
                        else
                            state   <= sONE;
                            sig_out <= '1';
                        end if;
                    end if;
                    
                when sONE =>
                    sig_out <= '1';
                    
                    if(sig_in = '0') then
                        state  <= sONEtoZERO;
                        tim_en <= '1';
                    end if;
                    
                when sONEtoZERO =>
                    sig_out <= '1';
                    
                    if(sig_in = '1') then
                        state   <= sONE;
                        tim_en  <= '0';
                    elsif(tim_tick = '1') then
                        state   <= sZERO;
                        tim_en  <= '0';
                    end if;
                    
                
                when sZERO      =>
                    sig_out <= '0';
                    
                    if(sig_in = '1') then
                        state  <= sZEROtoONE;
                        tim_en <= '1';
                    end if;
                    
                when sZEROtoONE =>
                    sig_out <= '0';
                    
                    if(sig_in = '0') then
                        state   <= sZERO;
                        tim_en  <= '0';
                    elsif(tim_tick = '1') then
                        state   <= sONE;
                        tim_en  <= '0';
                    end if;
            end case;  
        end if;
    end process;
    
    pTIMER: process(clk) begin
        if rising_edge(clk) then
            if(tim_en = '1') then
                if(timer = TIM_LIM-1) then
                    timer    <= 0;
                    tim_tick <= '1';      
                else
                    timer    <= timer + 1;
                    tim_tick <= '0';
                end if;                
            else
                timer    <= 0;
                tim_tick <= '0';
            end if;
        end if;
    end process;

end Behavioral;
```

## Testbench

The TB drives a few “bounce-like” pulses around the debounce window to show the FSM accepting or rejecting transitions. Clock and debouncing are parameterized via generics just like the DUT.

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_debouncer is
generic(
    CLK_FREQ   : integer := 1000;    -- Hz
    DEBTIME_MS : integer := 5;             -- ms   
    ACTIVE_LOW : boolean := true                    
);
end tb_debouncer;

architecture Behavioral of tb_debouncer is

    constant CLK_PERIOD : time      := 1 ms;  
    signal   clk        : std_logic := '1';
    
    signal sig_in  : std_logic := '1';
    signal sig_out : std_logic;

begin

    pSTIMULI: process begin
        wait for 5 ms;   
        sig_in <= '0';
        
        wait for 3 ms;
        sig_in <= '1';
        
        wait for 2 ms;
        sig_in <= '0';
        
        wait for 5 ms;
        sig_in <= '0';
        
        wait for 2 ms;
        sig_in <= '1';
        wait for 6 ms;
        
        assert false
        report "SIM DONE"
        severity failure;
    end process;

    pCLK_GEN: process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    DUT: entity work.debouncer
    generic map(
        CLK_FREQ   => CLK_FREQ  ,
        DEBTIME_MS => DEBTIME_MS,
        ACTIVE_LOW => ACTIVE_LOW
    )
    port map(
        clk     => clk   ,
        sig_in  => sig_in, 
        sig_out => sig_out
    );

end Behavioral;
```
## Simulation

The waveform below shows:

* Start in `sONE` (idle), first press causes a jump to `sONEtoZERO`, timer runs.
* If the raw input bounces back before timeout, we cancel and return to `sONE`.
* When the input stays stable longer than `DEBTIME_MS`, we commit to `sZERO`.
* Symmetric behavior on release.

![simulation](docs/debouncer.png)

Tip: Put `state`, `tim_en`, `tim_tick`, `timer`, `sig_in`, and `sig_out` on your wave—those tell the whole story at a glance.

---

## Metastability (important, but out of scope)

This module assumes `sig_in` is already synchronized. In real hardware, **asynchronous** inputs (like buttons) should pass through a **2-FF synchronizer** before hitting the FSM to avoid rare metastability artifacts. If you want a production-ready block, add that in front of `debouncer` (or wrap it inside).