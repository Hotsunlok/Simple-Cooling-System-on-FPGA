##=========================================================
##  Cooling FSM (A7-Lite Artix-7 XC7A35T-2FGG484)
##  Author : Jacky (Tsun Lok Ho)
##  Description : Pin assignments for LEDs, push buttons,
##                and 50 MHz on-board clock.
##=========================================================

# ==============================
# Clock Input (50 MHz oscillator)
# ==============================
set_property PACKAGE_PIN J19 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 20.000 -name sys_clk -waveform {0 10} [get_ports clk]

# ==============================
# Push Buttons
# ==============================
set_property PACKAGE_PIN AA1 [get_ports key1]   ;# KEY1 (Button 1 → COOL)
set_property IOSTANDARD LVCMOS33 [get_ports key1]

set_property PACKAGE_PIN W1 [get_ports key2]    ;# KEY2 (Button 2 → ACREADY)
set_property IOSTANDARD LVCMOS33 [get_ports key2]

# ==============================
# On-board LEDs
# ==============================
set_property PACKAGE_PIN M18 [get_ports led1]   ;# LED1 → A_C_ON (D6)
set_property IOSTANDARD LVCMOS33 [get_ports led1]

set_property PACKAGE_PIN N18 [get_ports led2]   ;# LED2 → FAN_ON (D5)
set_property IOSTANDARD LVCMOS33 [get_ports led2]

# ==============================
# External 4 Colored LEDs
# ==============================
set_property PACKAGE_PIN P17 [get_ports led_red]     ;# RED → IDLE
set_property PACKAGE_PIN R19 [get_ports led_green]   ;# GREEN → COOLON
set_property PACKAGE_PIN T18 [get_ports led_yellow]  ;# YELLOW → ACNOWREADY
set_property PACKAGE_PIN Y22 [get_ports led_blue]    ;# BLUE → ACDONE

set_property IOSTANDARD LVCMOS33 [get_ports {led_red led_green led_yellow led_blue}]
##=========================================================
## End of File
##=========================================================
