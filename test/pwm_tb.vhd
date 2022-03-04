-- pwm_tb - It tests the pwm.
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


entity pwm_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of pwm_tb is
  constant clk_period : integer := 20; -- in ns

  constant precision : integer := 2; -- in cycles
  constant period_parts : integer := 2; -- in precision
  constant N : natural := natural(ceil(log2(real(period_parts+1))));
  constant time_change_duty_cycle : integer := 3; -- in cycles

  signal clk : std_logic := '0';
  signal rst : std_logic;
  signal duty_cycle : unsigned(N-1 downto 0);
  signal output: std_logic;
begin
  clk <= not clk after (clk_period/2) * 1 ns;

  testing : entity serial_monitor.pwm
    generic map (
      precision => precision,
      period_parts => period_parts,
      time_change_duty_cycle => time_change_duty_cycle)
    port map (
      clk => clk,
      rst => rst,
      duty_cycle => duty_cycle,
      output => output);

  main : process
    type integer_vector is array (integer range <>) of integer;

    procedure checker(
      constant given_dc : integer_vector;
      constant expected_output : std_logic_vector) is
    begin
      check_equal(given_dc'length, expected_output'length, "in and out should have the same length");

      duty_cycle <= to_unsigned(0, N);
      rst <= '1';
      wait until rising_edge(clk);
      rst <= '0';

      for i in 0 to given_dc'length-1 loop
        duty_cycle <= to_unsigned(given_dc(i), N);

        wait until falling_edge(clk); -- let the combinatory parts propagate, if any

        check_equal(output, expected_output(i), "Fail at cycle " & integer'image(i) & ".");

        wait until rising_edge(clk);
      end loop;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop

-- precision = 2 cycles
-- period_parts = 2 precisions
-- time_change_duty_cycle = 3 cycles

      if run("varying dc") then
        checker(given_dc   => (0 to 2 => 1, 3 to 5 => 0, 6 to 11 => 2, 12 to 18 => 0),
                 -- given dc         1110002222220000000
                 -- change dc count  0120120120120120120
                 -- slow dc          0111000111222111000
                expected_output => b"0001000110111001000");
                -- period counter    0110011001100110011
                -- prec counter      0101010101010101010

      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
