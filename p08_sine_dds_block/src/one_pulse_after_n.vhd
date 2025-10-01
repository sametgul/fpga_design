library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity one_pulse_after_n is
  generic(
    N         : integer := 10;  -- kaç clock beklesin
    PULSE_LEN : integer := 1    -- çıkış kaç clock high kalsın (1 veya 2)
  );
  port(
    clk   : in  std_logic; 
    rst   : in  std_logic;  -- senkron reset, aktif high
    pulse : out std_logic
  );
end entity;

architecture rtl of one_pulse_after_n is
  signal cnt  : integer range 0 to N+PULSE_LEN := 0;
  signal done : std_logic := '0';
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt  <= 0;
        done <= '0';
      else
        if done = '0' then
          cnt <= cnt + 1;
          if cnt = N+PULSE_LEN then
            done <= '1';         -- pulse üretildi, iş bitti
          end if;
        end if;
      end if;
    end if;
  end process;

  pulse <= '1' when (done='0') and (cnt > N) and (cnt <= N+PULSE_LEN) else '0';
end architecture;
