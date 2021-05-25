library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dec_lcd is
  Port (
  num : in integer;
  dc_out : out std_logic_vector(7 downto 0);
  un_out : out std_logic_vector(7 downto 0));
end dec_lcd;

architecture Behavioral of dec_lcd is
signal dc_aux, un_aux : integer :=0;

begin

process(num)
begin
    dc_aux <= num / 10;
    un_aux <= num mod 10;
end process;

process(dc_aux)
begin
        CASE dc_aux IS
          WHEN 0 => dc_out <= "00110000"; -- 0
          WHEN 1 => dc_out <= "00110001"; -- 1
          WHEN 2 => dc_out <= "00110010"; -- 2
          WHEN 3 => dc_out <= "00110011"; -- 3
          WHEN 4 => dc_out <= "00110100"; -- 4
          WHEN 5 => dc_out <= "00110101"; -- 5
          WHEN 6 => dc_out <= "00110110"; -- 6
          WHEN 7 => dc_out <= "00110111"; -- 7
          WHEN 8 => dc_out <= "00111000"; -- 8
          WHEN 9 => dc_out <= "00111001"; -- 9
          WHEN OTHERS => dc_out <= "00000000";
        END CASE;
end process;

process(un_aux)
begin
        CASE un_aux IS
          WHEN 0 => un_out <= "00110000"; -- 0
          WHEN 1 => un_out <= "00110001"; -- 1
          WHEN 2 => un_out <= "00110010"; -- 2
          WHEN 3 => un_out <= "00110011"; -- 3
          WHEN 4 => un_out <= "00110100"; -- 4
          WHEN 5 => un_out <= "00110101"; -- 5
          WHEN 6 => un_out <= "00110110"; -- 6
          WHEN 7 => un_out <= "00110111"; -- 7
          WHEN 8 => un_out <= "00111000"; -- 8
          WHEN 9 => un_out <= "00111001"; -- 9
          WHEN OTHERS => un_out <= "00000000";
        END CASE;
end process;

end Behavioral;
