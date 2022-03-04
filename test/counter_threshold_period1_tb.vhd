-- counter_threshold_period1_tb - It tests counter_threshold with a period = 1.
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


entity counter_threshold_period1_tb is
  generic (runner_cfg : string);
end entity;


architecture tb of counter_threshold_period1_tb is
  constant clk_period : integer := 20; -- in ns
  constant period : integer := 1; -- in cycles
  constant N : natural := natural(ceil(log2(real(period+1))));

  signal clk : std_logic := '0';
  signal rst : std_logic;
  signal en : std_logic;
  signal threshold : unsigned(N-1 downto 0);
  signal is_below: std_logic;
begin
  clk <= not clk after (clk_period/2) * 1 ns;

  testing : entity serial_monitor.counter_threshold
    generic map (
      period => period)
    port map (
      clk => clk,
      rst => rst,
      en => en,
      threshold => threshold,
      is_below => is_below);

  main : process
    procedure checker(
      constant given_en : std_logic_vector;
      constant given_threshold : std_logic_vector;
      constant expected_is_below : std_logic_vector) is
    begin
      check_equal(given_en'length, given_threshold'length, "both in should have the same length");
      check_equal(given_en'length, expected_is_below'length, "in and out should have the same length");

      en <= '0'; -- init at '0'
      threshold <= to_unsigned(0, N);
      rst <= '1';
      wait until rising_edge(clk);
      rst <= '0';

      for i in 0 to given_en'length-1 loop
        en <= given_en(i);
        if given_threshold(i) = '0' then
          threshold <= to_unsigned(0, N);
        else
          threshold <= to_unsigned(1, N);
        end if;

        wait until falling_edge(clk); -- let the combinatory parts propagate, if any

        check_equal(is_below, expected_is_below(i), "Fail at cycle " & integer'image(i) & ".");

        wait until rising_edge(clk);
      end loop;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop

      if run("out is threshold") then
        checker(given_en =>          b"111111100000000",
                given_threshold =>   b"111011011101100",
                expected_is_below => b"111011011101100");

      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;

