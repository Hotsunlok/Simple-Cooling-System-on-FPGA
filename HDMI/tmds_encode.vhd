-- tmds_encode.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tmds_encode is
    port (
        clk         : in  std_logic;
        d_in        : in  std_logic_vector(7 downto 0);
        sync        : in  std_logic_vector(1 downto 0);
        w_draw_area : in  std_logic;
        d_out       : out std_logic_vector(9 downto 0)
    );
end entity tmds_encode;

architecture rtl of tmds_encode is
    signal bal_acc : signed(3 downto 0) := (others => '0');

    function count_ones(s : std_logic_vector(7 downto 0)) return unsigned is
        variable count : unsigned(3 downto 0) := (others => '0');
    begin
        for i in 0 to 7 loop
            if s(i) = '1' then
                count := count + 1;
            end if;
        end loop;
        return count;
    end function;

    signal w_nbs   : unsigned(3 downto 0);
    signal w_xnor  : std_logic;
    signal q_m     : std_logic_vector(8 downto 0);
    signal bal_int : integer range -4 to 4;
    signal bal     : signed(3 downto 0);
    signal bal_sign_eq : std_logic;
    signal invert_q_m  : std_logic;
    signal temp        : std_logic;
    signal condition   : std_logic;
    signal bal_acc_inc_int : integer range -5 to 5;  -- Slight extra range for safety
    signal bal_acc_inc : signed(3 downto 0);
    signal bal_acc_t   : signed(3 downto 0);
    signal w_data      : std_logic_vector(9 downto 0);
begin
    w_nbs  <= count_ones(d_in);
    w_xnor <= '1' when (w_nbs > 4 or (w_nbs = 4 and d_in(0) = '0')) else '0';

    q_m(0) <= d_in(0);
    gen_qm: for i in 1 to 7 generate
        q_m(i) <= q_m(i-1) xor d_in(i) xor w_xnor;
    end generate gen_qm;
    q_m(8) <= not w_xnor;

    bal_int <= to_integer(count_ones(q_m(7 downto 0))) - 4;
    bal     <= to_signed(bal_int, 4);

    bal_sign_eq <= '1' when bal(3) = bal_acc(3) else '0';

    invert_q_m <= not q_m(8) when (bal_int = 0 or bal_acc = 0) else bal_sign_eq;

    temp      <= q_m(8) xor (not bal_sign_eq);
    condition <= '0' when (bal_int = 0 or bal_acc = 0) else '1';

    bal_acc_inc_int <= bal_int - 1 when (temp = '1' and condition = '1') else bal_int - 0;
    bal_acc_inc     <= to_signed(bal_acc_inc_int, 4);

    bal_acc_t <= bal_acc - bal_acc_inc when invert_q_m = '1' else bal_acc + bal_acc_inc;

    w_data <= invert_q_m & q_m(8) & (q_m(7 downto 0) xor (7 downto 0 => invert_q_m));

    process (clk)
    begin
        if rising_edge(clk) then
            if w_draw_area = '1' then
                bal_acc <= bal_acc_t;
            else
                bal_acc <= (others => '0');
            end if;

            if w_draw_area = '1' then
                d_out <= w_data;
            else
                case sync is
                    when "00" => d_out <= "1101010100";
                    when "01" => d_out <= "0010101011";
                    when "10" => d_out <= "0101010100";
                    when "11" => d_out <= "1010101011";
                    when others => d_out <= "1101010100";  -- Default to "00"
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
