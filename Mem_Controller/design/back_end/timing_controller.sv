module timing_controller import types_def::*;
	
	#( parameter no_of_bursts  = 4 )

	(
	input clk,    // Clock
	input rst_n,  // synchronous reset active low

	input burst_states_type [no_of_bursts-1:0] in_burst_state, // started_filling ,almost_done , full , empty , returning_data
	input r_type [no_of_bursts-1:0] in_burst_type,
	input address_type [no_of_bursts-1:0] in_burst_address, /// I need the row , bank and bank_group bits

	output command burst_cmd_o,	// start cmd 
	output logic [$clog2(no_of_bursts)-1:0] cmd_index_o
	);

//////////////////////////////// timing params \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
localparam  
			//max_time   = 20,
			//max_time_log = $clog2(max_time),

			//////////////////////////////same bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
			
			act_to_col  =6, // or write
			pre_to_act =6,
			act_to_act_same_bank =20,
			act_to_pre =14,
			wr_to_data =4,/////////////////////////////////////////////////////// will be sent to the other block
			rd_to_data =6,///////////// the real value is 11 //////////////////// will be sent to the other block
			rd_to_pre =3,
			wr_to_pre =6,

			////////////////////////////// bank Group \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			act_to_act_diff_bank =3,
			
			// there is col_to_col_same bank group
			// there is wr_to_rd_same bank group

			//////////////////////////////any bank \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

			rd_to_wr =5,	
			wr_to_rd =9,	
			col_to_col =2,	// column to column time

			burst_time = 8;

//////////////////////////////// declarations \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

// b for bank , bg for bank group

command [no_of_bursts-1:0]  burst_cmd_temp;
command burst_cmd;
logic [$clog2(no_of_bursts)-1:0] cmd_index;

logic [banks_no-1:0] [row_addres_len-1:0] b_active_row ; 
logic [banks_no-1:0] b_active_row_valid ;

logic [banks_no-1:0] [$clog2(act_to_act_same_bank)-1:0] b_counter_act ;
logic [banks_no-1:0] [$clog2(rd_to_data)-1:0] b_counter_rd ;
logic [banks_no-1:0] [$clog2(wr_to_pre)-1:0] b_counter_wr ;
logic [banks_no-1:0] [$clog2(pre_to_act)-1:0] b_counter_pre ; 

logic [bank_group_no-1:0] [$clog2(act_to_act_diff_bank)-1:0] bg_counter_act ;

logic [$clog2(burst_time+rd_to_data+rd_to_wr)-1:0] global_counter_rd ; // for rd to wr delay
logic [$clog2(burst_time+wr_to_data+wr_to_rd)-1:0] global_counter_wr ; // for wr to rd delay

r_type last_cmd_type;

logic [no_of_bursts-1:0][3:0] burst_bank_id; // from 0 to 15
always_comb begin 
	for (int i = 0; i < 4; i++) begin
		burst_bank_id[i] = {in_burst_address[i].bank_group , in_burst_address[i].bank};
	end
end

logic [$clog2(no_of_bursts)-1:0] start_index;
logic [no_of_bursts-1:0] round_roubin_in, round_roubin_temp, round_roubin_out;


//////////////////////////////////////////////// the state of art \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

///////////////////// updating regesters \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_ff @(posedge clk) begin

	if(rst_n) begin // updating counters and 

		for (int i = 0; i < banks_no; i++) begin

			if (i == burst_bank_id[cmd_index] && burst_cmd != none ) begin // this bank who is sending cmd
				
				start_index <= cmd_index +1;

				if (burst_cmd == activate ) begin
					b_counter_act[i] <=0;

					b_active_row[i] <= in_burst_address[cmd_index].row;
					b_active_row_valid[i] <= 1;	
				end
				else begin
					if (b_counter_act[i] != act_to_act_same_bank-1) begin
						b_counter_act[i] <= b_counter_act[i] +1 ;
					end
				end
				
				if (burst_cmd == read_cmd) begin
					b_counter_rd[i] <=0;
				end
				else begin
					if (b_counter_rd[i] != rd_to_data-1) begin
						b_counter_rd[i] <= b_counter_rd[i] +1 ;
					end
				end

				if (burst_cmd == write_cmd) begin
					b_counter_wr[i] <=0;
				end
				else begin
					if (b_counter_wr[i] != wr_to_pre-1) begin
						b_counter_wr[i] <= b_counter_wr[i] +1 ;
					end
				end

				if (burst_cmd == precharge) begin
					b_counter_pre[i] <=0;

					b_active_row_valid[i] <= 0;  
				end
				else begin
					if (b_counter_pre[i] != pre_to_act-1) begin
						b_counter_pre[i] <= b_counter_pre[i] +1 ;
					end
				end

			end
			else begin
				if (b_counter_act[i] != act_to_act_same_bank-1) begin
					b_counter_act[i] <= b_counter_act[i] +1 ;
				end
				if (b_counter_rd[i] != rd_to_data-1) begin
					b_counter_rd[i] <= b_counter_rd[i] +1 ;
				end
				if (b_counter_wr[i] != wr_to_pre-1) begin
					b_counter_wr[i] <= b_counter_wr[i] +1 ;
				end
				if (b_counter_pre[i] != pre_to_act-1) begin
					b_counter_pre[i] <= b_counter_pre[i] +1 ;
				end
			end
	
		end


		for (int i = 0; i < bank_group_no; i++) begin

			if (burst_cmd == activate &&  i == in_burst_address[cmd_index].bank_group ) begin
				bg_counter_act[i] <= 0;
			end
			else begin
				if (bg_counter_act[i] != act_to_act_diff_bank-1) begin
					bg_counter_act[i] <= bg_counter_act[i] +1 ;
				end
			end
		end

		if (burst_cmd == read_cmd) begin
			global_counter_rd <= 0;
		end
		else begin
			if (global_counter_rd != burst_time+rd_to_data+rd_to_wr-1) begin
				global_counter_rd <= global_counter_rd +1 ;
			end
		end
		if (burst_cmd == write_cmd) begin
			global_counter_wr <= 0;
		end
		else begin
			if (global_counter_wr != burst_time+wr_to_data+wr_to_rd-1) begin
				global_counter_wr <= global_counter_wr +1 ;
			end
		end

	end 

	else begin // reset

		for (int i = 0; i < banks_no; i++) begin
			b_counter_act[i] <=  0;
			b_counter_rd[i] <=  0;
			b_counter_wr[i] <=  0;
			b_counter_pre[i] <=  0;
			b_active_row_valid[i] = 0;
		end
		for (int i = 0; i < bank_group_no; i++) begin
			bg_counter_act[i] <= 0;
		end
		global_counter_rd <= 0;
		global_counter_wr <= 0;

		start_index <= 0;
		b_active_row_valid <= 0;
		last_cmd_type <= read;
		
	end
	
