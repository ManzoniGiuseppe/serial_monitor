-- serial_monitor_tb - It tests the serial_monitor.
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

entity serial_monitor_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of serial_monitor_tb is
  constant clk_period : integer := 20; -- in ns

  constant precision : integer := 3; -- in cycles
  constant period_parts : integer := 4; -- in precision
  constant time_change_duty_cycle : integer := 2; -- in cycles
  constant permanence_duration : integer := 5; -- in cycles

  signal clk : std_logic := '0';
  signal rst : std_logic;
  signal use_pwm : std_logic;
  signal tx_line : std_logic;
  signal rx_line : std_logic;
  signal tx_is_tr : std_logic;
  signal rx_is_tr : std_logic;

  signal actual_transmission_line : std_logic_vector(0 to 1);
  signal actual_is_transmitting : std_logic_vector(0 to 1);
begin
  clk <= not clk after (clk_period/2) * 1 ns;

  testing : entity serial_monitor.serial_monitor
    generic map (
      N => 2, -- a pair of lines
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

  actual_transmission_line <= (0 => tx_line, 1 => rx_line);
  tx_is_tr <= actual_is_transmitting(0);
  rx_is_tr <= actual_is_transmitting(1);

  main : process
    procedure checker(
      constant given_pwm : std_logic_vector;
      constant given_rx : std_logic_vector;
      constant given_tx : std_logic_vector;
      constant expected_rx : std_logic_vector;
      constant expected_tx : std_logic_vector) is
    begin
      check_equal(given_rx'length, given_tx'length, "both in lines should have the same length");
      check_equal(given_pwm'length, given_rx'length, "all in should have the same length");
      check_equal(expected_rx'length, expected_tx'length, "both out should have the same length");
      check_equal(given_pwm'length, expected_rx'length, "in and out should have the same length");

      use_pwm <= '0';
      tx_line <= '0';
      rx_line <= '0';
      rst <= '1';
      wait until rising_edge(clk);
      rst <= '0';

      for i in 0 to given_pwm'length-1 loop
        use_pwm <= given_pwm(i);
        tx_line <= given_tx(i);
        rx_line <= given_rx(i);

        wait until falling_edge(clk); -- let the combinatory parts propagate, if any

        check_equal(tx_is_tr, expected_tx(i), "tx fails at cycle " & integer'image(i) & ".");
        check_equal(rx_is_tr, expected_rx(i), "rx fails at cycle " & integer'image(i) & ".");

        wait until rising_edge(clk);
      end loop;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop

--  precision = 3 cycles
--  period_parts = 4 precisions
--  time_change_duty_cycle = 2 cycles
--  permanence_duration = 5 cycles

      if run("no pwm") then
        checker(given_pwm   => b"00000000000000000000000000",
                given_tx    => b"11110000000000011111111111",
                expected_tx => b"01111111110000001111100000",
                given_rx    => b"00000001111111111100000000",
                expected_rx => b"00000000111110000001111100");

      elsif run("alternating and pulse") then
        checker(given_pwm   => b"11111111111111111111111111",
                given_tx    => b"10101010101010101010101010",
                   -- raw_it     01111111111111111111111111
                   -- dc         04444444444444444444444444
            -- change dc count   01010101010101010101010101
                   -- slow dc    00011223344444444444444444
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_tx => b"00000000011111111111111111",
                given_rx    => b"10000000000000000000000000",
                   -- raw_it     01111110000000000000000000
                   -- dc         04444440000000000000000000
                   -- slow dc    00011223322110000000000000
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_rx => b"00000000001110000000000000");

      elsif run("complex") then
        checker(given_pwm   => b"1111111111101111110111101111",
                given_tx    => b"1110000000000000000000000000",
                   -- raw_it     0111111110000000000000000000
                   -- dc         0444444440000000000000000000
                   -- slow dc    0001122334433221100000000000
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_tx => b"0000000001101110000000000000",
                given_rx    => b"1111100000000000111111111111",
                   -- raw_it     0111111111100000011111000000
                   -- dc         0444444444400000044444000000
                   -- slow dc    0001122334444332211223322110
                   -- period               ,           ,
                   -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_rx => b"0000000001101111001000101000");

      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
