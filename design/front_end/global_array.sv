

module global_array import types_def::*;

(
	input clk,    
	input rst,
	input request in_request,	// from mapper
	input logic [read_entries_log:0] in_request_index, // from mapper
	input r_type the_mapper_type,  	// the mapper request type

	input logic [1:0] in_enable,	  	// en [0] mapper , en[1] scheduler

	input logic [read_entries_log:0] out_request_index, // from scheduler
	input r_type the_scheduler_type,  	// the scheduler request type

	input [1:0] done,  			// done [0] read_done  done[1] write_done from returner
	
	output request out_request, // to scheduler
	output logic sending, 		// to scheduler
	output logic [1:0] busy_out // busy read and write
	
);

typedef enum logic [1:0] {idle,working,reset_state} my_states ;

my_states curr_state , next_state ; 

//		valid + address
logic [0:read_entries][ 1 + address_width : 0]					read_global_array;

//		valid + address + data
logic [0:write_entries][ 1 + address_width + data_width + 1 : 0]	write_global_array;

logic [read_entries_log:0] the_diffrence_in_read_counters ;
logic [write_entries_log:0] the_diffrence_in_write_counters ;

always_ff @(posedge clk  ) begin
	if (rst) begin
		if (done [0]) begin
			the_diffrence_in_read_counters --;
		end	
		if (done [1]) begin
			the_diffrence_in_write_counters --;
		end
		if (in_enable[0]) begin // mapper is sending req
			if (the_mapper_type == read) begin
				the_diffrence_in_read_counters ++;
			end
			else begin
				the_diffrence_in_write_counters ++;
			end
			
		end
		
	end
	else begin
		the_diffrence_in_read_counters = 0;
		the_diffrence_in_write_counters = 0;
	end
	
end

always_comb begin 
	if (the_diffrence_in_read_counters == read_entries) begin
				busy_out[0] = 1;
	end	
	else begin
		busy_out[0] = 0;
	end
	if (the_diffrence_in_write_counters == write_entries) begin
				busy_out[1] = 1;
	end	
	else begin
		busy_out[1] = 0;
	end

end

//////////////////////////// to be continued

always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= reset_state;
	end
end

always_comb begin

	if (in_enable != 0) begin
		next_state = working ;
	end	
	
	else begin
		next_state = idle ;
	end	
end

always_comb begin
	case (curr_state)
		
		working : begin
			
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
