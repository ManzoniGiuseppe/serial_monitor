-- pwm - A Pulse Width Modulator.
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

entity pwm is
  generic (
    precision : positive; -- if 'duty_cycle' is changed by 1, the pulse-width of the output is
                          -- changed by 'precision' cycles
    period_parts : positive; -- in how many parts the period is split.
                             -- period duration = 'period_parts'*'precision'
    time_change_duty_cycle : natural; -- how many cycles to internally change the duty cycle of 1.
                                      -- 0 for disable and use the external one.

    duty_cycle_width : positive := positive(ceil(log2(real(period_parts+1)))));
                                    -- minimum number of bit to fit the value of 'period_parts'
  port (
    clk : in std_logic;  -- clock
    rst : in std_logic;  -- sync reset

    duty_cycle : in unsigned(duty_cycle_width-1 downto 0);  -- in internal clock cycles.

    output: out std_logic); -- the pulse-width modulated signal.
                            -- it's 1 for the first 'duty_cycle'*'precision' cycles.
                            -- resets every 'period_parts'*'precision' cycles.
end entity;

architecture rtl of pwm is
  signal do_change_duty_cycle : std_logic;
  signal do_update_output : std_logic;

  signal dc : unsigned(duty_cycle_width-1 downto 0);  -- internal duty cycle
begin
  dc_follower: if time_change_duty_cycle /= 0 generate
    dc_c : entity work.counter_threshold
      generic map (period => time_change_duty_cycle)
      port map (
        clk => clk,
        rst => rst,
        is_below => do_change_duty_cycle);

    process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          dc <= duty_cycle;
        elsif do_change_duty_cycle = '1' then
          if duty_cycle < dc then
            dc <= dc - 1;
          elsif duty_cycle > dc then
            dc <= dc + 1;
          end if;
        end if;
      end if;
    end process;
  else generate
    -- to behave like the main case
    process (clk)
    begin
      if rising_edge(clk) then
        dc <= duty_cycle;
      end if;
    end process;
  end generate;

  p_c : entity work.counter_threshold
    generic map (period => precision)
    port map (
      clk => clk,
      rst => rst,
      is_below => do_update_output);

  o_c : entity work.counter_threshold
    generic map (period => period_parts)
    port map (
      clk => clk,
      rst => rst,
      en => do_update_output,
      threshold => dc,
      is_below => output);
end architecture;
