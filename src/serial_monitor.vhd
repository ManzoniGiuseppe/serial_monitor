-- serial_monitor - For each data line, it monitors it and tells if something is being sent.
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

entity serial_monitor is
  generic (
    N : integer; -- how many lines

    -- see serial_is_transmitting
    sit_permanence_duration : positive;

    -- see pwm
    pwm_precision : positive;
    pwm_period_parts : positive;
    pwm_time_change_duty_cycle : natural);
  port (
    clk : in std_logic;  -- clock
    rst : in std_logic;  -- sync reset. needs to be held to '1' for 2 cycles.

    use_pwm : in std_logic; -- if to use the pwm or a direct on-off

    transmission_line : in std_logic_vector(0 to N-1);
    is_transmitting : out std_logic_vector(0 to N-1));
end entity;

architecture a of serial_monitor is
  signal raw_is_transmitting : std_logic_vector(0 to N-1);

  constant duty_cycle_width : positive := positive(ceil(log2(real(pwm_period_parts+1))));
                                     -- minimum number of bit to fit the value of 'duty_cycle'
  type dc_vector is array (0 to N-1) of unsigned(duty_cycle_width-1 downto 0);
  signal duty_cycle : dc_vector;

  signal pwm_output : std_logic_vector(0 to N-1);
begin
  instances: for i in 0 to N-1 generate
    sit : entity work.serial_is_transmitting
      generic map (permanence_duration => sit_permanence_duration)
      port map (
        clk => clk,
        rst => rst,
        transmission_line => transmission_line(i),
        is_transmitting => raw_is_transmitting(i));

    duty_cycle(i) <= to_unsigned(pwm_period_parts, duty_cycle_width) when raw_is_transmitting(i) = '1'
                else to_unsigned(0, duty_cycle_width);

    p : entity work.pwm
      generic map (
        precision => pwm_precision,
        period_parts => pwm_period_parts, 
        time_change_duty_cycle => pwm_time_change_duty_cycle)
      port map (
        clk => clk,
        rst => rst,
        duty_cycle => duty_cycle(i),
        output => pwm_output(i));

    is_transmitting(i) <= pwm_output(i) when use_pwm = '1' else raw_is_transmitting(i);
  end generate;  
end architecture;