end


///////////////////// burst timing block \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin 

	round_roubin_in = 4'b0;

	if (global_counter_rd > burst_time + rd_to_data-2 && global_counter_wr > burst_time + wr_to_data-2 ) begin /// the bus is free	
		
		for (int i = 0; i < no_of_bursts; i++) begin 
				
			if (in_burst_state[i] != empty && in_burst_state[i] != returning_data) begin //  there is requests to be sent

				if ( b_active_row_valid[burst_bank_id[i]] == 1 ) begin // there is active row
		
					if (b_active_row[burst_bank_id[i]] == in_burst_address[i].row) begin // same active row
					
						if (in_burst_type[i] == last_cmd_type  ||  ( ( last_cmd_type == read_cmd && global_counter_rd > rd_to_wr-2 ) && ( last_cmd_type == write && global_counter_wr > wr_to_rd-2 ) ) ) begin // same type or rd_to_wr delays are done
					
							if ( global_counter_rd > burst_time + rd_to_data + col_to_col-2 && global_counter_wr > burst_time + wr_to_data + col_to_col-2 ) begin // column to column time
					
								if (b_counter_act[burst_bank_id[i]] > act_to_col-2 ) begin // activate to read or write time passed
					
									if (in_burst_type[i] == read) begin
										
										if (in_burst_state[i] == almost_done || in_burst_state[i] == full ) begin
											round_roubin_in[i] = 1;
											burst_cmd_temp[i] = read_cmd ;
										end
									
									end
									else begin
										
										if (in_burst_state[i] == full ) begin
											round_roubin_in[i] = 1;
											burst_cmd_temp[i] = write_cmd ;
										end
									
									end
								end
							end
						end	
					end
					
					else begin  // diff active row

						if (b_counter_act[burst_bank_id[i]] > act_to_pre-2 && b_counter_rd[burst_bank_id[i]] > rd_to_pre-2  && b_counter_wr[burst_bank_id[i]] > wr_to_pre-2 ) begin
							round_roubin_in[i] = 1;
							burst_cmd_temp[i] = precharge ;
						end
					end
				end
				else begin // no active row
					
					if (b_counter_pre[burst_bank_id[i]] > pre_to_act-2 && bg_counter_act[in_burst_address[i].bank_group] > act_to_act_diff_bank-2  && b_counter_act[burst_bank_id[i]] > act_to_act_same_bank-2 ) begin
						round_roubin_in[i] = 1;
						burst_cmd_temp[i] = activate ;
					end
				end
				
			end
		end
	end

	else begin
		for (int i = 0; i < no_of_bursts; i++) begin
			burst_cmd_temp[i] = none;		
		end
	end

end

//////////////////////////////////////////////////// made by : mohamed khaled mohamed elkhawas \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
///////////////////////////////////////////////////  			All rights reserved				\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin // working way for round robin
	round_roubin_out = 4'b0;
	if (round_roubin_in != 0) begin
		round_roubin_temp = {round_roubin_in,round_roubin_in} >> start_index;	// rotate right to start from the next 1
		round_roubin_temp = ( ~round_roubin_temp +1'b1 ) & round_roubin_temp ; // find first one after shifting
		round_roubin_out = {round_roubin_temp,round_roubin_temp} >> (4-start_index) ; // rotational shift left 00010001
	end
end

//////////////////////////////////////////////////// 			All rights reserved				\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin // continue round roubin

	for (int i = 0; i < no_of_bursts; i++) begin
		if (round_roubin_out[i]) begin
			burst_cmd = burst_cmd_temp[i];
			cmd_index = i;
		end
	end

	if (round_roubin_out == 0) begin
		burst_cmd = none;
		cmd_index = 0;
	end

end


///////////////////////////////////////////////// output update \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
always_ff @(posedge clk) begin 
	
	if(rst_n) begin
		burst_cmd_o <= burst_cmd;
		cmd_index_o <= cmd_index;
	end 
	
	else begin
		burst_cmd_o = none;
		cmd_index_o = 0;
	end

end
///////////////////////////////////////////////// output update \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

endmodule