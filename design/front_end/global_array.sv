
module global_array import types_def::*;

(
	input clk,    
	input rst,
	
	input request in_request,							// from mapper
	input logic [read_entries_log:0] in_request_index,  // from mapper
	input mapper_valid,									// from mapper
	output logic stop_reading, 							// to mapper busy read 
	output logic stop_writing,							// to mapper busy write

	input scheduler_valid,								// from scheduler
	input logic [read_entries_log:0] out_request_index, // from scheduler
	input r_type the_scheduler_req_type,  				// the scheduler request type

	output request out_request, 						// to scheduler
	output logic out_request_valid 								// to scheduler
	
);

typedef enum logic [1:0] {idle,working,reset_state} my_states ;

my_states curr_state , next_state ; 


typedef struct packed {
	logic [address_width:0] address ;
	logic [data_width:0] data ;

} request_without_type;


//		address
logic [0:read_entries][ address_width : 0]					read_global_array;

//		 address + data
request_without_type [0:write_entries]					write_global_array;


always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= reset_state;
	end
end

always_comb begin

	if (mapper_valid || scheduler_valid) begin
		next_state = working ;
	end	
	
	else begin
		next_state = idle ;
	end	
end

always_comb begin
	case (curr_state)
		
		working : begin
			if (mapper_valid) begin

				if (in_request.req_type == read) begin
					read_global_array [in_request_index] = in_request.address ;
				end
				else begin
					write_global_array [in_request_index].address = in_request.address ;
					write_global_array [in_request_index].data = in_request.data ;
				end

			end

			if (scheduler_valid) begin

				if (the_scheduler_req_type == read) begin
					out_request.address = read_global_array [out_request_index];
					out_request_valid = 1;
				end
				else begin
					out_request.address = write_global_array [out_request_index].address;
					out_request.data = write_global_array [out_request_index].data;
					out_request_valid = 1;
				end

			end

			else begin
				out_request = 0;
				out_request_valid = 0;
			end
		end
		idle : begin
			out_request_valid = 0;
			out_request = 0;
		end

		reset_state : begin
			out_request_valid = 0;
			out_request = 0;
		end

		default : begin
			out_request_valid = 0;
			out_request = 0;
		end
	
	endcase
end

endmodule