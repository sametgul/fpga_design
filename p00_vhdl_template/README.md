# VHDL TEMPLATE & SYNTAX NOTES

These are some VHDL constructs that I frequently use and sometimes forget. I keep them here as a reference. 

**Style preferences**:

* Constants and generics in **UPPERCASE**.
* Ports use `_in` and `_out` postfixes.
* I like to add the width as a suffix (e.g. `_in16`).
* Using exponantiation terms `2**N-1` is good to have.

```vhdl
--------------------------------------------------------------------------------
-- LIBRARY and PACKAGE DECLARATIONS
--------------------------------------------------------------------------------
-- Standard packages
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
entity my_entity_name is
    generic (
        CLKFREQ  : integer := 100_000_000;
        SCLKFREQ : integer := 1_000_000;
        WIDTH    : integer := 8;
        N        : integer := 8;
        DEBUG    : boolean := false
    );
    port (
        input1_inW     : in  std_logic_vector (WIDTH-1 downto 0);
        input2_in      : in  std_logic;
        output1_out32  : out std_logic_vector(31 downto 0)
    );
end my_entity_name;


--------------------------------------------------------------------------------
-- ARCHITECTURE
--------------------------------------------------------------------------------
architecture Behavioral of my_entity_name is

    --------------------------------------------------------------------------------
    -- CONSTANTS
    --------------------------------------------------------------------------------
    constant CONSTANT1      : integer := 30;
    constant TIMERLIM_1MS   : integer := CLKFREQ / 1000;
    constant CONSTANT2      : std_logic_vector (WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------------------
    -- TYPE DECLARATION
    --------------------------------------------------------------------------------
    type t_state is (S_START, S_OPERATION, S_TERMINATE, S_IDLE);

    --------------------------------------------------------------------------------
    -- SIGNALS
    --------------------------------------------------------------------------------
    signal state : t_state := S_START;
    signal s0    : std_logic_vector (N-1 downto 0);            -- uninitialized
    signal s1    : std_logic_vector (7 downto 0) := x"00";     -- initialized
    signal s2    : integer range 0 to 2**N-1 := 0;             -- N-bit HW, N=8 so the range is 0 to 255
    signal s3    : integer := 0;                               -- default 32-bit
    signal s4    : std_logic := '0';

--------------------------------------------------------------------------------
-- BEGIN
--------------------------------------------------------------------------------    
begin

    --------------------------------------------------------------------------------
    -- ENTITY INSTANTIATION
    --------------------------------------------------------------------------------
    inst1 : entity work.my_component
        generic map(
            gen1 => SCLKFREQ,
            gen2 => '0'
        )
        port map(
            in1_i  => input2_in,
            out1_o => output1_out32
        );

    --------------------------------------------------------------------------------
    -- CONCURRENT ASSIGNMENTS
    --------------------------------------------------------------------------------
    s1 <=  x"01" when s0 < 30 else
           x"02" when s0 < 40 else
           x"03";
            
    with state select
        s0 <= x"01" when S_START,
              x"02" when S_OPERATION,
              x"03" when S_TERMINATE,
              x"04" when others;
            
    s3 <= 5 + 2;
    s4 <= input1_in(1) and input1_in(2) xor input2_in;
    -- Multiple drivers on s4 would cause an error!

    --------------------------------------------------------------------------------
    -- COMBINATIONAL PROCESS
    --------------------------------------------------------------------------------
    P_COMBINATIONAL : process (s0, state, input1_in, input2_in) begin

        -- if / elsif / else
        if (s0 < 30) then
            s1 <= x"01";
        elsif (s0 < 40) then
            s1 <= x"02";
        else
            s1 <= x"03";
        end if;

        -- case statement
        case state is
            when S_START      => s0 <= x"01";
            when S_OPERATION  => s0 <= x"02";
            when S_TERMINATE  => s0 <= x"03";
            when others       => s0 <= x"04";
        end case;

        -- Last assignment wins (not multiple driven net)
        s4 <= input1_in(1) and input1_in(2) xor input2_in;
        s4 <= input1_in(1) or input1_in(2) xnor input2_in;

    end process P_COMBINATIONAL;

    --------------------------------------------------------------------------------
    -- SEQUENTIAL PROCESS
    --------------------------------------------------------------------------------
    P_SEQUENTIAL : process (clk) begin
        if rising_edge(clk) then
            -- sequential logic here
        end if;
    end process P_SEQUENTIAL;

end Behavioral;
```

For writing testbenches in VHDL, I generally add the following first

```vhdl

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_pmodda4 is
end tb_pmodda4;

architecture Behavioral of tb_pmodda4 is

    constant CLK_PERIOD : time      := 10 ns;
    signal   clk        : std_logic := '0';

begin

    pSTIMULI: process begin
        -- ...
        
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


end Behavioral;

```

## References

* [Mehmet Burak Aykenar - Github Repo](https://github.com/mbaykenar)
