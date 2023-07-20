onerror {resume}
quietly virtual function -install /APB_TB -env /APB_TB { &{/APB_TB/start_0, /APB_TB/start_1, /APB_TB/start_2 }} Start
quietly virtual function -install /APB_TB -env /APB_TB { &{/APB_TB/rw_0, /APB_TB/rw_1, /APB_TB/rw_2 }} rw
quietly WaveActivateNextPane {} 0
add wave -noupdate /APB_TB/clk
add wave -noupdate -expand -group {Selected Master/Slave} /APB_TB/D0/f0/A0/priority_state
add wave -noupdate -expand -group {Selected Master/Slave} -radix binary -childformat {{{/APB_TB/D0/o_gnt[2]} -radix binary} {{/APB_TB/D0/o_gnt[1]} -radix binary} {{/APB_TB/D0/o_gnt[0]} -radix binary}} -subitemconfig {{/APB_TB/D0/o_gnt[2]} {-height 15 -radix binary} {/APB_TB/D0/o_gnt[1]} {-height 15 -radix binary} {/APB_TB/D0/o_gnt[0]} {-height 15 -radix binary}} /APB_TB/D0/o_gnt
add wave -noupdate -expand -group {Selected Master/Slave} -radix binary -childformat {{{/APB_TB/D0/psel_s[2]} -radix binary} {{/APB_TB/D0/psel_s[1]} -radix binary} {{/APB_TB/D0/psel_s[0]} -radix binary}} -subitemconfig {{/APB_TB/D0/psel_s[2]} {-height 15 -radix binary} {/APB_TB/D0/psel_s[1]} {-height 15 -radix binary} {/APB_TB/D0/psel_s[0]} {-height 15 -radix binary}} /APB_TB/D0/psel_s
add wave -noupdate /APB_TB/start_0
add wave -noupdate /APB_TB/start_1
add wave -noupdate /APB_TB/start_2
add wave -noupdate /APB_TB/rw_0
add wave -noupdate /APB_TB/rw_1
add wave -noupdate /APB_TB/rw_2
add wave -noupdate /APB_TB/valid
add wave -noupdate /APB_TB/ready
add wave -noupdate -expand -group {Mimic slaves} /APB_TB/mimic_mem_0
add wave -noupdate -expand -group {Mimic slaves} /APB_TB/mimic_mem_1
add wave -noupdate -expand -group {Mimic slaves} /APB_TB/mimic_mem_2
add wave -noupdate -expand -group Master_0 -radix unsigned /APB_TB/addr_rand_0
add wave -noupdate -expand -group Master_0 -radix unsigned /APB_TB/slave_rand_0
add wave -noupdate -expand -group Master_0 /APB_TB/data_rand_0
add wave -noupdate -group Master_1 -radix unsigned /APB_TB/addr_rand_1
add wave -noupdate -group Master_1 -radix unsigned /APB_TB/slave_rand_1
add wave -noupdate -group Master_1 /APB_TB/data_rand_1
add wave -noupdate -expand -group Master_2 -radix unsigned /APB_TB/addr_rand_2
add wave -noupdate -expand -group Master_2 -radix unsigned /APB_TB/slave_rand_2
add wave -noupdate -expand -group Master_2 /APB_TB/data_rand_2
add wave -noupdate -expand -group {Read data} /APB_TB/o_data_out_m0
add wave -noupdate -expand -group {Read data} /APB_TB/o_data_out_m1
add wave -noupdate -expand -group {Read data} /APB_TB/o_data_out_m2
add wave -noupdate -group Slave_0 -radix hexadecimal /APB_TB/D0/S0/i_paddr
add wave -noupdate -group Slave_0 /APB_TB/D0/S0/i_pclk
add wave -noupdate -group Slave_0 /APB_TB/D0/S0/i_penable
add wave -noupdate -group Slave_0 /APB_TB/D0/S0/i_prstn
add wave -noupdate -group Slave_0 /APB_TB/D0/S0/i_psel
add wave -noupdate -group Slave_0 /APB_TB/D0/S0/i_pwdata
add wave -noupdate -group Slave_0 /APB_TB/D0/S0/i_pwrite
add wave -noupdate -group Slave_0 /APB_TB/D0/S0/mem
add wave -noupdate -group Slave_1 /APB_TB/D0/S1/i_paddr
add wave -noupdate -group Slave_1 /APB_TB/D0/S1/i_pclk
add wave -noupdate -group Slave_1 /APB_TB/D0/S1/i_penable
add wave -noupdate -group Slave_1 /APB_TB/D0/S1/i_prstn
add wave -noupdate -group Slave_1 /APB_TB/D0/S1/i_psel
add wave -noupdate -group Slave_1 /APB_TB/D0/S1/i_pwdata
add wave -noupdate -group Slave_1 /APB_TB/D0/S1/i_pwrite
add wave -noupdate -group Slave_1 -expand /APB_TB/D0/S1/mem
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/i_paddr
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/i_pclk
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/i_penable
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/i_prstn
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/i_psel
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/i_pwdata
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/i_pwrite
add wave -noupdate -group Slave_2 /APB_TB/D0/S2/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {207538800 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 305
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {207037600 ps} {210156 ns}
