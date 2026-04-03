library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library osvvm;
--use osvvm.AlertLogPkg.all; -- used for logging and assertions
context osvvm.OsvvmContext;

entity testCase_nominal is
end entity;

architecture sim of testCase_nominal is

    --------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------
    constant C_CLK_HZ     : integer := 50_000_000;
    constant C_BITWIDTH   : integer := 32;
    constant CLK_PERIOD   : time    := 20 ns;
    constant TOLERANCE    : time    := 2 * CLK_PERIOD;

    --------------------------------------------------------------------
    -- DUT signals
    --------------------------------------------------------------------
    signal pl_clk   : std_logic := '0';
    signal rst_n    : std_logic := '1';
    signal en       : std_logic := '0';
    signal pulse_us : std_logic_vector(C_BITWIDTH-1 downto 0) := (others => '0');
    signal pwm_sig  : std_logic;

    --------------------------------------------------------------------
    -- Procedures
    --------------------------------------------------------------------
    procedure set_pulse_us (
        signal pulse_us : out std_logic_vector;
        constant us_int : in integer
    ) is
    begin
        pulse_us <= std_logic_vector(to_unsigned(us_int, C_BITWIDTH));
    end procedure;

begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    dut : entity work.pwm_gen
        generic map (
            C_CLK_HZ      => C_CLK_HZ,
            C_BITWIDTH    => C_BITWIDTH,
            C_PULSE_MODE  => false,
            C_RST_PW_US   => 1500
        )
        port map (
            pl_clk   => pl_clk,
            rst_n    => rst_n,
            en       => en,
            pulse_us => pulse_us,
            pwm_sig  => pwm_sig
        );

    --------------------------------------------------------------------
    -- Clock
    --------------------------------------------------------------------
    clk_gen : process
    begin
        while true loop
            pl_clk <= '0';
            wait for CLK_PERIOD / 2;
            pl_clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    stim_proc : process
    begin
        SetLogEnable(INFO, TRUE);
        SetLogEnable(PASSED, TRUE);
        SetLogEnable(DEBUG, TRUE);

        Log("Starting tb_pwm_gen", INFO);

        ----------------------------------------------------------------
        -- Initial state
        ----------------------------------------------------------------
        en <= '0';
        rst_n <= '1';
        set_pulse_us(pulse_us, 0);

        wait for 10 * CLK_PERIOD;

        ----------------------------------------------------------------
        -- Test 0: Disabled
        ----------------------------------------------------------------
        Log( "Test 0: Disabled output low", INFO);
        set_pulse_us(pulse_us, 100);

        -- make sure output signal stays low when disabled and pulse us != 0
        wait until pwm_sig = '1' for 1 ms;
        wait for 0 ns;
        if pwm_sig = '0' then
            AffirmIf(TRUE, "TEST 0 PASSED, Signal stayed low during disable period");
        else
            AffirmIf(FALSE, "TEST 0 FAILED, Signal went high during disable period");
        end if;

        ----------------------------------------------------------------
        -- Test 1: Pulse Width 0
        ----------------------------------------------------------------
        Log( "Test 1: Pulse width set to 0", INFO);
        en <= '1';
        set_pulse_us(pulse_us, 0);

        -- make sure output signal stays low when pulse width = 0
        wait until pwm_sig = '1' for 1 ms;
        wait for 0 ns;
        if pwm_sig = '0' then
            AffirmIf(TRUE, "TEST 1 PASSED, Signal stayed low when pulse_us = 0");
        else
            AffirmIf(FALSE, "TEST 1 FAILED, Signal went high when pulse_us = 0");
        end if;

        ----------------------------------------------------------------
        -- Test 2: Pulse Width 1000
        ----------------------------------------------------------------
        Log( "Test 2: Pulse width set to 1000", INFO);
        en <= '1';
        set_pulse_us(pulse_us, 1000);

        -- make sure output signal goes high at some point after fully enabled
        wait until pwm_sig = '1' for 5 ms;
        wait for 0 ns;
        if pwm_sig = '1' then
            AffirmIf(TRUE, "TEST 2 PASSED, Signal went high when pulse_us = 1000");
        else
            AffirmIf(FALSE, "TEST 2 FAILED, Signal stayed low when pulse_us = 1000");
        end if;


        ----------------------------------------------------------------
        -- Done
        ----------------------------------------------------------------
        Log( "All tests completed", INFO);

        EndOfTestReports;
        stop;
        wait;
    end process;

end architecture;