module timing_controller import types_def::*;
	
	#( parameter no_of_bursts  = 4 )

	(
	input clk,    // Clock
	input rst_n,  // synchronous reset active low

	input burst_states_type [no_of_bursts-1:0] in_burst_state, // started_filling , full , empty , returning_data
	input r_type [no_of_bursts-1:0] in_burst_type,
	input address_type [no_of_bursts-1:0] in_burst_address, /// i need the row , bank and bank_group bits

	//output logic [no_of_bursts-1:0] valid_out,
	output command [no_of_bursts-1:0] burst_cmd_o	// start cmd 
	);

command [no_of_bursts-1:0] burst_cmd;

//////////////////////////////// timing params \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
localparam  
			max_time   = 39,
			max_time_log = $clog2(max_time),

			//////////////////////////////same bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
			
			act_to_rd  =11, // or write
			pre_to_act =11,
			act_to_act_same_bank =39,
			act_to_pre =28,
			wr_to_data =8,
			rd_to_data =11,
			rd_to_pre =6,
			wr_to_pre =12,

			//////////////////////////////diff bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			act_to_act_diff_bank =6,


			//////////////////////////////any bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			rd_to_wr =9,
			wr_to_rd =18,
			rd_to_rd =4,

			burst_time = 8;

//////////////////////////////// declarations \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


//command [banks_no-1:0] bank_last_cmd , bank_next_cmd;

logic [banks_no-1:0] [row_addres_len-1:0] bank_active_row ; 
logic [banks_no-1:0] bank_active_row_valid ;

command [no_of_bursts-1:0] burst_last_cmd ;//, burst_next_cmd;
command global_last_cmd;

logic [banks_no-1:0] [max_time_log-1:0] bank_counter_act ;
logic [banks_no-1:0] [max_time_log-1:0] bank_counter_rd ;
logic [banks_no-1:0] [max_time_log-1:0] bank_counter_wr ;
logic [banks_no-1:0] [max_time_log-1:0] bank_counter_pre ; 

logic [4-1:0] [max_time_log-1:0] bank_group_counter_act ;
logic [4-1:0] [max_time_log-1:0] bank_group_counter_rd ;
logic [4-1:0] [max_time_log-1:0] bank_group_counter_wr ;
//logic [4-1:0] [max_time_log:0] bank_group_counter_pre ;

logic [max_time_log-1:0] global_counter_rd ; // for rd to wr delay
logic [max_time_log-1:0] global_counter_wr ; // for wr to rd delay
//logic [max_time_log:0] global_counter_data ;

r_type last_cmd_type;

logic [no_of_bursts-1:0][3:0] burst_bank_add;
always_comb begin 
	for (int i = 0; i < 4; i++) begin
		burst_bank_add[i] = {in_burst_address[i].bank_group , in_burst_address[i].bank};
	end
end

logic [2:0] start_i;
logic stop;


//////////////////////////////////////////////// the state of art \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

