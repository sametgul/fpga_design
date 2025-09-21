# VHDL Notes: Behaviors, Pitfalls, and Useful Tricks

This document collects some important behaviors and reminders that are easy to forget when writing VHDL.

---

## Process Block Behavior

* Statements **inside a process** execute sequentially, in order.
* **Different processes** run concurrently (in parallel).
* Signal assignments inside a process take effect only **after the process suspends**.

  * You can assign multiple times to the same signal, but only the **last assignment** is visible.
* VHDL is **case-insensitive**.

```vhdl
process (clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      state <= S_IDLE;
      cntr1 <= 0;
      cntr2 <= (others => '0');
    else
      -- ...
    end if;
  end if;
end process;
```

Tip: use `'length` attributes to avoid memorizing signal widths:

```vhdl
cntr1_out <= std_logic_vector(to_unsigned(cntr1, cntr1_out'length));
```

---

## Common Combinational Pitfalls

When writing a **combinational process**, watch out for:

1. **Sensitivity list**

   * All signals that are read must appear in the sensitivity list.
   * Otherwise: simulation mismatches.

2. **Missing branches**

   * Every `if` should have an `else`, every `case` should have a `when others`.
   * Otherwise: unintended **latch inference**.

3. **Read + write of same signal**

   * Writing and reading the same signal in a combinational process may cause **feedback loops**.

### Example 1: Unintended Latch

```vhdl
PROCESS3 : process (sel, b, c)
begin
  if (sel = '0') then
    a <= b + c;
  end if;
end process PROCESS3;
```

Here, if `sel = '1'`, signal `a` keeps its previous value. Because this is not sequential logic, the synthesizer infers a **latch**. Vivado synthesizes it but gives a warning.

### Example 2: Combinational Feedback

```vhdl
PROCESS4 : process (sel, a, b, c)
begin
  if (sel = '0') then
    a <= a + b + c;
  else
    a <= a - b - c;
  end if;
end process PROCESS4;
```

Here, `a` is both read and written inside the same process. This creates a **combinational feedback loop**. Vivado synthesizes it without warnings, but it may cause oscillation or unstable behavior.

---

## Hierarchy Optimization in Vivado

Vivado has options like **rebuilt** and **none** for how it handles module hierarchy during synthesis:

* `rebuilt`: optimizer flattens and merges logic, removing unnecessary hierarchy. Your design may appear as one flat block.
* `none`: keeps submodules and hierarchy intact.

![merge](assets/merge_structures.png)

---

## Reset Strategy

* Xilinx recommends **synchronous, active-high reset**. This aligns with FPGA internal logic (active-high reset and clock-enable).
* Still, asynchronous reset is sometimes necessary.
* One trick is to use a generic like `rst_type : string := "ASYNC"` to switch between sync/async reset implementations.

### Example

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
  generic (
    rst_type : string := "ASYNC"
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    a   : in std_logic;
    b   : in std_logic;
    c   : in std_logic;
    y   : out std_logic
  );
end top;

architecture Behavioral of top is
  -- Signal initialized to '1'. In SRAM-based FPGAs, FFs power up initialized.
  -- In ASICs or flash-based FPGAs, explicit reset is required.
  signal y_int : std_logic := '1';
begin

  -- Synchronous Reset
  G_SYNC : if rst_type = "SYNC" generate
    process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          y_int <= '1';
        else
          y_int <= (a and b and (not c)) or
                   ((not a) and b and c) or
                   ((not a) and (not b) and (not c));
        end if;
      end if;
    end process;
  end generate;

  -- Asynchronous Reset
  G_ASYNC : if rst_type = "ASYNC" generate
    process (clk, rst)
    begin
      if (rst = '1') then
        y_int <= '1';
      elsif rising_edge(clk) then
        y_int <= (a and b and (not c)) or
                 ((not a) and b and c) or
                 ((not a) and (not b) and (not c));
      end if;
    end process;
  end generate;

  y <= y_int;
end Behavioral;
```

---

## Timing Considerations

* For **asynchronous inputs** or **crossing clock domains**:

  * Use 2- or 3-stage synchronizers.
* For **control signals**:

  * Use handshake or toggle synchronizers.
* For **data transfers**:

  * Use dual-clock FIFOs or Gray-coded counters in dual-port RAMs.

---

## Timing Closure Trick

When struggling with timing violations:

* Insert 2–4 flip-flops at the inputs of your design.
* Enable **retiming** in synthesis (`Settings → Synthesis → Retiming`).
* The synthesizer may move/redistribute these registers across logic to create a pipelined structure, improving timing.

*(original document had an image here: “replace\_registers.png”)*
