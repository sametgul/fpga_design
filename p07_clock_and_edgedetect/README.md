# Edge Detection & D Flip-Flop Notes

I had confused myself with these basic mechanism, so I experimented a few things.

## 1. D Flip-Flop Basics

* **Code pattern:**

```vhdl
entity dff is
  port(
    clk : in  std_logic;
    rst : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic
  );
end entity;

architecture rtl of dff is
  signal r_q : std_logic := '0';
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        r_q <= '0';
      else
        r_q <= d;
      end if;
    end if;
  end process;

  q <= r_q;
end rtl;
  ```
* Synthesizes to a **single D flip-flop**.
* On every rising edge of `clk`, the input `d` is sampled and stored in `q`.
* `q` only changes **after** the clock edge, never in between.

**Mental model:**

```
d ──► [D FF] ──► q
         ▲
        clk
```


## 2. Edge Detection with `sig` + `sig_prev`

* **Code pattern:**

```vhdl
entity edge_detect is
  port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    sig    : in  std_logic;
    rising : out std_logic;
    falling: out std_logic
  );
end entity;

architecture rtl of edge_detect is
  signal sig_prev : std_logic := '0';
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        sig_prev <= '0';
        rising   <= '0';
        falling  <= '0';
      else
        -- default
        rising  <= '0';
        falling <= '0';

        -- edge check
        if sig='1' and sig_prev='0' then
          rising <= '1';
        elsif sig='0' and sig_prev='1' then
          falling <= '1';
        end if;

        -- register current value
        sig_prev <= sig;
      end if;
    end if;
  end process;
end rtl;
  ```
* This creates a pulse (`rising=1`) **only when** `sig` transitions from 0 → 1.
* Internally it’s like **two flip-flops plus combinational logic**:

```
sig ──►[FF]── sig_prev ───┐
        ▲                 │
       clk                ├─► AND ─►[FF]─► rising
sig ──────────────────────┘        ▲
                                   clk
```

---

## 3. Why `sig` and `rising` Look Misaligned in Simulation

* In the simulator waveform:

  * At the **moment of rising edge**, the condition (`sig=1`, `sig_prev=0`) is true → `rising=1`.
  * **After the process ends**, `sig_prev` is updated to 1.
* So the waveform often shows: `sig=1`, `sig_prev=1`, and `rising=1` at the same time.

This is not an error — it’s just how **signal update scheduling** works in VHDL.
The decision was made using the *old* value, the update reflects the *new* value.

---

## 4. Pulse Width Considerations

* If `sig` itself is a **1-clock-wide pulse**, then `rising` is redundant. The pulse *is already an event*.
* If `sig` is **longer than 1 clock** (button press, data_ready flag, etc.), then `rising` is essential to convert a level into an event.

**Rule of thumb:**

* Use `sig` directly if it is already 1-cycle.
* Use `rising` (edge detector) if `sig` can stay high for multiple cycles.

---

## 5. Mental Anchors

* **`rising_edge(clk)` = 1 flip-flop.**
* **`sig + sig_prev` = 2 flip-flops + comb logic** (edge detector circuit).
* `sig` = **level information** (“is it high now?”).
* `rising` = **event information** (“did it just go high this cycle?”).

---

## 6. Quick Testbench Patterns

### DFF

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_dff is
end entity;

architecture sim of tb_dff is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal d   : std_logic := '0';
  signal q   : std_logic;
begin
  -- clock üretimi: 100 MHz (10 ns periyod)
  clk <= not clk after 5 ns;

  -- DUT (device under test)
  uut: entity work.dff
    port map(
      clk => clk,
      rst => rst,
      d   => d,
      q   => q
    );

  -- Stimulus
  process
  begin
    -- Başlangıçta reset
    wait for 12 ns;
    rst <= '0';  -- reset release

    -- D girişini değiştir
    wait for 8 ns;  d <= '1';  -- clock kenarında sample edilmeli
    wait for 20 ns; d <= '0';
    wait for 20 ns; d <= '1';
    wait for 10 ns; d <= '0';

    wait for 30 ns;
    assert false report "Simulation finished" severity failure;
  end process;
end sim;

```

![dff](docs/dff.png)

### Edge Detector

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_edge_detect is
end entity;

architecture sim of tb_edge_detect is
  signal clk     : std_logic := '0';
  signal rst     : std_logic := '1';
  signal sig     : std_logic := '0';
  signal rising  : std_logic;
  signal falling : std_logic;
begin
  -- clock üret
  clk <= not clk after 5 ns; -- 100 MHz

  -- DUT
  uut: entity work.edge_detect
    port map(
      clk     => clk,
      rst     => rst,
      sig     => sig,
      rising  => rising,
      falling => falling
    );

  -- stimulus
  process
  begin
    -- reset
    rst <= '1';
    wait for 20 ns;
    rst <= '0';

    -- sig'e pulse uygula
    wait for 30 ns;
    sig <= '1';  -- rising bekle
    wait for 20 ns;
    sig <= '0';  -- falling bekle
    wait for 40 ns;
    sig <= '1';  -- rising tekrar
    wait for 10 ns;
    sig <= '0';  -- falling tekrar

    wait for 50 ns;
    assert false report "Test finished" severity failure;
  end process;
end sim;    
```

![ed](docs/edge_detect.png)
---

## 7. Key Takeaway

* **Level vs Event:** Don’t confuse a signal being high (`sig=1`) with the moment it *became* high (`rising=1`).
* Think in terms of **register + next-state logic**:

  * `sig_prev` = stored past (like `state_reg`)
  * `sig` = current input
  * `rising` = event pulse derived from comparing the two.

---
