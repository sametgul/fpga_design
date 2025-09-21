library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spbram is
generic (
WIDTH       : integer := 8;
DEPTH       : integer := 14;
read_type   : string := "READ_FIRST";
LAT         : string := "2_CLK"
);
port (
clk     : in std_logic;
we_i    : in std_logic;
addr_i  : in std_logic_vector (DEPTH-1 downto 0);
din_i   : in std_logic_vector (WIDTH-1 downto 0);
dout_o  : out std_logic_vector (WIDTH-1 downto 0)
);
end spbram;

architecture Behavioral of spbram is

type t_ram is array (0 to 2**DEPTH-1) of std_logic_vector (WIDTH-1 downto 0);
signal ram : t_ram := (others => (others => '0'));
signal ram_int : std_logic_vector (WIDTH-1 downto 0) := (others => '0');

begin

G_READ_FIRST : if read_type = "READ_FIRST" generate

G_LAT_1 : if LAT = "1_CLK" generate
process (clk)
begin
if rising_edge(clk) then
    if (we_i = '1') then 
        ram(to_integer(unsigned(addr_i))) <= din_i;
    end if;
    dout_o <= ram(to_integer(unsigned(addr_i)));    
end if;
end process;      
end generate G_LAT_1;

G_LAT_2 : if LAT = "2_CLK" generate
process (clk)
begin
if rising_edge(clk) then
    if (we_i = '1') then 
        ram(to_integer(unsigned(addr_i))) <= din_i;
    end if;
    ram_int <= ram(to_integer(unsigned(addr_i)));
    dout_o <= ram_int;
end if;
end process;   
end generate G_LAT_2;    

end generate G_READ_FIRST;

G_WRITE_FIRST : if read_type = "WRITE_FIRST" generate

G_LAT_1 : if LAT = "1_CLK" generate
process (clk)
begin
if rising_edge(clk) then
    dout_o <= ram(to_integer(unsigned(addr_i)));    
    if (we_i = '1') then 
        ram(to_integer(unsigned(addr_i))) <= din_i;
        dout_o <= din_i;
    end if;
end if;
end process;     
end generate G_LAT_1;

G_LAT_2 : if LAT = "2_CLK" generate
process (clk)
begin
if rising_edge(clk) then
    ram_int <= ram(to_integer(unsigned(addr_i)));    
    dout_o  <= ram_int;
    if (we_i = '1') then 
        ram(to_integer(unsigned(addr_i))) <= din_i;
        ram_int <= din_i;
        dout_o <= ram_int;
    end if;
end if;
end process;     
end generate G_LAT_2;
    
end generate G_WRITE_FIRST;

end Behavioral;

## References

* [VHDL ile FPGA PROGRAMLAMA](https://www.udemy.com/course/vhdl-ile-fpga-programlama-temel-seviye/)