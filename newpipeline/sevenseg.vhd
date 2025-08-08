library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sevenseg is
    Port (
        clk : in STD_LOGIC;
        digit0 : in STD_LOGIC_VECTOR(3 downto 0);
        digit1 : in STD_LOGIC_VECTOR(3 downto 0);
        digit2 : in STD_LOGIC_VECTOR(3 downto 0);
        digit3 : in STD_LOGIC_VECTOR(3 downto 0);
        an : out STD_LOGIC_VECTOR(3 downto 0);
        seg : out STD_LOGIC_VECTOR(6 downto 0)
    );
end sevenseg;

architecture Behavioral of sevenseg is
    signal refresh_counter : unsigned(15 downto 0) := (others => '0');
    signal current_digit : unsigned(1 downto 0) := (others => '0');
    signal value : STD_LOGIC_VECTOR(3 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
            current_digit <= refresh_counter(15 downto 14);
        end if;
    end process;

    process(current_digit, digit0, digit1, digit2, digit3)
    begin
        case current_digit is
            when "00" =>
                value <= digit0;
                an <= "1110";
            when "01" =>
                value <= digit1;
                an <= "1101";
            when "10" =>
                value <= digit2;
                an <= "1011";
            when others =>
                value <= digit3;
                an <= "0111";
        end case;
    end process;

    process(value)
    begin
        case value is
            when "0000" => seg <= "1000000";
            when "0001" => seg <= "1111001";
            when "0010" => seg <= "0100100";
            when "0011" => seg <= "0110000";
            when "0100" => seg <= "0011001";
            when "0101" => seg <= "0010010";
            when "0110" => seg <= "0000010";
            when "0111" => seg <= "1111000";
            when "1000" => seg <= "0000000";
            when "1001" => seg <= "0010000";
            when "1010" => seg <= "0001000";
            when "1011" => seg <= "0000011";
            when "1100" => seg <= "1000110";
            when "1101" => seg <= "0100001";
            when "1110" => seg <= "0000110";
            when others => seg <= "0001110";
        end case;
    end process;
end Behavioral;
