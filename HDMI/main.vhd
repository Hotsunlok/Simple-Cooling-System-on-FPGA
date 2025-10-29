-- main.vhd  (HDMI 640x480 @ 60Hz, for MicroPhase A7-Lite)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity main is
    port (
        w_clk       : in  std_logic;  -- 50 MHz board clock
        tmds_r_p    : out std_logic;
        tmds_r_n    : out std_logic;
        tmds_g_p    : out std_logic;
        tmds_g_n    : out std_logic;
        tmds_b_p    : out std_logic;
        tmds_b_n    : out std_logic;
        tmds_clk_p  : out std_logic;
        tmds_clk_n  : out std_logic
    );
end entity main;

architecture rtl of main is

    ------------------------------------------------------------------
    -- Clock wizard outputs:
    -- clk_out1 = 25.175 MHz  (pixel clock)
    -- clk_out2 = 251.75 MHz  (TMDS 10x)
    ------------------------------------------------------------------
    component clk_wiz_0
        port (
            clk_in1  : in  std_logic;
            clk_out1 : out std_logic;
            clk_out2 : out std_logic
        );
    end component;

    component tmds_encode
        port (
            clk         : in  std_logic;
            d_in        : in  std_logic_vector(7 downto 0);
            sync        : in  std_logic_vector(1 downto 0);
            w_draw_area : in  std_logic;
            d_out       : out std_logic_vector(9 downto 0)
        );
    end component;

    signal clk_pix  : std_logic;
    signal clk_tmds : std_logic;

 -- Horizontal
constant H_ACTIVE : integer := 640;
constant H_FP     : integer := 16;
constant H_SYNC   : integer := 96;
constant H_BP     : integer := 48;
constant H_TOTAL  : integer := 800;

-- Vertical
constant V_ACTIVE : integer := 480;
constant V_FP     : integer := 10;
constant V_SYNC   : integer := 2;
constant V_BP     : integer := 33;
constant V_TOTAL  : integer := 525;



    signal r_x         : unsigned(9 downto 0) := (others => '0');
    signal r_y         : unsigned(9 downto 0) := (others => '0');
    signal hSync       : std_logic := '1';
    signal vSync       : std_logic := '1';
    signal w_draw_area : std_logic := '0';

    signal red, green, blue : std_logic_vector(7 downto 0) := (others => '0');

    signal tmds_red, tmds_green, tmds_blue : std_logic_vector(9 downto 0);
    signal tmds_cnt : unsigned(3 downto 0) := (others => '0');

    signal tmds_sft_red, tmds_sft_green, tmds_sft_blue : std_logic_vector(9 downto 0);
    signal tmds_en : std_logic := '0';

begin

    ------------------------------------------------------------------
    -- Clock generation
    ------------------------------------------------------------------
    m0: clk_wiz_0
        port map (
            clk_in1  => w_clk,
            clk_out1 => clk_pix,
            clk_out2 => clk_tmds
        );

    ------------------------------------------------------------------
    -- Horizontal/vertical counters and sync
    ------------------------------------------------------------------
    process(clk_pix)
    begin
        if rising_edge(clk_pix) then
            if r_x = H_TOTAL - 1 then
                r_x <= (others => '0');
                if r_y = V_TOTAL - 1 then
                    r_y <= (others => '0');
                else
                    r_y <= r_y + 1;
                end if;
            else
                r_x <= r_x + 1;
            end if;

            -- negative polarity syncs for VGA
            hSync <= '0' when (to_integer(r_x) >= (H_ACTIVE + H_FP) and
                               to_integer(r_x) <  (H_ACTIVE + H_FP + H_SYNC))
                      else '1';
            vSync <= '0' when (to_integer(r_y) >= (V_ACTIVE + V_FP) and
                               to_integer(r_y) <  (V_ACTIVE + V_FP + V_SYNC))
                      else '1';
            w_draw_area <= '1' when (to_integer(r_x) < H_ACTIVE and
                                     to_integer(r_y) < V_ACTIVE)
                           else '0';
        end if;
    end process;

    ------------------------------------------------------------------
    -- Simple color bars (red/green/blue)
    ------------------------------------------------------------------
    process(clk_pix)
        constant BAR_W : integer := 213;
        variable x : integer;
    begin
        if rising_edge(clk_pix) then
            x := to_integer(r_x);
            if w_draw_area = '1' then
                if x < BAR_W then
                    red <= x"FF";  green <= x"00";  blue <= x"00";
                elsif x < 2*BAR_W then
                    red <= x"00";  green <= x"FF";  blue <= x"00";
                else
                    red <= x"00";  green <= x"00";  blue <= x"FF";
                end if;
            else
                red <= x"00";  green <= x"00";  blue <= x"00";
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- TMDS encode channels
    ------------------------------------------------------------------
    m_enc1: tmds_encode
        port map (clk => clk_pix, d_in => red,   sync => "00", w_draw_area => w_draw_area, d_out => tmds_red);
    m_enc2: tmds_encode
        port map (clk => clk_pix, d_in => green, sync => "00", w_draw_area => w_draw_area, d_out => tmds_green);
    m_enc3: tmds_encode
        port map (clk => clk_pix, d_in => blue,  sync => vSync & hSync, w_draw_area => w_draw_area, d_out => tmds_blue);

    ------------------------------------------------------------------
    -- 10:1 shift serializer (simplified TMDS output)
    ------------------------------------------------------------------
    process(clk_tmds)
    begin
        if rising_edge(clk_tmds) then
            tmds_en <= '1' when tmds_cnt = 9 else '0';

            if tmds_en = '1' then
                tmds_sft_red   <= tmds_red;
                tmds_sft_green <= tmds_green;
                tmds_sft_blue  <= tmds_blue;
            else
                tmds_sft_red   <= tmds_sft_red(9 downto 1) & '0';
                tmds_sft_green <= tmds_sft_green(9 downto 1) & '0';
                tmds_sft_blue  <= tmds_sft_blue(9 downto 1) & '0';
            end if;

            if tmds_cnt = 9 then
                tmds_cnt <= (others => '0');
            else
                tmds_cnt <= tmds_cnt + 1;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- TMDS differential outputs
    ------------------------------------------------------------------
    m_ds1: OBUFDS
        generic map (IOSTANDARD => "TMDS_33", SLEW => "FAST")
        port map (O => tmds_r_p,  OB => tmds_r_n,  I => tmds_sft_red(0));

    m_ds2: OBUFDS
        generic map (IOSTANDARD => "TMDS_33", SLEW => "FAST")
        port map (O => tmds_g_p,  OB => tmds_g_n,  I => tmds_sft_green(0));

    m_ds3: OBUFDS
        generic map (IOSTANDARD => "TMDS_33", SLEW => "FAST")
        port map (O => tmds_b_p,  OB => tmds_b_n,  I => tmds_sft_blue(0));

    m_ds4: OBUFDS
        generic map (IOSTANDARD => "TMDS_33", SLEW => "FAST")
        port map (O => tmds_clk_p, OB => tmds_clk_n, I => clk_pix);

end architecture rtl;