///////////////////// updating regesters \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_ff @(posedge clk) begin

	if(rst_n) begin
		for (int i = 0; i < banks_no; i++) begin
			if (bank_counter_act[i] != max_time) begin
				bank_counter_act[i] <= bank_counter_act[i] +1 ;
			end
			if (bank_counter_rd[i] != max_time) begin
				bank_counter_rd[i] <= bank_counter_rd[i] +1 ;
			end
			if (bank_counter_wr[i] != max_time) begin
				bank_counter_wr[i] <= bank_counter_wr[i] +1 ;
			end
			if (bank_counter_pre[i] != max_time) begin
				bank_counter_pre[i] <= bank_counter_pre[i] +1 ;
			end
		end
		for (int i = 0; i < 4; i++) begin
			if (bank_group_counter_act[i] != max_time) begin
				bank_group_counter_act[i] <= bank_group_counter_act[i] +1 ;
			end
			if (bank_group_counter_rd[i] != max_time) begin
				bank_group_counter_rd[i] <= bank_group_counter_rd[i] +1 ;
			end
			if (bank_group_counter_wr[i] != max_time) begin
				bank_group_counter_wr[i] <= bank_group_counter_wr[i] +1 ;
			end

		end

		if (global_counter_rd != max_time) begin
			global_counter_rd <= global_counter_rd +1 ;
		end
		if (global_counter_wr != max_time) begin
			global_counter_wr <= global_counter_wr +1 ;
		end

		for (int i = 0; i < no_of_bursts; i++) begin
			if (burst_cmd[i] != none) begin
				case (burst_cmd[i])
					activate: begin   bank_counter_act[i] <=0; bank_group_counter_act[i] <=0; end
					read_cmd: begin   bank_counter_rd[i] <=0; bank_group_counter_rd[i] <=0; global_counter_rd <= 0; end // global_counter_data <= 0; end
					write_cmd: begin  bank_counter_wr[i] <=0; bank_group_counter_wr[i] <=0; global_counter_wr <= 0; end //global_counter_data <= 0; end
					precharge: begin  bank_counter_pre[i] <=0;  end
				endcase
			end
		end

	end 

	else begin

		for (int i = 0; i < banks_no; i++) begin
			bank_counter_act[i] <=  0;
			bank_counter_rd[i] <=  0;
			bank_counter_wr[i] <=  0;
			bank_counter_pre[i] <=  0;
		end
		for (int i = 0; i < 4; i++) begin
			bank_group_counter_act[i] <= 0;
			bank_group_counter_rd[i] <= 0;
			bank_group_counter_wr[i] <= 0;
		end
		global_counter_rd <= 0;
		global_counter_wr <= 0;
		
	end
	
end


function do_the_magic (int i );

						if ( bank_active_row_valid == 1 ) begin // there is active row
							if (bank_active_row == in_burst_address[i[1:0]].row) begin // same active row
								if (in_burst_type[i[1:0]] == last_cmd_type  ||  ( ( last_cmd_type == read_cmd && global_counter_wr > wr_to_rd-2 ) && ( last_cmd_type == write && global_counter_rd > rd_to_wr-2 ) ) ) begin // same type or rd_to_wr delays are done
									if ( bank_counter_act[burst_bank_add[i[1:0]]] > rd_to_rd-2 ) begin // column to column time
									
										if (in_burst_type[i[1:0]] == read) begin
											if (in_burst_state[i[1:0]] == almost_done || in_burst_state[i[1:0]] == full ) begin
												stop = 1; 
												burst_cmd[i[1:0]] = read_cmd ;
												burst_last_cmd[i[1:0]] = read_cmd;
												global_last_cmd = read_cmd;
											end
										end
										else begin
											if (in_burst_state[i[1:0]] == full ) begin
												stop = 1; 
												burst_cmd[i[1:0]] = write_cmd ;
												burst_last_cmd[i[1:0]] = write_cmd ;
												global_last_cmd = write_cmd;
											end
										end
									end
								end
								
							end
							
							else begin  // diff active row

								if (bank_counter_act[burst_bank_add[i[1:0]]] > act_to_pre-2 && bank_counter_rd[burst_bank_add[i[1:0]]] > rd_to_pre-2  && bank_counter_wr[burst_bank_add[i[1:0]]] > wr_to_pre-2 ) begin
									stop = 1; 
									burst_cmd[i[1:0]] = precharge ;
									burst_last_cmd[i[1:0]] = precharge ;
									global_last_cmd = precharge;
									bank_active_row = in_burst_address[i[1:0]].row;
									bank_active_row_valid[i[1:0]] = 1;
								end
							end
						end
						else begin // no active row
							
							if (bank_counter_pre[burst_bank_add[i[1:0]]] > pre_to_act-2 && bank_group_counter_act[burst_bank_add[i[1:0]]] > act_to_act_diff_bank-2  && bank_counter_act[burst_bank_add[i[1:0]]] > act_to_act_same_bank-2 ) begin
								stop = 1; 
								burst_cmd[i[1:0]] = activate;
								burst_last_cmd[i[1:0]] = activate;
								global_last_cmd = activate;
								bank_active_row = in_burst_address[i[1:0]].row;
								bank_active_row_valid = 1 ;
							end
						end
	
