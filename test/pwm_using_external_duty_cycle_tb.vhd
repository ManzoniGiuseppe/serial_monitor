-- pwm_using_external_duty_cycle_tb - It tests the pwm without slowing the changes in the duty cycle.
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


entity pwm_using_external_duty_cycle_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of pwm_using_external_duty_cycle_tb is
  constant clk_period : integer := 20; -- in ns

  constant precision : integer := 3; -- in cycles
  constant period_parts : integer := 4; -- in precision
  constant N : natural := natural(ceil(log2(real(period_parts+1))));

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
      time_change_duty_cycle => 0) -- use directly the extarnally provided 'duty_cycle'
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

  -- precision = 3 cycles
  -- period_parts = 4 precisions

      if run("fixed dc to 1") then
        checker(given_dc   =>  (0 to 25 => 1),
                           --  dc    11111111111111111111111111
                    -- period                  ,           ,
                  -- precision        ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_output => b"10000000001110000000001110");
                   -- period count   01112223330001112223330001
                 -- precision count  01201201201201201201201201

      elsif run("all varying dc") then
        checker(given_dc   =>    (0 => 0, 1 to 6 => 2, 7 to 15 => 1, 16 to 22 => 3, 23 to 25 => 0),
                       -- position   01234567890123456789012345
                           --  dc    02222221111111113333333000
                        -- period              ,           ,
                       -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_output => b"01110000001110001110001000");

      elsif run("fixed dc to period") then
        checker(given_dc   =>    (0 to 25 => 4),
                           --  dc    11111111111111111111111111
                        -- period              ,           ,
                       -- precision   ,  ,  ,  ,  ,  ,  ,  ,  ,
                expected_output => b"11111111111111111111111111");

      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
