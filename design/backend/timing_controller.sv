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

command [no_of_bursts-1:0] burst_cmd, burst_cmd_temp;

//////////////////////////////// timing params \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
localparam  
			max_time   = 20,
			max_time_log = $clog2(max_time),

			//////////////////////////////same bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
			
			act_to_rd  =6, // or write
			pre_to_act =6,
			act_to_act_same_bank =20,
			act_to_pre =14,
			wr_to_data =4,
			rd_to_data =6, // 11 so not sure what to do
			rd_to_pre =3,
			wr_to_pre =6,

			//////////////////////////////diff bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			act_to_act_diff_bank =3,

			//////////////////////////////any bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			rd_to_wr =5,
			wr_to_rd =9,
			rd_to_rd =2,

			burst_time = 8;

//////////////////////////////// declarations \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

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

logic [max_time_log-1:0] global_counter_rd ; // for rd to wr delay
logic [max_time_log-1:0] global_counter_wr ; // for wr to rd delay

r_type last_cmd_type;

logic [no_of_bursts-1:0][3:0] burst_bank_add;
always_comb begin 
	for (int i = 0; i < 4; i++) begin
		burst_bank_add[i] = {in_burst_address[i].bank_group , in_burst_address[i].bank};
	end
end

logic [$clog2(no_of_bursts):0] start_i;
logic [no_of_bursts-1:0] rr_in, rr_temp, rr_out;


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
				start_i <= start_i +1 ;
				case (burst_cmd[i])
					activate: begin
						bank_counter_act[i] <=0; bank_group_counter_act[i] <=0; 
						
						burst_last_cmd[i] <= activate;
						global_last_cmd[i] <= activate;
						
						bank_active_row[burst_bank_add[i]] <= in_burst_address[i[1:0]].row;
						bank_active_row_valid[burst_bank_add[i]] <= 1;	
					end
					read_cmd: begin
						bank_counter_rd[i] <=0; bank_group_counter_rd[i] <=0; global_counter_rd <= 0; 
						
						burst_last_cmd[i] <= read_cmd;
						global_last_cmd[i] <= read_cmd;
					end
					write_cmd: begin
						bank_counter_wr[i] <=0; bank_group_counter_wr[i] <=0; global_counter_wr <= 0;
						
						burst_last_cmd[i] <= write_cmd;
						global_last_cmd[i] <= write_cmd; 
					end
					precharge: begin	
						bank_counter_pre[i] <=0;

						burst_last_cmd[i] <= precharge;
						global_last_cmd[i] <= precharge;
						
						bank_active_row_valid[burst_bank_add[i]] <= 0;  
					end
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
			bank_active_row_valid[i] = 0;
		end
		for (int i = 0; i < 4; i++) begin
			bank_group_counter_act[i] <= 0;
			bank_group_counter_rd[i] <= 0;
			bank_group_counter_wr[i] <= 0;
		end
		global_counter_rd <= 0;
		global_counter_wr <= 0;

		start_i = 0;
		for (int i = 0; i < no_of_bursts; i++) begin
			burst_last_cmd[i] = none;
		end
		bank_active_row_valid = 0;
		global_last_cmd = none;
		last_cmd_type = read;
		
	end
	
end


function do_the_magic (int i );

						if ( bank_active_row_valid == 1 ) begin // there is active row
							if (bank_active_row == in_burst_address[i[1:0]].row) begin // same active row
								if (in_burst_type[i[1:0]] == last_cmd_type  ||  ( ( last_cmd_type == read_cmd && global_counter_wr > wr_to_rd-2 ) && ( last_cmd_type == write && global_counter_rd > rd_to_wr-2 ) ) ) begin // same type or rd_to_wr delays are done
									if ( bank_counter_act[burst_bank_add[i[1:0]]] > rd_to_rd-2 ) begin // column to column time
									
										if (in_burst_type[i[1:0]] == read) begin
											if (in_burst_state[i[1:0]] == almost_done || in_burst_state[i[1:0]] == full ) begin
												rr_in[i[1:0]] = 1;
												burst_cmd_temp[i[1:0]] = read_cmd ;
											end
										end
										else begin
											if (in_burst_state[i[1:0]] == full ) begin
												rr_in[i[1:0]] = 1;
												burst_cmd_temp[i[1:0]] = write_cmd ;
											end
										end
									end
								end
								
							end
							
							else begin  // diff active row

								if (bank_counter_act[burst_bank_add[i[1:0]]] > act_to_pre-2 && bank_counter_rd[burst_bank_add[i[1:0]]] > rd_to_pre-2  && bank_counter_wr[burst_bank_add[i[1:0]]] > wr_to_pre-2 ) begin
									rr_in[i[1:0]] = 1;
									burst_cmd_temp[i[1:0]] = precharge ;
								end
							end
						end
						else begin // no active row
							
							if (bank_counter_pre[burst_bank_add[i[1:0]]] > pre_to_act-2 && bank_group_counter_act[burst_bank_add[i[1:0]]] > act_to_act_diff_bank-2  && bank_counter_act[burst_bank_add[i[1:0]]] > act_to_act_same_bank-2 ) begin
								rr_in[i[1:0]] = 1;
								burst_cmd_temp[i[1:0]] = precharge ;
							end
						end
	
