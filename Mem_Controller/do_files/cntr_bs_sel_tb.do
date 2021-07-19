onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cntr_bs_sel_tb/clk
add wave -noupdate /cntr_bs_sel_tb/full
add wave -noupdate /cntr_bs_sel_tb/mid
add wave -noupdate /cntr_bs_sel_tb/empty
add wave -noupdate /cntr_bs_sel_tb/valid
add wave -noupdate /cntr_bs_sel_tb/ra_i
add wave -noupdate /cntr_bs_sel_tb/t_i
add wave -noupdate /cntr_bs_sel_tb/last_ra
add wave -noupdate /cntr_bs_sel_tb/push
add wave -noupdate /cntr_bs_sel_tb/k
add wave -noupdate /cntr_bs_sel_tb/selector/valid_i
add wave -noupdate /cntr_bs_sel_tb/selector/ra_i
add wave -noupdate /cntr_bs_sel_tb/selector/t_i
add wave -noupdate /cntr_bs_sel_tb/selector/full
add wave -noupdate /cntr_bs_sel_tb/selector/mid
add wave -noupdate /cntr_bs_sel_tb/selector/rd_empty
add wave -noupdate /cntr_bs_sel_tb/selector/rd_full
add wave -noupdate /cntr_bs_sel_tb/selector/rd_mid
add wave -noupdate /cntr_bs_sel_tb/selector/wr_empty
add wave -noupdate /cntr_bs_sel_tb/selector/wr_full
add wave -noupdate /cntr_bs_sel_tb/selector/wr_mid
add wave -noupdate /cntr_bs_sel_tb/selector/hits
add wave -noupdate /cntr_bs_sel_tb/selector/rd_full
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {112 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 261
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
WaveRestoreZoom {0 ns} {214 ns}
