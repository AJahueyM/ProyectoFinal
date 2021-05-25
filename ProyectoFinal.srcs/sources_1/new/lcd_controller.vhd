library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lcd_controller is
 Port (
    dispOut : out  std_logic_vector(7 downto 0);
    rs : out std_logic;
    rw : out std_logic;
    temp1, temp2, temp3, temp4: in integer;
    enable : out std_logic;
    clk : in std_logic
 );
end lcd_controller;

ARCHITECTURE Behavioral OF lcd_controller IS
  SIGNAL   lcd_enable : STD_LOGIC;
  SIGNAL   lcd_bus    : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   lcd_busy   : STD_LOGIC;
  
  SIGNAL p_temp : integer := 0;
  SIGNAL dc_temp :  std_logic_vector(7 downto 0);
  SIGNAL un_temp :  std_logic_vector(7 downto 0);

  COMPONENT lcd_driver IS
    PORT(
       clk        : IN  STD_LOGIC; --system clock
       reset_n    : IN  STD_LOGIC; --active low reinitializes lcd
       lcd_enable : IN  STD_LOGIC; --latches data into lcd controller
       lcd_bus    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0); --data and control signals
       busy       : OUT STD_LOGIC; --lcd controller busy/idle feedback
       rw, rs, e  : OUT STD_LOGIC; --read/write, setup/data, and enable for lcd
       lcd_data   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
  END COMPONENT;
  
  COMPONENT dec_lcd IS
  Port (
  num : in integer;
  dc_out : out std_logic_vector(7 downto 0);
  un_out : out std_logic_vector(7 downto 0));
  END COMPONENT;
  
BEGIN

  --instantiate the lcd controller
  dut: lcd_driver
    PORT MAP(clk => clk, reset_n => '1', lcd_enable => lcd_enable, lcd_bus => lcd_bus, 
             busy => lcd_busy, rw => rw, rs => rs, e => enable, lcd_data => dispOut);
  
  D1: dec_lcd PORT MAP(p_temp, dc_temp ,un_temp);
  
  PROCESS(clk)
    VARIABLE char  :  INTEGER RANGE 0 TO 16 := 0;
    variable count : integer := 0;
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN
      
      p_temp <= (temp1 + temp2 + temp3)/3;
--      p_temp <= temp4;
      IF(lcd_busy = '0' AND lcd_enable = '0') THEN
        lcd_enable <= '1';
        
        IF(char < 11) THEN
          char := char + 1;   
        ELSE
            count := count + 1;
            if(count > 100000000) then
                count := 0;
                char := 12;
            end if;
        END IF;      
        
        --p_temp <= temp2;
        
        CASE char IS
          WHEN 1 => lcd_bus <= "1001010100"; -- "T"
          WHEN 2 => lcd_bus <= "1001000101"; -- "E"
          WHEN 3 => lcd_bus <= "1001001101"; -- "M"
          WHEN 4 => lcd_bus <= "1001010000"; -- "P"
          WHEN 5 => lcd_bus <= "1000111010"; -- ":"
          WHEN 6 => lcd_bus <= "1000100000"; -- " "  
          WHEN 7 => lcd_bus <= "10" & dc_temp; -- "X"
          WHEN 8 => lcd_bus <= "10" & un_temp; -- "X" 
          WHEN 9 => lcd_bus <= "1000100000"; -- " "
          WHEN 10 => lcd_bus <= "1001000011"; -- "C" 
          WHEN 11 => lcd_enable <= '0';
          WHEN 12 => 
            lcd_bus <= "0010000000"; -- "Return Cursor to start"
            char := 0;
          WHEN others => lcd_enable <= '0';      
          END CASE;
      ELSE
        lcd_enable <= '0';
      END IF;
    END IF;
  END PROCESS;
  
END Behavioral;
