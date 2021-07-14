module burst_handler import types_def::*;

	#( parameter no_of_bursts  = 4 )

	(
	input clk,    // Clock
	input rst_n,  // synchronous reset active low

	//////////////////////////////////////////////////////////////// timing_controller
	output burst_states_type [no_of_bursts:0] out_burst_state,
	output r_type [no_of_bursts:0] out_burst_type,
	output logic [address_width-1:4] [no_of_bursts:0] out_burst_address,

	input command in_burst_cmd,
	input [$clog2(no_of_bursts)-1:0] in_cmd_index,
	
	/////////////////////////////////////////////////////////////// banks arbiter
	output logic [$clog2(no_of_bursts) :0]  empty_bursts_counter,

	input arbiter_valid,
	input address_type in_req_address,
	input [data_width -1:0] arbiter_data,
	input [read_entries_log -1:0] arbiter_index,
	input r_type arbiter_type,
	
	/////////////////////////////////////////////////////////////// memory interface
	output logic CS_n                ,// Chip Select -> active low
	output logic [13:0] CA           ,// Command / Address Port   
	output logic CAI                 ,// Command / Address inversion
	output logic [2:0] DM_n          ,// Data Mask -> byte based 
	inout logic [15:0] DQ           ,// Data Port  
	inout logic [2:0] DQS_t , DQS_c ,// Data Strobes (diff pair) // ~Data Strobes (diff pair)
 	inout logic ALERT_n             , // CRC/Parity error flag

	/////////////////////////////////////////////////////////////// returner interface
	output logic returner_valid,
	output r_type returner_type,
	output logic [data_width-1:0] returner_data,
	output logic [read_entries_log -1:0] returner_index
	//input test

	);


parameter wr_to_data =8, // on clk not posedge clk
		  rd_to_data =11,
		  burst_length = 16;

typedef struct packed {
	logic [1:0] bank_group ;
	logic [1:0] bank ;
	logic [15:0] row ;
	logic [9-4:0] column ;	

} burst_address_type;
	
	
typedef struct packed {
	r_type the_type;
	burst_states_type state;
	burst_address_type address ;
	logic [burst_length-1:0][read_entries_log -1:0] index ;
	logic [burst_length-1:0][data_width -1:0] data ;
	logic [burst_length-1:0] mask;

	} burst_storage;

burst_storage [no_of_bursts-1:0] burst;

logic [3:0] new_burst_counter;

logic [$clog2(no_of_bursts) -1:0] in_burst , older_in_burst , out_burst;

logic new_burst_flag , return_req;

logic [$clog2(no_of_bursts) -1:0][$clog2(burst_lentgh) -1:0] burst_data_counter;

logic [burst_length-1:0] first_one_in_mask;

logic [$clog2(burst_lentgh)-1:0] first_one_id;

logic [$clog2(rd_to_data)-1:0] data_wait_counter;

logic [$clog2(no_of_bursts) -1:0] cmd_burst_id;

command cmd_to_send;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// there are 3 main blocks with 1 storage element shared between them													//
// input requests from arbiter to storage and to timing cont. 	// turn timing cmds  to memory // return reqto returner //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// updating burst_storage  //dealing with arbiter // outputs burst states, address and type


always_comb begin // calculate which burst and new_burst_flag
	
	if (arbiter_valid) begin

		if ( burst[in_burst].state == full || empty_bursts_counter == 4  || burst[in_burst].address != in_req_address[address_width-1:4] || burst[in_burst].the_type != arbiter_type  ) begin /////////////////// 	new burst 

			new_burst_flag =1;

			if (burst[0].state == empty) begin//choose the first empty burst// if no_of_bursts is not 4 change here 
				in_burst = 0;
			end
			else begin
				if (burst[1].state == empty) begin
					in_burst = 1;
				end
				else begin
					if (burst[2].state == empty) begin
						in_burst = 2;
					end
					else in_burst = 3;
				end
			end//////////////////////////////////////////////////////////// that is enough changing ;)
		end	
		else new_burst_flag =0;	
	end
	else new_burst_flag =0;
end


