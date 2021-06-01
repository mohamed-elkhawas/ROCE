module memory_s_best_friend import types_def::*;

	#( parameter no_of_bursts  = 4 )

	(
	input clk,    // Clock
	input rst_n,  // synchronous reset active low

	//////////////////////////////////////////////////////////////// timing_controller
	output burst_states_type [no_of_bursts:0] out_burst_state,
	output r_type [no_of_bursts:0] out_burst_type,
	output logic [address_width-1:4] [no_of_bursts:0] out_burst_address,

	input command [no_of_bursts-1:0] in_burst_cmd,
	
	/////////////////////////////////////////////////////////////// banks arbiter
	output logic start_new_burst,

	input arbiter_valid,
	input address_type in_req_address,
	input [data_width -1:0] arbiter_data,
	input [read_entries_log -1:0] arbiter_index,
	input r_type arbiter_type
	
	/////////////////////////////////////////////////////////////// memory interface




	/////////////////////////////////////////////////////////////// returner interface


	);


typedef struct packed {
	r_type the_type;
	burst_states_type state;
	logic [address_width-1:4] address ;
	logic [15:0] index ;
	logic [15:0][data_width -1:0] data ;

	} burst_storage;

burst_storage [no_of_bursts-1:0] burst;

logic [3:0] new_burst_counter;

logic [$clog2(no_of_bursts) -1:0] which_burst ;

logic [$clog2(no_of_bursts) :0]  empty_bursts_counter;


parameter wr_to_data =8, // on clk not posedge clk
		  rd_to_data =11;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// there are 3 main blocks with 1 storage element shared between them													//
// input requests from arbiter to storage and to timing cont. 	// turn timing cmds  to memory // return reqto returner //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// updating burst_storage  //dealing with arbiter // outputs burst states, address and type

always_ff @(posedge clk) begin 

	if(rst_n) begin
		
		if (arbiter_valid) begin

			if ( empty_bursts_counter == 4  || burst[which_burst].address != in_req_address[address_width-1:4] || burst[which_burst].the_type != arbiter_type  ) begin /////////////////// 	new burst 

				if (empty_bursts_counter == 1) begin
					start_new_burst <= 0;
				end
				
				empty_bursts_counter <= empty_bursts_counter -1;

				if (burst[which_burst].state == started_filling || burst[which_burst].state == almost_done) begin // old one is full
					burst[which_burst].state <= full;  out_burst_state[which_burst] <= full;
				end

				if (burst[0].state == empty) begin//choose the first empty burst// if no_of_bursts is not 4 change here 
					which_burst <= 0;
				end
				else begin
					if (burst[1].state == empty) begin
						which_burst <= 1;
					end
					else begin
						if (burst[2].state == empty) begin
							which_burst <= 2;
						end
						which_burst <= 3;
					end
				end//////////////////////////////////////////////////////////// that is enough changing ;)

				new_burst_counter <= 0;

				burst[which_burst].state <= started_filling; 	out_burst_state[which_burst] <= started_filling;
				burst[which_burst].address <= in_req_address[address_width-1:4]; out_burst_address[which_burst] <= in_req_address[address_width-1:4];
				burst[which_burst].the_type <= arbiter_type; out_burst_type[which_burst] <= arbiter_type;
				// the column last 4 bits are the req place in the burst
				burst[which_burst].data[in_req_address.column[3:0]] <= arbiter_data; 
				burst[which_burst].index[in_req_address.column[3:0]] <= arbiter_index;

			end
			
			else begin // continue filling old burst
				
				new_burst_counter <= new_burst_counter +1;
				if (new_burst_counter == 7) begin
					burst[which_burst].state <= almost_done; out_burst_state[which_burst] <= almost_done;
				end

				burst[which_burst].data[in_req_address.column[3:0]] <= arbiter_data; 
				burst[which_burst].index[in_req_address.column[3:0]] <= arbiter_index;
			end		
		end
		
		else begin // end the current burst // without starting new one
			if (burst[which_burst].state == started_filling || burst[which_burst].state == almost_done) begin
				burst[which_burst].state <= full; out_burst_state[which_burst] <= full;
			end
		end		
	
	end
	
	else begin // reset
		start_new_burst <= 1;
		empty_bursts_counter <= 4;
		which_burst <= 0;
		for (int i = 0; i < no_of_bursts; i++) begin
			burst[i].state <= empty;
			out_burst_address[i] <= empty;
		end

	end
end




/*

always_comb begin // deals with the input from timing controller to tell the memory interface what to do 
	for (int i = 0; i < no_of_bursts; i++) begin
		case (in_burst_cmd[i])
	
			default : 
		endcase
	end		
end


always_ff @( clk ) begin ///////////////// memory interface 
	if(rst_n) begin
		
	end 
	else begin
		
	end
end

*/

endmodule