endfunction

///////////////////// burst block \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin 

rr_in = 0;

	if (global_counter_rd > burst_time + rd_to_data-2 && global_counter_wr > burst_time + wr_to_data-2 ) begin /// the bus is free	
		
		for (int i = 0; i < no_of_bursts; i++) begin 
				
			if (in_burst_state[i[1:0]] != empty && in_burst_state[i[1:0]] != returning_data) begin //  there is requests to be sent

				case (burst_last_cmd[i[1:0]])
					activate: begin
						if (in_burst_type[i[1:0]] == last_cmd_type  ||  ( ( last_cmd_type == read_cmd && global_counter_wr > wr_to_rd-2 ) && ( last_cmd_type == write && global_counter_rd > rd_to_wr-2 ) ) ) begin
							if ( bank_counter_act[burst_bank_add[i[1:0]]] > act_to_rd-2 ) begin

								if (in_burst_type[i[1:0]] == read) begin
									if (in_burst_state[i[1:0]] == almost_done || in_burst_state[i[1:0]] == full ) begin
										
										rr_in[i[1:0]] = 1;
										burst_cmd_temp[i[1:0]] = read_cmd ;
										
									end
								end
								else begin
									if (in_burst_state[i[1:0]] == full ) begin
										rr_in[i[1:0]] = 1;
										burst_cmd_temp[i[1:0]] = write_cmd ;
									end
								end
							end
						end

					end
					read_cmd: begin
						do_the_magic (i);
					end
					write_cmd: begin
						do_the_magic (i);
					end
					precharge: begin
						if (bank_counter_pre[burst_bank_add[i[1:0]]] > pre_to_act-2 && bank_group_counter_act[burst_bank_add[i[1:0]]] > act_to_act_diff_bank-2  && bank_counter_act[burst_bank_add[i[1:0]]] > act_to_act_same_bank-2 ) begin
							rr_in[i[1:0]] = 1;
							burst_cmd_temp[i[1:0]] = activate ;
						end
					end
					none: begin
						if (bank_group_counter_act[burst_bank_add[i[1:0]]] > act_to_act_diff_bank-2) begin
							rr_in[i[1:0]] = 1;
							burst_cmd_temp[i[1:0]] = activate ;
						end
					end
				endcase
			end
		end
	end

	else begin
		for (int i = 0; i < no_of_bursts; i++) begin
			burst_cmd_temp[i[1:0]] = none;		
		end
	end

end

//////////////////////////////////////////////////// made by : mohamed khaled mohamed elkhawas \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
//////////////////////////////////////////////////// 			All rights reserved				\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin // working way for round robin
	rr_out = 0;
	if (rr_in != 0) begin
		rr_temp = {rr_in,rr_in} >> start_i;	// rotate right to start from the next 1
		rr_temp = ( ~rr_temp +1'b1 ) & rr_temp ; // find first one after shifting
		rr_out = {rr_temp,rr_temp} >> (4-start_i) ; // rotational shift left 
	end
end

//////////////////////////////////////////////////// mohamed khaled mohamed elkhawas \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin
	
	for (int i = 0; i < no_of_bursts; i++) begin
		burst_cmd[i] = none;
	end

	if (rr_out != 0) begin
		for (int i = 0; i < no_of_bursts; i++) begin
			if (rr_out[i]) begin
				burst_cmd[i] = burst_cmd_temp[i];
			end
		end
	end

end

///////////////////////////////////////////////// output update \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_ff @(posedge clk) begin 
	if(rst_n) begin
		burst_cmd_o <= burst_cmd;
	end 
	else begin
		burst_cmd_o <= none;
	end
end

endmodule
