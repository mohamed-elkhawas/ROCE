module global_array import types_def::*;

(
	input clk,    
	input rst,
	
	input request in_req,				// from mapper
	input logic [read_entries_log:0] in_req_index,  // from mapper
	input mapper_valid,				// from mapper

	input scheduler_valid,				// from scheduler
	input logic [read_entries_log:0] out_req_index, // from scheduler
	input r_type scheduler_req_type,  		// the scheduler request type

	output request out_req, 			// to scheduler
	output logic out_req_valid 			// to scheduler
	
);

typedef enum logic [1:0] {idle,working,reset_state} my_states ;

my_states curr_state , next_state ; 


typedef struct packed {
	logic [address_width -1:0] address ;
	logic [data_width -1:0] data ;

} request_without_type;


//		address
logic [0:read_entries -1][ address_width -1 : 0]					read_global_array;

//		 address + data
request_without_type [0:write_entries -1]					write_global_array;




typedef struct packed {
	request in_req;
	logic [read_entries_log -1:0] in_req_index;
	logic mapper_valid, scheduler_valid;
	logic [read_entries_log -1:0] out_req_index;
	r_type scheduler_req_type;

} previous_input_type;

previous_input_type previous_input;


task save_the_input ();
	previous_input.in_req <= in_req;
	previous_input.in_req_index <= in_req_index;
	previous_input.mapper_valid <= mapper_valid;
	previous_input.scheduler_valid <= scheduler_valid;
	previous_input.out_req_index <= out_req_index;
	previous_input.scheduler_req_type <= scheduler_req_type;
endtask

always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
		save_the_input ();
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
			if (previous_input.mapper_valid) begin

				if (previous_input.in_req.req_type == read) begin
					read_global_array [previous_input.in_req_index] = previous_input.in_req.address ;
				end
				else begin
					write_global_array [previous_input.in_req_index].address = previous_input.in_req.address ;
					write_global_array [previous_input.in_req_index].data = previous_input.in_req.data ;
				end

			end

			if (previous_input.scheduler_valid) begin

				if (previous_input.scheduler_req_type == read) begin
					out_req.address = read_global_array [previous_input.out_req_index];
					out_req_valid = 1;
				end
				else begin
					out_req.address = write_global_array [previous_input.out_req_index].address;
					out_req.data = write_global_array [previous_input.out_req_index].data;
					out_req_valid = 1;
				end

			end

			else begin
				out_req = 0;
				out_req_valid = 0;
			end
		end
		idle : begin
			out_req_valid = 0;
			out_req = 0;
		end

		reset_state : begin
			out_req_valid = 0;
			out_req = 0;
		end

		default : begin
			out_req_valid = 0;
			out_req = 0;
		end
	
	endcase
end

endmodule
