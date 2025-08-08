LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY debounce IS
    PORT( clk : IN std_logic;
          noisy_sig : IN std_logic;
          clean_sig : OUT std_logic);
END debounce;

ARCHITECTURE behavioural OF debounce is
    SIGNAL input_prev : std_logic;
    SIGNAL synch_count : std_logic_vector(20 DOWNTO 0);
BEGIN
    synchronize: PROCESS
    BEGIN
        WAIT UNTIL clk'event AND clk = '1';
        input_prev <= noisy_sig;
        IF noisy_sig /= input_prev THEN
            synch_count <= (others => '0');
        ELSIF synch_count /= x"100000" THEN
            synch_count <= synch_count + 1;
        END IF;
        IF synch_count = x"100000" THEN
            clean_sig <= noisy_sig;
        END IF;
    END PROCESS;
END behavioural;