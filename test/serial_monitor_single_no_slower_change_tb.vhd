-- serial_monitor_single_no_slower_change_tb - It tests a specific case of the serial_monitor.
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

library vunit_lib;
context vunit_lib.vunit_context;

library serial_monitor;

entity serial_monitor_single_no_slower_change_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of serial_monitor_single_no_slower_change_tb is
  constant clk_period : integer := 20; -- in ns

  constant precision : integer := 3; -- in cycles
  constant period_parts : integer := 4; -- in precision
  constant time_change_duty_cycle : integer := 0; -- none / disabled
  constant permanence_duration : integer := 5; -- in cycles

  signal clk : std_logic := '0';
  signal rst : std_logic;
  signal use_pwm : std_logic;
  signal transmission_line : std_logic;
  signal is_transmitting: std_logic;

  signal actual_transmission_line : std_logic_vector(0 to 0);
  signal actual_is_transmitting : std_logic_vector(0 to 0);
begin
  clk <= not clk after (clk_period/2) * 1 ns;

  testing : entity serial_monitor.serial_monitor
    generic map (
      N => 1, -- use only 1
      pwm_precision => precision,
      pwm_period_parts => period_parts,
      pwm_time_change_duty_cycle => time_change_duty_cycle,
      sit_permanence_duration => permanence_duration)
    port map (
      clk => clk,
      rst => rst,
      use_pwm => use_pwm,
      transmission_line => actual_transmission_line,
      is_transmitting => actual_is_transmitting);

  actual_transmission_line <= (others => transmission_line);
  is_transmitting <= actual_is_transmitting(0);

  main : process
    procedure checker(
      constant given_pwm : std_logic_vector;
      constant given_tl : std_logic_vector;
      constant expected_it : std_logic_vector) is
    begin
      check_equal(given_pwm'length, given_tl'length, "both in should have the same length");
      check_equal(given_pwm'length, expected_it'length, "in and out should have the same length");

      use_pwm <= '0';
      transmission_line <= '0';
      rst <= '1';
      wait until rising_edge(clk); -- sync, and needs to propagate internal signal.
      wait until rising_edge(clk);
      rst <= '0';

      for i in 0 to given_pwm'length-1 loop
        use_pwm <= given_pwm(i);
        transmission_line <= given_tl(i);

        wait until falling_edge(clk); -- let the combinatory parts propagate, if any

        check_equal(is_transmitting, expected_it(i), "Fail at cycle " & integer'image(i) & ".");

        wait until rising_edge(clk);
      end loop;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop

--  precision = 3 cycles
--  period_parts = 4 precisions
--  time_change_duty_cycle = none / disabled
--  permanence_duration = 5 cycles

      if run("no signal") then
        checker(given_pwm   => b"11111111111111111111111111",
                given_tl    => b"00000000000000000000000000",
                   -- raw_it     00000000000000000000000000
                   -- dc         00000000000000000000000000
                   -- slow dc    00000000000000000000000000
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_it => b"00000000000000000000000000");

      elsif run("alternating") then
        checker(given_pwm   => b"11111111111111111111111111",
                given_tl    => b"10101010101010101010101010",
                   -- raw_it     01111111111111111111111111
                   -- dc         04444444444444444444444444
                   -- slow dc    00444444444444444444444444
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_it => b"00111111111111111111111111");



      elsif run("pulse") then
        checker(given_pwm   => b"11111111111111111111111111",
                given_tl    => b"10000000000000000000000000",
                   -- raw_it     01111110000000000000000000
                   -- dc         04444440000000000000000000
                   -- slow dc    00444444000000000000000000
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_it => b"00111111000000000000000000");

      elsif run("only initial change") then
        checker(given_pwm   => b"11111111111111111111111111",
                given_tl    => b"11111111111111111111111111",
                   -- raw_it     01111100000000000000000000
                   -- dc         04444400000000000000000000
                   -- slow dc    00444440000000000000000000
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_it => b"00111110000000000000000000");

      elsif run("complex") then
        checker(given_pwm   => b"11111111110111110111111111",
                given_tl    => b"11110000000000011111111111",
                   -- raw_it     01111111110000001111100000
                   -- dc         04444444440000004444400000
                   -- slow dc    00444444444000000444440000
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_it => b"00111111110000001111110000");

      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
