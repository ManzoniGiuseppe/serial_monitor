-- counter_threshold - A counter that outputs if its internal value is below a threshold.
-- Written in 2022 by Manzoni Giuseppe
--
-- To the extent possible under law, the author(s) have dedicated all copyright and related and
-- neighboring rights to this software to the public domain worldwide.
-- This software is distributed without any warranty.
-- You should have received a copy of the CC0 Public Domain Dedication along with this software.
-- If not, see <http://creativecommons.org/publicdomain/zero/1.0/>. 

library ieee;
use ieee.std_logic_1164.all;   -- standard unresolved logic UX01ZWLH-
use ieee.numeric_std.all;      -- for the signed, unsigned types and arithmetic ops
use ieee.math_real.all;        -- log2, ceil


entity counter_threshold is
  generic (
    period : positive; -- in clock cycles
    N : positive := natural(ceil(log2(real(period+1))))); -- min bit size for 'threshold'
  port (
    clk : in std_logic;  -- clock
    rst : in std_logic;  -- async reset

    en : in std_logic := '1'; -- enable. when true it ticks.
    threshold : in unsigned(N-1 downto 0) := (0 => '1', others => '0'); -- default 1.
           -- in case it's left as default the 'is_below' behaves like a is_zero

    is_below: out std_logic);  -- if the counter is below the threshold.
end entity;

architecture rtl of counter_threshold is
  signal count: unsigned(N-1 downto 0);   -- from 0 to 'period'-1 and again.
begin
  process (clk, rst)
  begin
    if rising_edge(clk) and en = '1' then
      if count = to_unsigned(period-1, N) then
        count <= to_unsigned(0, N);
      else
        count <= count + 1;
      end if;
    end if;
    if rst = '1' then
      count <= to_unsigned(0, N);
    end if;
  end process;

  is_below <= '1' when count < threshold else '0';
end architecture;
