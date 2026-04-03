# run_all.pro

# Use VHDL-2008 (OSVVM generally expects 2008 support)
SetVHDLVersion 2008

# Put your DUT and TB into the work library
library work
analyze pwm_gen.vhd
analyze testCase_nominal.vhd

# Run the self-checking testbench
simulate testCase_nominal