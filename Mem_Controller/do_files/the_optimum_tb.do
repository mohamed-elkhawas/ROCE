onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/clk
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/rst_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/valid_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/data_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/idx_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/row_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/col_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/t_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/ready
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/returner_valid
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/returner_type
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/returner_data
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/returner_index
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/CS_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/CA
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/CAI
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/DM_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/DQ
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/DQS_t
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/DQS_c
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/ALERT_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/data_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/idx_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/row_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/col_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/t_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/ba_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/bg_o
add wave -noupdate -color Magenta -itemcolor Magenta /the_optimum_tb/the_memory_controller/the_back_end/wr_en
add wave -noupdate -color Gold -itemcolor Gold /the_optimum_tb/the_memory_controller/the_back_end/the_handler/arbiter_type_temp
add wave -noupdate -color Gold -itemcolor Gold /the_optimum_tb/the_memory_controller/the_back_end/burst_state
add wave -noupdate -color Gold -itemcolor Gold /the_optimum_tb/the_memory_controller/the_front_end/t_o
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/t_o}
add wave -noupdate -color Gold /the_optimum_tb/the_memory_controller/the_back_end/burst_type
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/burst_address_bank
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/burst_address_bg
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/burst_address_row
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/burst_cmd_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/cmd_index_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/start_new_burst
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/clk
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/rst_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/in_valid
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/in_request_type
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/in_request_data
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/in_request_address
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/out_busy
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/request_done_valid
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/the_type
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/data_in
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/index
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/write_done
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/read_done
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/data_out
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/ready
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/valid_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/dq_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/idx_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/ra_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/ca_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/request_out
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/out_index
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/grant_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/bank_out_valid
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/pop
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/valid_out
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/out_fifo_sch
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/idx_out
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/num
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/mode
add wave -noupdate /the_optimum_tb/the_memory_controller/the_front_end/rd_empty
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/clk
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/rst_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/out_burst_state
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/out_burst_type
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/out_burst_address_bank
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/out_burst_address_bg
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/out_burst_address_row
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/in_burst_cmd
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/in_cmd_index
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/start_new_burst
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/arbiter_valid
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/in_req_address
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/arbiter_data
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/arbiter_index
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/CS_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/CA
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/CAI
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/DM_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/DQ
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/DQS_t
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/DQS_c
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/ALERT_n
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/returner_valid
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/returner_type
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/returner_data
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/returner_index
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/DQ_logic
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/DQS_t_logic
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/DQS_c_logic
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/ALERT_n_logic
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/burst
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/new_burst_counter
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/in_burst
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/older_in_burst
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/out_burst
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/new_burst_flag
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/return_req
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/burst_data_counter
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/first_one_in_mask
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/first_one_id
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/data_wait_counter
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/cmd_burst_id
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/cmd_to_send
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/empty_bursts_counter
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/the_handler/arbiter_type
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/clk}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/rst_n}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/ready}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/mode}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/valid_i}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/dq_i}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/idx_i}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/ra_i}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/ca_i}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/valid_o}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/dq_o}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/idx_o}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/ra_o}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/ca_o}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/rd_empty}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/grant}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/num}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/last_ra}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/full}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/mid}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/empty}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/push}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/pop}
add wave -noupdate {/the_optimum_tb/the_memory_controller/the_front_end/genblk1[0]/BankScheduler/burst_i}
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/data_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/idx_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/row_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/col_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/t_i
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/bank_sel
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/group_sel
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/data_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/idx_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/row_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/col_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/t_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/ba_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/bg_o
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_A3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_A2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_A1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_A0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_B3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_B2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_B1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_B0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_C3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_C2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_C1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_C0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_D3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_D2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_D1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D_D0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_A3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_A2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_A1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_A0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_B3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_B2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_B1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_B0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_C3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_C2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_C1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_C0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_D3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_D2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_D1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/I_D0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_A3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_A2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_A1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_A0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_B3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_B2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_B1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_B0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_C3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_C2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_C1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_C0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_D3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_D2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_D1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/R_D0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_A3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_A2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_A1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_A0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_B3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_B2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_B1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_B0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_C3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_C2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_C1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_C0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_D3
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_D2
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_D1
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C_D0
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_A3
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_A2
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_A1
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_A0
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_B3
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_B2
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_B1
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_B0
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_C3
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_C2
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_C1
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_C0
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_D3
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_D2
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_D1
add wave -noupdate -color Magenta -itemcolor Blue /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/T_D0
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/BA_A
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/BA_B
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/BA_C
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/BA_D
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/sel_D
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/sel_C
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/sel_B
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/sel_A
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/A
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/B
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/C
add wave -noupdate /the_optimum_tb/the_memory_controller/the_back_end/arbiter/D_path/D
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 516
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
WaveRestoreZoom {0 ns} {57 ns}