always_ff @(posedge clk) begin // handels storage input states and requests indices 

	older_in_burst <= in_burst;

	if(rst_n) begin
		
		if (arbiter_valid) begin

			if (new_burst_flag) begin

				if ( !(return_req && first_one_in_mask == 0) ) begin // if we did not free one burst
					empty_bursts_counter <= empty_bursts_counter -1;
				end
				
				if (burst[older_in_burst].state == started_filling || burst[older_in_burst].state == almost_done) begin // old one is full
					burst[older_in_burst].state <= full;  out_burst_state[older_in_burst] <= full;
				end

				new_burst_counter <= 0;

				burst[in_burst].state <= started_filling; 	out_burst_state[in_burst] <= started_filling;
				burst[in_burst].address <= in_req_address[address_width-1:4]; out_burst_address[in_burst] <= in_req_address[address_width-1:4];
				burst[in_burst].the_type <= arbiter_type; out_burst_type[in_burst] <= arbiter_type;
				// the column last 4 bits are the req place in the burst
				if (arbiter_type == write) begin
					burst[in_burst].data[in_req_address.column[3:0]] <= arbiter_data; 
				end
				burst[in_burst].index[in_req_address.column[3:0]] <= arbiter_index;
				burst[in_burst].mask[in_req_address.column[3:0]] <= 1;

			end
			else begin // continue filling old burst
				new_burst_counter <= new_burst_counter +1;
				if (new_burst_counter == 7) begin
					burst[in_burst].state <= almost_done; out_burst_state[in_burst] <= almost_done;
				end
				if (arbiter_type == write) begin
					burst[in_burst].data[in_req_address.column[3:0]] <= arbiter_data; 
				end
				burst[in_burst].index[in_req_address.column[3:0]] <= arbiter_index;
				burst[in_burst].mask[in_req_address.column[3:0]] <= 1;
			end

		end
		else begin// end the current burst // without starting new one
			if (burst[in_burst].state == started_filling || burst[in_burst].state == almost_done) begin
				burst[in_burst].state <= full; out_burst_state[in_burst] <= full;
			end
		end

	end
	else begin // reset
		empty_bursts_counter <= 4;
		for (int i = 0; i < no_of_bursts; i++) begin
			burst[i].state <= empty;
			burst[i].mask <= 0;
			out_burst_address[i] <= 0;
		end
	end
end


// returning data to the returner

