library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cooling_fsm_top is
    Port (
        clk : in STD_LOGIC;
        key1 : in STD_LOGIC;
        key2 : in STD_LOGIC;
        led1 : out STD_LOGIC; -- onboard D6 (A_C_ON)
        led2 : out STD_LOGIC; -- onboard D5 (FAN_ON)
        led_red : out STD_LOGIC;    -- IDLE
        led_green : out STD_LOGIC;  -- COOLON
        led_yellow : out STD_LOGIC; -- ACNOWREADY
        led_blue : out STD_LOGIC    -- ACDONE
    );
end cooling_fsm_top;

architecture Behavioral of cooling_fsm_top is
    -- Internal signals
    signal COOL      : std_logic := '0';
    signal AC_READY  : std_logic := '0';
    signal A_C_ON    : std_logic;
    signal FAN_ON    : std_logic;
    type STATE_TYPE is (IDLE, COOLON, ACNOWREADY, ACDONE);
    signal CURRENT_STATE : STATE_TYPE := IDLE;
    signal NEXT_STATE    : STATE_TYPE;

    -- Add toggled versions of button signals
    signal cool_latched     : std_logic := '0';
    signal ac_ready_latched : std_logic := '0';
    signal key1_prev, key2_prev : std_logic := '0';  -- to detect button edges

begin
    ------------------------------------------------------------
    -- BUTTON TOGGLE PROCESS (creates latched signals)
    ------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- detect a new press (rising edge) of key1
            if (key1 = '1' and key1_prev = '0') then
                cool_latched <= not cool_latched;
            end if;

            -- detect a new press (rising edge) of key2
            if (key2 = '1' and key2_prev = '0') then
                ac_ready_latched <= not ac_ready_latched;
            end if;

            -- store the previous button states
            key1_prev <= key1;
            key2_prev <= key2;
        end if;
    end process;

    ------------------------------------------------------------
    -- Connect latched signals to FSM inputs
    ------------------------------------------------------------
    COOL     <= cool_latched;   
    AC_READY <= ac_ready_latched;   

    ------------------------------------------------------------
    -- FSM OUTPUTS → LEDs
    ------------------------------------------------------------
    led1 <= A_C_ON;     
    led2 <= FAN_ON;     

    ------------------------------------------------------------
    -- FSM STATE REGISTER
    ------------------------------------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            CURRENT_STATE <= NEXT_STATE;
        end if;
    end process;

    ------------------------------------------------------------
    -- FSM NEXT STATE LOGIC
    ------------------------------------------------------------
    process (CURRENT_STATE, COOL, AC_READY)
    begin
        case CURRENT_STATE is
            when IDLE =>
                if COOL = '1' then
                    NEXT_STATE <= COOLON;
                else
                    NEXT_STATE <= IDLE;
                end if;

            when COOLON =>
                if AC_READY = '1' then
                    NEXT_STATE <= ACNOWREADY;
                else
                    NEXT_STATE <= COOLON;
                end if;

            when ACNOWREADY =>
                if COOL = '0' then
                    NEXT_STATE <= ACDONE;
                else
                    NEXT_STATE <= ACNOWREADY;
                end if;

            when ACDONE =>
                if AC_READY = '0' then
                    NEXT_STATE <= IDLE;
                else
                    NEXT_STATE <= ACDONE;
                end if;
        end case;
    end process;

    ------------------------------------------------------------
    -- FSM OUTPUT LOGIC (LED behavior)
    ------------------------------------------------------------
    process (CURRENT_STATE)
    begin
        -- Default all LEDs off
        A_C_ON <= '0';
        FAN_ON <= '0';
        led_red <= '0';
        led_green <= '0';
        led_yellow <= '0';
        led_blue <= '0';

        -- State-specific assignments
        case CURRENT_STATE is
            when IDLE =>
                led_red <= '1';
                A_C_ON <= '0';
                FAN_ON <= '0';

            when COOLON =>
                led_green <= '1';
                A_C_ON <= '1';
                FAN_ON <= '0';

            when ACNOWREADY =>
                led_yellow <= '1';
                A_C_ON <= '1';
                FAN_ON <= '1';

            when ACDONE =>
                led_blue <= '1';
                A_C_ON <= '0';
                FAN_ON <= '1';
        end case;
    end process;

end Behavioral;