endfunction

///////////////////// burst block \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

//always_ff @(posedge clk) begin
always_comb begin 

if (rst_n) begin
	
	for (int i = start_i; i < start_i+no_of_bursts; i++) begin // round roubin
		
		burst_cmd[i[1:0]] = none;

		if (stop == 0 && global_counter_rd > burst_time + rd_to_data-2 && global_counter_wr > burst_time + wr_to_data-2 ) begin /// the bus is free
			if (in_burst_state[i[1:0]] != empty && in_burst_state[i[1:0]] != returning_data) begin //  there is requests to be sent

				case (burst_last_cmd[i[1:0]])
					activate: begin
						if (in_burst_type[i[1:0]] == last_cmd_type  ||  ( ( last_cmd_type == read_cmd && global_counter_wr > wr_to_rd-2 ) && ( last_cmd_type == write && global_counter_rd > rd_to_wr-2 ) ) ) begin
							if ( bank_counter_act[burst_bank_add[i[1:0]]] > act_to_rd-2 ) begin

								if (in_burst_type[i[1:0]] == read) begin
									if (in_burst_state[i[1:0]] == almost_done || in_burst_state[i[1:0]] == full ) begin
										stop = 1; 
										burst_cmd[i[1:0]] = read_cmd ;
										burst_last_cmd[i[1:0]] = read_cmd;
										global_last_cmd = read_cmd;
									end
								end
								else begin
									if (in_burst_state[i[1:0]] == full ) begin
										stop = 1; 
										burst_cmd[i[1:0]] = write_cmd ;
										burst_last_cmd[i[1:0]] = write_cmd ;
										global_last_cmd = write_cmd;
									end
								end
							end
						end
						/*else begin
							stop = 1; 
							burst_cmd[i[1:0]] = change_mode ;
							burst_last_cmd[i[1:0]] = change_mode ;
							global_last_cmd = change_mode;
						end*/

					end
					read_cmd: begin
						do_the_magic (i);
					end
					write_cmd: begin
						do_the_magic (i);
					end
					precharge: begin
						if (bank_counter_pre[burst_bank_add[i[1:0]]] > pre_to_act-2 && bank_group_counter_act[burst_bank_add[i[1:0]]] > act_to_act_diff_bank-2  && bank_counter_act[burst_bank_add[i[1:0]]] > act_to_act_same_bank-2 ) begin
							stop = 1; 
							burst_cmd[i[1:0]] = activate;
							burst_last_cmd[i[1:0]] = activate;
							global_last_cmd = activate;
							bank_active_row = in_burst_address[i[1:0]].row;
							bank_active_row_valid = 1 ;
						end
					end
					none: begin
						if (bank_group_counter_act[burst_bank_add[i[1:0]]] > act_to_act_diff_bank-2) begin
							stop = 1; 
							burst_cmd[i[1:0]] = activate;
							burst_last_cmd[i[1:0]] = activate;
							global_last_cmd = activate;
							bank_active_row = in_burst_address[i[1:0]].row;
							bank_active_row_valid = 1 ;
						end
					end
				
					default: begin
						burst_cmd[i[1:0]] = none;
						
						bank_active_row_valid = 0;
						burst_last_cmd[i[1:0]] = none;
						global_last_cmd = none;
					end
				endcase
			end
		end
	end

	if (stop) begin
		start_i ++;
		stop = 0;
	end	
end

else begin
	start_i = 0;
	stop = 0;
	for (int i = 0; i < no_of_bursts; i++) begin
		burst_last_cmd[i] = none;
	end
	
	bank_active_row_valid = 0;
	global_last_cmd = none;
	last_cmd_type = read;

end

end


///////////////////////////////////////////////// output update \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_ff @(posedge clk or negedge rst_n) begin : proc_
	if(rst_n) begin
		burst_cmd_o <= burst_cmd;
	end 
	else begin
		burst_cmd_o <= none;
	end
end

endmodule
