onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /AHB_TB/clk
add wave -noupdate -radix unsigned /AHB_TB/addr_rand_0
add wave -noupdate /AHB_TB/hready
add wave -noupdate /AHB_TB/data_out_m0
add wave -noupdate -expand -group Master_0_outputs /AHB_TB/d0/hsel
add wave -noupdate -expand -group Master_0_outputs -radix binary /AHB_TB/d0/mo/o_hburst
add wave -noupdate -expand -group Master_0_outputs -radix unsigned -childformat {{{/AHB_TB/d0/mo/o_haddr[31]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[30]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[29]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[28]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[27]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[26]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[25]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[24]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[23]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[22]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[21]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[20]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[19]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[18]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[17]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[16]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[15]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[14]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[13]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[12]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[11]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[10]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[9]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[8]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[7]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[6]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[5]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[4]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[3]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[2]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[1]} -radix unsigned} {{/AHB_TB/d0/mo/o_haddr[0]} -radix unsigned}} -subitemconfig {{/AHB_TB/d0/mo/o_haddr[31]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[30]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[29]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[28]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[27]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[26]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[25]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[24]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[23]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[22]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[21]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[20]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[19]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[18]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[17]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[16]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[15]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[14]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[13]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[12]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[11]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[10]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[9]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[8]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[7]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[6]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[5]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[4]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[3]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[2]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[1]} {-height 15 -radix unsigned} {/AHB_TB/d0/mo/o_haddr[0]} {-height 15 -radix unsigned}} /AHB_TB/d0/mo/o_haddr
add wave -noupdate -expand -group Master_0_outputs -radix hexadecimal /AHB_TB/d0/mo/o_hwdata
add wave -noupdate -expand -group Master_0_outputs -radix binary /AHB_TB/d0/mo/o_hsize
add wave -noupdate -expand -group Master_0_outputs /AHB_TB/d0/mo/o_htrans
add wave -noupdate -expand -group Master_0_outputs /AHB_TB/d0/mo/o_hwrite
add wave -noupdate /AHB_TB/d0/s1/mem
add wave -noupdate /AHB_TB/mem
add wave -noupdate -expand -group debug /AHB_TB/d0/so/i_hsel
add wave -noupdate -expand -group debug /AHB_TB/d0/s1/i_hsel
add wave -noupdate -expand -group debug /AHB_TB/d0/s1/hsel_samp
add wave -noupdate -expand -group debug /AHB_TB/d0/so/hsel_samp
add wave -noupdate -expand -group debug /AHB_TB/d0/so/o_hreadyout
add wave -noupdate -expand -group debug /AHB_TB/d0/s1/o_hreadyout
add wave -noupdate -expand -group debug -radix unsigned /AHB_TB/d0/s1/haddr_samp
add wave -noupdate -expand -group debug /AHB_TB/d0/s1/write_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {302565100 ps} 0} {{Cursor 2} {161830000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 213
configure wave -valuecolwidth 75
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
configure wave -timelineunits ns
update
WaveRestoreZoom {481262800 ps} {532565200 ps}