always_comb begin 
	
	return_req = 0;
	
	if (burst[0].state == returning_data) begin//choose the first returning data burst// if no_of_bursts is not 4 change here 
		out_burst = 0; return_req = 1;
	end
	else begin
		if (burst[1].state == returning_data) begin
			out_burst = 1; return_req = 1;
		end
		else begin
			if (burst[2].state == returning_data) begin
				out_burst = 2; return_req = 1;
			end
			else begin
				if (burst[3].state == returning_data) begin
					out_burst = 3; return_req = 1;
				end
			end
		end
	end//////////////////////////////////////////////////////////// that is enough changing ;)

	first_one_in_mask = ( ~burst[out_burst].mask +1'b1 ) & burst[out_burst].mask ;
	
	for (int i = 0; i < burst_length; i++) begin
		if (first_one_in_mask[i]) begin
			first_one_id = i;
		end
	end

end

always_ff @(  posedge clk ) begin
	
	if(rst_n) begin
		
		if (return_req) begin

			if (first_one_in_mask != 0) begin // didn't finish returning

				if (burst_data_counter[out_burst] >= first_one_id) begin // recieved req data or sent the write 
					
					returner_valid <= 1;
					returner_type <= burst[out_burst].the_type;
					returner_index <= burst[out_burst].index[first_one_id];
					returner_data <= burst[out_burst].data[first_one_id];
					burst[out_burst].mask[first_one_id] <= 0;

				end

				else returner_valid <= 0; 
			end
			
			else begin // finished returning

				returner_valid <= 0;
				
				burst[out_burst].state <= empty;
				if (!new_burst_flag) begin
					empty_bursts_counter <= empty_bursts_counter +1;
				end

			end
		end
	end 

	else begin // reset
		returner_valid <= 0;
	end
end

/*
// testing returning data
always_ff @(posedge clk ) begin
	if (test) begin
		for (int i = 0; i < no_of_bursts; i++) begin
			burst_data_counter = 15;
			burst[i].state = returning_data;
			burst[i].mask = 0;
			burst[i].the_type = write;
			burst[i].index[0] = 8;
			burst[i].index[2] = 7;
			burst[i].index[9] = 9;
			burst[i].mask[0] = 1;
			burst[i].mask[2] = 1;
			burst[i].mask[9] = 1;
		end
	end
end
*/


//////////// important note: returning_data state will start on read after recieving data from the memory on write after writing the data

//////////////////////////////// ddr5 commands\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

// CID3 = 0

task ddr5_activate_p1(cmd_burst_id);
	CS_n <= 1'b0 ; // Chip Select -> active low
	CA <= {2'b00,burst[cmd_burst_id].address.row[3:0],burst[cmd_burst_id].address.bank,burst[cmd_burst_id].address.bank_group,3'b000};
endtask 
task ddr5_read_p1(cmd_burst_id);
	CS_n <= 1'b0;
	CA <= {5'b10111,burst_length,burst[cmd_burst_id].address.bank,burst[cmd_burst_id].address.bank_group,3'b000};
endtask 
task ddr5_write_p1(cmd_burst_id);
	CS_n <= 1'b0;
	CA <= {5'b10110,burst_length,burst[cmd_burst_id].address.bank,burst[cmd_burst_id].address.bank_group,3'b000};
endtask 
task ddr5_precharge_p1(cmd_burst_id);
	CS_n <= 1'b0;
	CA <= {1'b1,5'b11011,1'b0,burst[cmd_burst_id].address.bank,burst[cmd_burst_id].address.bank_group,1'b0};            
endtask 

task ddr5_activate_p2(cmd_burst_id);
	CS_n <= 1'b1 ; // Chip Select -> active low
	CA <= {burst[cmd_burst_id].address.row[15:4],1'b0};
endtask 
task ddr5_read_p2(cmd_burst_id);
	CS_n <= 1'b1;
	CA <= {1'b0,burst[cmd_burst_id].address.column,1'b0,1'b0,&burst[cmd_burst_id].mask,1'b0,1'b0};
endtask 
task ddr5_write_p2(cmd_burst_id);
	CS_n <= 1'b1;
	CA <= {1'b0,burst[cmd_burst_id].address.column,1'b0,1'b0,2'b00,1'b0};
endtask 
task ddr5_precharge_p2(cmd_burst_id);
	//no part2
endtask 

task ddr5_write_data(cmd_burst_id,counter);
	if (burst[cmd_burst_id].mask[counter]) begin
		DQ <= burst[cmd_burst_id].data[counter];
	end
	
endtask 
task ddr5_read_data(cmd_burst_id,counter);
	if (burst[cmd_burst_id].mask[counter]) begin
   		burst[cmd_burst_id].data <= DQ   ;
	end	
endtask 

//////////////////////////////// ddr5 commands\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


always_ff @( clk ) begin ///////////////// memory interface 

	if(rst_n) begin
		
		if (in_burst_cmd == none) begin // all cmds are none
		
			if (cmd_to_send == read_cmd || cmd_to_send == write_cmd) begin
				
				if (data_wait_counter != rd_to_data ) begin
					data_wait_counter <= data_wait_counter +1;
				end

			end
			
			
			if (data_wait_counter >= rd_to_data && cmd_to_send == read_cmd) begin
				
				if (data_wait_counter == rd_to_data) begin
					burst[cmd_burst_id].state <= returning_data;
				end

				ddr5_read_data(cmd_burst_id,burst_data_counter[cmd_burst_id]);
				burst_data_counter[cmd_burst_id] <= burst_data_counter[cmd_burst_id] +1;				
			
			end

			if (data_wait_counter >= wr_to_data && cmd_to_send == write_cmd) begin

				if (data_wait_counter == wr_to_data) begin
					burst[cmd_burst_id].state <= returning_data;
				end

				ddr5_write_data(cmd_burst_id,burst_data_counter[cmd_burst_id]);
				burst_data_counter[cmd_burst_id] <= burst_data_counter[cmd_burst_id] +1;				
			
			end

		end
		else begin
			
			if (clk) begin // if (clk_n) begin // to make the memory interface command start at posedge 

				burst_data_counter[cmd_burst_id] <= 0;
				data_wait_counter <= 0;

				cmd_burst_id <= in_cmd_index;
				cmd_to_send <= in_burst_cmd;

				case (cmd_to_send)
					activate:ddr5_activate_p1(cmd_burst_id);
					read_cmd:ddr5_read_p1(cmd_burst_id);
					write_cmd:ddr5_write_p1(cmd_burst_id);
					precharge:ddr5_precharge_p1(cmd_burst_id);
				endcase
			end

			else begin
				data_wait_counter <= 1;
				case (cmd_to_send)
					activate:ddr5_activate_p2(cmd_burst_id);
					read_cmd:ddr5_read_p2(cmd_burst_id);
					write_cmd:ddr5_write_p2(cmd_burst_id);
					precharge:ddr5_precharge_p2(cmd_burst_id);
				endcase

			end 

		end			
	end 
	else begin
		burst_data_counter <= 0;
		data_wait_counter <= 0;
		cmd_burst_id <= 0;
	end
end


endmodule

// // to make the memory interface command start at posedge 

// logic clk_n;

// always_ff @( clk ) begin
// clk_n <= ~clk;
// end
// /////////////////////////////////////
