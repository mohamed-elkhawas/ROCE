module timing_controller import types_def::*;
	
	#( parameter no_of_bursts  = 4 )

	(
	input clk,    // Clock
	input rst_n,  // synchronous reset active low
	input logic [banks_no-1:0][1:0] in_bank_state, // idle , same_row , same_burst, different_row
	input logic [no_of_bursts:0][1:0] in_burst_state, // started_filling , full , empty , returning_data
	input address_type [no_of_bursts:0] in_burst_address,

	output logic [banks_no-1:0] bank_start_burst_o, // witch bank is allowed to be taken from
	output command [no_of_bursts:0] burst_start_next_cmd_o	// start cmd 
);

logic [banks_no-1:0] bank_start_burst;
logic command [no_of_bursts:0] burst_start_next_cmd;


//////////////////////////////// timing params \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
localparam  
			//////////////////////////////same bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
			max_time   =,
			max_time_log == $clog2(max_time);,
			act_to_rd  =, // or write
			col_to_pre =,
			pre_to_act =,
			act_to_act_same_bank =,
			act_to_pre =,
			wr_to_data =,
			rd_to_data =,
			rd_to_pre =,
			end_of_wr_to_pre =,

			//////////////////////////////diff bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			act_to_act_diff_bank =,


			//////////////////////////////any bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			rd_to_wr =,
			wr_to_rd =,

			burst_time =,
			col_to_col =;

//////////////////////////////// declarations \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


typedef enum logic [2:0] {activate , read_cmd , write_cmd , change_mode ,  precharge , none} command ; /* change_mode from rd to wr or vise versa*/

//command [banks_no-1:0] bank_last_cmd , bank_next_cmd;

logic [banks_no-1:0] [row_addres_len:0] bank_active_row ; //  +1 for the valid bit

command [no_of_bursts-1:0] burst_last_cmd , burst_next_cmd;

logic [banks_no-1:0] [max_time_log:0] bank_counter ; // 0 = ready to send the next cmd

logic [4-1:0] [max_time_log:0] bank_group_counter ;

logic [max_time_log:0] global_counter ; // all bursts wait until the data burst

typedef enum logic [1:0] { idle , send_cmd , data_is_comming } my_1st_states ; // to be edited
my_1st_states burst_curr_state , burst_next_state ; 

//typedef enum logic {idle , new_bank_allowed } my_2nd_states ; // to be edited
//my_2nd_states bank_curr_state , bank_next_state ; 

logic [no_of_bursts:0][3:0] burst_bank_add;
always_comb begin 
	for (int i = 0; i < 4; i++) begin
		burst_bank_add[i] = {in_burst_address[i].bank_group , in_burst_address[i].bank}
	end
end

logic [2:0] start_i;
logic stop;
//////////////////////////////////////////////// the work of art \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
always_ff @(posedge clk ) begin
	if(rst_n) begin
		burst_curr_state <= burst_next_state ;
		bank_curr_state <= bank_next_state ;
	end 
	else begin
		burst_curr_state <= 0 ;
		bank_curr_state <= 0 ;
		bank_open_row <= 0;
		start_i <= 0;
		stop <= 0;
		for (int i = 0; i < no_of_bursts; i++) begin
			burst_last_cmd[i] = none;
			burst_next_cmd[i] = activate;
		end
	end
end


///////////////////// bank block \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin 
	for (int i = 0; i < banks_no; i++) begin
		if (in_bank_state[i] != idle && bank_counter[i] == 0 && bank_group_counter[ i/4 ] == 0 ) begin 
			bank_start_burst[i] = 1;
		end
		else bank_start_burst[i] = 0;
	end	
end

///////////////////// burst block \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin

for (int i = start_i; i < start_i+no_of_bursts; i++) begin
	if (stop == 0) begin
		if (in_burst_state != empty || in_burst_state != returning_data) begin
			if (bank_counter[burst_bank_add[i]] == 0 && bank_group_counter[in_burst_address.bank_group] == 0 && ) begin
				stop = 1;
				burst_start_next_cmd[i] = burst_next_cmd[i];
				burst_last_cmd = burst_next_cmd;

				case (burst_last_cmd)
					activate: begin
						bank_counter[i] = ;
						bank_group_counter[i/4] = ;
					end
					read_cmd: begin
						bank_counter[i] = ;
						bank_group_counter[i/4] = ;
						global_counter = ;
					end
					write_cmd: begin
						bank_counter[i] = ;
						bank_group_counter[i/4] = ;
						global_counter = ;
					end
					change_mode: begin
						bank_counter[i] = ;
						bank_group_counter[i/4] = ;
					end
					precharge: begin
						bank_counter[i] = ;
						bank_group_counter[i/4] = ;
					end
					none: begin
						bank_counter[i] = ;
						bank_group_counter[i/4] = ;
					end
					
					default: begin
						bank_counter[i] = ;
						bank_group_counter[i/4] = ;
						burst_next_cmd[i] = ;
					end
				endcase

			end
		end
	end
	
end
stop = 0;
start_i ++;

end

always_ff @(posedge clk) begin

	for (int i = 0; i < banks_no; i++) begin
		if (bank_counter[i] != 0) begin
			bank_counter[i] <= bank_counter[i] -1 ;
		end
	end
	for (int i = 0; i < 4; i++) begin
		if (bank_group_counter[i] != 0) begin
			bank_group_counter[i] <= bank_group_counter[i] -1 ;
		end
	end
	if (global_counter[i] != 0) begin
		global_counter[i] <= global_counter[i] -1 ;
	end
	
	bank_start_burst_o <= bank_start_burst;
	burst_start_next_cmd_o <= burst_start_next_cmd;
end


endmodule
