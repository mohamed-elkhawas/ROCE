

module global_array import types_def::*;

(
	input clk,    
	input rst,
	input request in_request,
	input [1:0] in_enable,  // en [0] mapper  en[1] scheduler
	input [1:0] done,  		// done [0] read  done[1] write
	output request out_request,
	output logic sending,
	output logic [1:0] busy_out
	
);

typedef enum logic [1:0] {idle,working,reset_state} my_states ;

my_states curr_state , next_state ; 

//		valid + address
logic [0:read_entries][ 1 + address_width : 0]					read_global_array;

//		valid + address + data
logic [0:write_entries][ 1 + address_width + data_width + 1 : 0]	write_global_array;

logic [read_entries_log:0] the_read_counter ;
logic [write_entries_log:0] the_write_counter ;

always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= reset_state;
	end
end

always_ff @(posedge clk  ) begin
	if (rst) begin
		if (done [0]) begin
			the_read_counter --;
		end	
		if (done [1]) begin
			the_write_counter --;
		end
		
	end
	else begin
		the_read_counter = 0;
		the_write_counter = 0;
	end
	
end

always_comb begin 
	if (the_read_counter == read_entries) begin
				busy_out[0] = 1;
	end	
	else begin
		busy_out[0] = 0;
	end
	if (the_write_counter == write_entries) begin
				busy_out[1] = 1;
	end	
	else begin
		busy_out[1] = 0;
	end

end
//////////////////////////// to be continued
always_comb begin

	if (in_enable != 0) begin

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
			
		end

		reset_state : begin
			sending = 0;
		end

		default : begin
			
		end
	
	endcase
end

endmodule
