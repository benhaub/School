onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color White -itemcolor White /final_tb/clk
add wave -noupdate /final_tb/reset
add wave -noupdate -color {Steel Blue} -itemcolor Black -radix hexadecimal /final_tb/seed
add wave -noupdate -color {Steel Blue} -itemcolor Black -radix hexadecimal /final_tb/accumulator_output
add wave -noupdate -color Khaki -itemcolor Khaki -radix hexadecimal /final_tb/pm_address
add wave -noupdate -color {Medium Aquamarine} -itemcolor {Medium Aquamarine} -radix hexadecimal /final_tb/pm_data
add wave -noupdate -color Gold -itemcolor Gold -radix hexadecimal /final_tb/pc
add wave -noupdate -color Cyan -itemcolor Cyan -radix hexadecimal /final_tb/ir
add wave -noupdate -color Gray70 -itemcolor Grey70 -radix hexadecimal /final_tb/from_PS
add wave -noupdate -color White -itemcolor White -radix hexadecimal /final_tb/from_ID
add wave -noupdate -color {Sky Blue} -itemcolor {Sky Blue} -radix hexadecimal /final_tb/from_CU
add wave -noupdate -radix hexadecimal /final_tb/x0
add wave -noupdate -radix hexadecimal /final_tb/x1
add wave -noupdate -color {Medium Sea Green} -itemcolor {Medium Sea Green} -radix hexadecimal /final_tb/y0
add wave -noupdate -color {Medium Sea Green} -itemcolor {Medium Sea Green} -radix hexadecimal /final_tb/y1
add wave -noupdate -color Green -itemcolor Green -radix hexadecimal /final_tb/r
add wave -noupdate -color Green -itemcolor Green -radix hexadecimal /final_tb/zero_flag
add wave -noupdate -radix hexadecimal /final_tb/m
add wave -noupdate -color White -itemcolor White -radix hexadecimal /final_tb/i
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal /final_tb/o_reg
add wave -noupdate -radix binary /final_tb/NOPC8
add wave -noupdate -color Pink -itemcolor Pink -radix binary /final_tb/NOPCF
add wave -noupdate -radix binary /final_tb/NOPD8
add wave -noupdate -color Pink -itemcolor Pink -radix binary /final_tb/NOPDF
add wave -noupdate -radix hexadecimal /final_tb/register_enables
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {524689215 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {386112 ns} {964198184 ps}
