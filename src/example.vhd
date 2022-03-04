-- example - How to use the serial_monitor.
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

entity example is
  port (
    clk : in std_logic;  -- clock
    rst : in std_logic;  -- async reset.

    use_pwm : in std_logic; -- if to use the pwm or a direct on-off

    rx0 : in std_logic;
    rx1 : in std_logic;
    rx2 : in std_logic;
    rx3 : in std_logic;

    tx0 : in std_logic;
    tx1 : in std_logic;
    tx2 : in std_logic;
    tx3 : in std_logic;

    rx0_led : out std_logic;
    rx1_led : out std_logic;
    rx2_led : out std_logic;
    rx3_led : out std_logic;

    tx0_led : out std_logic;
    tx1_led : out std_logic;
    tx2_led : out std_logic;
    tx3_led : out std_logic);
end entity;

architecture a of example is
  -- CONFIG                            --   ,  ,  ,  ,
  constant clk_period : real           := 0.000000020;  -- in seconds. =50MHz clock
  constant pwm_period : real           := 0.001;      -- in seconds. the led blinks once per period. = 1KHz
  constant pwm_time_to_on_off : real   := 0.1;       -- in seconds. how long the fading takes.
  constant sit_pemanence_period : real := 0.1;     -- in seconds. how long the transmission is showed to
                                                   -- continue after the last change in the line.
  constant pwm_period_parts : integer  := 16;     -- it's in how many parts the period of the pwm is split.


  -- compute the parameters from the config.
  constant pwm_precision_period : real := pwm_period / real(pwm_period_parts); -- in seconds.
  constant pwm_precision : integer := integer(pwm_precision_period / clk_period); -- in clk
  constant sit_permanence_duration : integer := integer (sit_pemanence_period / clk_period);
  constant pwm_time_to_change_one_part : real := pwm_time_to_on_off / real(pwm_period_parts); -- in seconds
  constant pwm_time_change_duty_cycle : integer := integer(pwm_time_to_change_one_part / clk_period); -- in clk

  -- other
  constant N : positive := 8;
  signal actual_transmission_line : std_logic_vector(0 to N-1);
  signal actual_is_transmitting : std_logic_vector(0 to N-1);
begin
  actual_transmission_line <= (0 => rx0, 1 => rx1, 2 => rx2, 3 => rx3,
                               4 => tx0, 5 => tx1, 6 => tx2, 7 => tx3);

  rx0_led <= actual_is_transmitting(0);
  rx1_led <= actual_is_transmitting(1);
  rx2_led <= actual_is_transmitting(2);
  rx3_led <= actual_is_transmitting(3);

  tx0_led <= actual_is_transmitting(4);
  tx1_led <= actual_is_transmitting(5);
  tx2_led <= actual_is_transmitting(6);
  tx3_led <= actual_is_transmitting(7);

  main: entity work.serial_monitor
    generic map (
      N => N,
      pwm_precision => pwm_precision,
      pwm_period_parts => pwm_period_parts,
      pwm_time_change_duty_cycle => pwm_time_change_duty_cycle,
      sit_permanence_duration => sit_permanence_duration)
    port map (
      clk => clk,
      rst => rst,
      use_pwm => use_pwm,
      transmission_line => actual_transmission_line,
      is_transmitting => actual_is_transmitting);
end architecture;
