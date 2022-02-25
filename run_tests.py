#!/usr/bin/env python3

# run_tests - It checks compilation errors and it runs the tests for this library.
# Written in 2022 by Manzoni Giuseppe
#
# To the extent possible under law, the author(s) have dedicated all copyright and related and
# neighboring rights to this software to the public domain worldwide.
# This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.


from vunit import VUnit

vu = VUnit.from_argv()

vu.add_library("serial_monitor").add_source_files("src/*.vhd")
vu.add_library("serial_monitor_test").add_source_files("test/*.vhd")

vu.main()
