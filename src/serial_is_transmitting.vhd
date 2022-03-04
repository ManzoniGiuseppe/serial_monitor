-- serial_is_transmitting - It says if a transmission line is being used.
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
use ieee.math_real.all;        -- log2

entity serial_is_transmitting is
  generic (
    permanence_duration : positive); -- in cycles. how long the transmission is assumed to continue
                                     -- with no change to the 'transmission_line' signal
  port (
    clk : in std_logic;  -- clock
    rst : in std_logic;  -- async reset

    transmission_line : in std_logic; -- the rx/tx to check if it's transmitting

    is_transmitting: out std_logic); -- output. if 'transmission_line' has changed in the last
                                     -- 'permanence_duration' cycles.
end entity;


architecture rtl of serial_is_transmitting is
  constant permanence_width : positive := positive(ceil(log2(real(permanence_duration+1))));
                                          -- minimum number of bits to fit 'permanence_duration'

  signal permanence : unsigned(permanence_width-1 downto 0);
  signal last_transmission_line : std_logic;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      last_transmission_line <= transmission_line;
    end if;
  end process;

  process (clk, rst)
  begin
    if rising_edge(clk) then
      if transmission_line /= last_transmission_line then
        permanence <= to_unsigned(permanence_duration, permanence_width);
      elsif permanence /= 0 then
        permanence <= permanence - 1;
      end if;
    end if;
    if rst = '1' then
      permanence <= (others => '0');
    end if;
  end process;

  is_transmitting <= '0' when permanence = 0 else '1';
end architecture;
