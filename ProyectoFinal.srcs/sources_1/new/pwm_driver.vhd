library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_driver is  
port (
    clk100m : in std_logic;
    level  : in integer;
    pwm_out : out std_logic
);
end pwm_driver;

architecture Behavioral of pwm_driver is

subtype u20 is unsigned(19 downto 0);
signal counter      : u20 := x"00000";

constant clk_freq   : integer := 100_000_000;       -- Clock frequency in Hz (10 ns)
constant pwm_freq   : integer := 50;                -- PWM signal frequency in Hz (20 ms)
constant period     : integer := clk_freq/pwm_freq; -- Clock cycle count per PWM period
signal duty_cycle : integer := 50_000;            -- Clock cycle count per PWM duty cycle, goes from 50k to 250k

signal pwm_counter  : std_logic := '0';
signal stateHigh    : std_logic := '1';

signal clk50m       : std_logic;

signal num : std_logic_vector(63 downto 0) := (others => '1');
begin

pwm_generator : process(clk100m) is
variable cur : u20 := counter;
variable level_int: integer := 0;
begin
    if ((clk100m = '1' and clk100m'event) ) then
        level_int := level;
        
        if(level_int > 255) then
            level_int := 255;
        elsif(level_int < 0) then
            level_int := 0;
        end if;
        
        level_int := (level_int * 100 / 255);
        duty_cycle <= level_int * 2000 + 50_000; -- Change duty cycle depending on level_int, from 50k to 250k
        
        cur := cur + 1;  
        counter <= cur;
        if (cur <= duty_cycle) then
            pwm_counter <= '1'; 
        elsif (cur > duty_cycle) then
            pwm_counter <= '0';
        elsif (cur = period) then
            cur := x"00000";
        end if;  
    end if;
end process pwm_generator;
pwm_out <= pwm_counter;
end Behavioral;