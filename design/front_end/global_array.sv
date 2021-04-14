
module global_array import types_def::*;

(
	input clk,    
	input rst,
	input request in_request,							// from mapper
	input logic [read_entries_log:0] in_request_index,  // from mapper
	input r_type the_mapper_req_type,  					// the mapper request type
	input mapper_enable,								// from mapper
	output logic stop_reading, 							// to mapper busy read 
	output logic stop_writing,							// to mapper busy write

	input logic [1:0] in_enable,	  					// en [0] mapper , en[1] scheduler

	input scheduler_enable,								// from scheduler
	input logic [read_entries_log:0] out_request_index, // from scheduler
	input r_type the_scheduler_req_type,  				// the scheduler request type

	input  read_done,  									// read_done read_done  write_done write_done from returner
	input  write_done,
	
	output request out_request, 						// to scheduler
	output logic sending 								// to scheduler
	
);

typedef enum logic [1:0] {idle,working,reset_state} my_states ;

my_states curr_state , next_state ; 

//		valid + address
logic [0:read_entries][ 1 + address_width : 0]					read_global_array;

//		valid + address + data
logic [0:write_entries][ 1 + address_width + data_width + 1 : 0]	write_global_array;


always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= reset_state;
	end
end

always_comb begin

	if (mapper_enable || scheduler_enable) begin
		next_state = working ;
	end	
	
	else begin
		next_state = idle ;
	end	
end

always_comb begin
	case (curr_state)
		
		working : begin
			if (mapper_enable) begin

				if (the_mapper_req_type == read) begin
					read_global_array [in_request_index] = in_request ;
				end
				else begin
					write_global_array [in_request_index] = in_request ;
				end

			end

			if (scheduler_enable) begin

				if (the_scheduler_req_type == read) begin
					out_request = read_global_array [out_request_index];
					sending = 1;
				end
				else begin
					out_request = write_global_array [out_request_index];
					sending = 1;
				end

			end

			else begin
				out_request = 0;
				sending = 0;
			end
		end
		idle : begin
			sending = 0;
			out_request = 0;
		end

		reset_state : begin
			sending = 0;
			out_request = 0;
		end

		default : begin
			
		end
	
	endcase
end

endmodule
