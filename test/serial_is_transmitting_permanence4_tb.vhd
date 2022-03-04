-- serial_is_transmitting_permanence4_tb - It tests the serial_is_transmitting with permanence=4.
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

library vunit_lib;
context vunit_lib.vunit_context;

library serial_monitor;


entity serial_is_transmitting_permanence4_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of serial_is_transmitting_permanence4_tb is
  constant clk_period : integer := 200; -- in ns
  constant permanence_period : integer := 800; -- in ns    (4 cycles)

  constant permanence_duration : integer := permanence_period / clk_period;  -- in cycles

  signal clk : std_logic := '0';
  signal rst : std_logic;
  signal transmission_line : std_logic;
  signal is_transmitting : std_logic;
begin
  clk <= not clk after (clk_period/2) * 1 ns;

  testing : entity serial_monitor.serial_is_transmitting
    generic map (
      permanence_duration => permanence_duration)
    port map (
      clk => clk,
      rst => rst,
      transmission_line => transmission_line,
      is_transmitting => is_transmitting);

  main : process
    procedure checker(
      constant given_input : std_logic_vector;
      constant expected_output : std_logic_vector) is
    begin
      check_equal(given_input'length, expected_output'length, "in and out should have the same length");

      transmission_line <= '0'; -- init at '0'
      rst <= '1';
      wait until rising_edge(clk);
      rst <= '0';

      for i in 0 to given_input'length-1 loop
        transmission_line <= given_input(i);

        wait until falling_edge(clk); -- let the combinatory parts propagate, if any

        check_equal(is_transmitting, expected_output(i), "Fail at cycle " & integer'image(i) & ".");

        wait until rising_edge(clk);
      end loop;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop

      if run("constant to init") then
        checker(given_input =>     b"0000000",
                expected_output => b"0000000");

      elsif run("constant to not init") then
        checker(given_input =>     b"1111111",
                expected_output => b"0111100");

      elsif run("pulse of not init") then
        checker(given_input =>     b"10000000",
                expected_output => b"01111100");

      elsif run("alternating") then
        checker(given_input =>     b"1010111111",
                expected_output => b"0111111110");


      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;

