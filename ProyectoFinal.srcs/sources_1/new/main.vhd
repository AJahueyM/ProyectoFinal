----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/13/2021 02:43:09 PM
-- Design Name: 
-- Module Name: main - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;    
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
 Port (   
    CLK100MHZ : IN STD_LOGIC;
    vauxp2 : IN STD_LOGIC;
    vauxn2 : IN STD_LOGIC;
    vauxp3 : IN STD_LOGIC;
    vauxn3 : IN STD_LOGIC;
    vauxp10 : IN STD_LOGIC;
    vauxn10 : IN STD_LOGIC;
    vauxp11 : IN STD_LOGIC;
    vauxn11 : IN STD_LOGIC;
    vp_in : IN STD_LOGIC;
    vn_in : IN STD_LOGIC;
    dispOut : out  std_logic_vector(7 downto 0);
    rs : out std_logic;
    rw : out std_logic;
    dispEnable : out std_logic;
    servo_pwm_out : out std_logic;
    led_r_pwm_out : out std_logic;
    led_g_pwm_out : out std_logic
   );
end main;

architecture Behavioral of main is

COMPONENT xadc_wiz_0
  PORT (
    di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    den_in : IN STD_LOGIC;
    dwe_in : IN STD_LOGIC;
    drdy_out : OUT STD_LOGIC;
    do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dclk_in : IN STD_LOGIC;
    reset_in : IN STD_LOGIC;
    vp_in : IN STD_LOGIC;
    vn_in : IN STD_LOGIC;
    vauxp2 : IN STD_LOGIC;
    vauxn2 : IN STD_LOGIC;
    vauxp3 : IN STD_LOGIC;
    vauxn3 : IN STD_LOGIC;
    vauxp10 : IN STD_LOGIC;
    vauxn10 : IN STD_LOGIC;
    vauxp11 : IN STD_LOGIC;
    vauxn11 : IN STD_LOGIC;
    channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    eoc_out : OUT STD_LOGIC;
    alarm_out : OUT STD_LOGIC;
    eos_out : OUT STD_LOGIC;
    busy_out : OUT STD_LOGIC
  );
END COMPONENT;

component lcd_controller is
 Port (
    dispOut : out  std_logic_vector(7 downto 0);
    rs : out std_logic;
    rw : out std_logic;
    temp1, temp2, temp3, temp4: in integer;
    enable : out std_logic;
    clk : in std_logic
 );
end component;


component pwm_driver is
port (
    clk100m : in std_logic;
    level  : in integer;
    pwm_out : out std_logic
);
end component;

signal analog_data : STD_LOGIC_VECTOR(15 downto 0);
signal enable : STD_LOGIC := '0';
signal ready : STD_LOGIC;
type adc_channel is (first, second, third, fourth);
signal current_channel : adc_channel := first;
signal drp_address_in : STD_LOGIC_VECTOR(6 downto 0) := "0010010"; -- 8'h12, registro inicial
signal first_value, second_value, third_value, fourth_value : integer;
signal temperature : integer := 0;
constant pwm_base : integer := 128; -- Base value for PWM signal
signal pwm_level : integer := 0; -- Change from the base pwm
signal green_level : integer := 0; -- Change from the base pwm
signal red_level : integer := 0; -- Change from the base pwm

constant temp_setpoint : integer := 21; -- Target temperature
begin

adc : xadc_wiz_0
  PORT MAP (
    di_in => "0000000000000000",
    daddr_in => drp_address_in,
    den_in => enable,
    dwe_in => '0',
    drdy_out => ready,
    do_out => analog_data,
    dclk_in => CLK100MHZ,
    reset_in => '0',
    vp_in => vp_in,
    vn_in => vn_in,
    vauxp2 => vauxp2,
    vauxn2 => vauxn2,
    vauxp3 => vauxp3,
    vauxn3 => vauxn3,
    vauxp10 => vauxp10,
    vauxn10 => vauxn10,
    vauxp11 => vauxp11,
    vauxn11 => vauxn11,
    channel_out => open,
    eoc_out => enable,
    alarm_out => open,
    eos_out => open,
    busy_out => open
  );
  
lcd_control : lcd_controller
    PORT MAP (
        dispOut => dispOut,
        rs => rs,
        rw => rw,
        temp1 => first_value,
        temp2 => second_value,
        temp3 => third_value,
        temp4 => fourth_value,
        enable => dispEnable,
        clk => CLK100MHZ
    );

pwm_servo : pwm_driver
    PORT MAP (
        clk100m => CLK100MHZ,
        level => pwm_level,
        pwm_out =>  servo_pwm_out
    );

pwm_red : pwm_driver
    PORT MAP (
        clk100m => CLK100MHZ,
        level => red_level,
        pwm_out =>  led_r_pwm_out
    );

pwm_green : pwm_driver
    PORT MAP (
        clk100m => CLK100MHZ,
        level => green_level,
        pwm_out =>  led_g_pwm_out
    );
    
process(CLK100MHZ)
variable channel_timer : integer := 0;
variable decimal : unsigned(32 downto 0);   
variable decimal_mult : unsigned(65 downto 0);
variable temp_error : integer := 0;
begin
    if(CLK100MHZ = '1' and CLK100MHZ'event) then   
        temp_error := (first_value + second_value + third_value) / 3 - temp_setpoint;
        pwm_level <= pwm_base + temp_error * 2; -- Proportional control
        
        red_level <= temp_error * 1000 / 78 ;--Mientras más grande sea el error, más rojo (Si error es 10, maximo rojo)
        if(temp_error > 6) then
            green_level <= 0;
        else
            green_level <= 255 - temp_error * 1000 / 78; -- Mientras más pequeño sea el error, más verde
        end if;

        channel_timer := channel_timer + 1;
        
        -- Transformar información del ADC a decimal (Obtenido de https://github.com/Digilent/Nexys-4-DDR-XADC/blob/master/src/hdl/XADCdemo.v ), luego transformar a Celcius
        -- Si leemos 1 volt, esto representa que el sensor está dandonos 5 volts, multiplicamos por 5. Pasamos a millivolts multiplicando por 1000
        -- El LM35 nos da 10 mV por cada Centigrado, dividir el resultado entre 10. Termina siendo una operación de multiplicar por 500.
        decimal := "00000000000000000" & shift_right(unsigned(analog_data), 4); 
        decimal_mult := decimal * 250000;
        
        decimal_mult := shift_right(decimal_mult, 10);
        temperature <= TO_INTEGER(decimal_mult * 500) / 1000000; -- Pasar a enteros, si no esta gigante el numero
      
        
        if(channel_timer > 10000000 / 2) then
            case current_channel is
                when first =>
                    first_value <= temperature;
                when second => 
                    second_value <= temperature;
                when third =>
                    third_value <= temperature;
                when fourth =>
                    fourth_value <= first_value; -- Este LM35 murió por la patria, por el momento leer lo mismo que el primero.
            end case;  
        end if;
        
        if(channel_timer > 10000000) then
            channel_timer := 0;
            if(drp_address_in = "0010010") then
                current_channel <= second;
                drp_address_in <= "0010011"; -- 8'h13
            elsif (drp_address_in = "0010011") then
                current_channel <= third;
                drp_address_in <= "0011010"; -- 8'h1a        
            elsif (drp_address_in = "0010011") then
                current_channel <= fourth;
                drp_address_in <= "0011011"; -- 8'h1b
            elsif (drp_address_in <= "0011011") then
                current_channel <= first;
                drp_address_in <= "0010010"; -- 8'h12
            end if;
        end if;      
    end if;  
end process;

end Behavioral;
