module over_flow_stopper import types_def::*;

(
	input clk,
	input rst,
	 
	input mapper_valid,
	input the_req_type, 

	input read_done,
	input  write_done,

	output logic stop_reading,
	output logic stop_writing

);

logic [read_entries_log -1 +1:0] diff_read_counter ;
logic [write_entries_log -1 +1:0] diff_write_counter ;


always_ff @(posedge clk  ) begin

	if (rst) begin
		if (mapper_valid) begin // mapper is sending req

			if (the_req_type == read ) begin
				if (read_done == 0) begin
					diff_read_counter ++;
				end	
			end

			else begin
				if (write_done == 0) begin
					diff_write_counter ++;
				end
			end
			
		end

		else begin
			if (read_done) begin
				diff_read_counter --;
			end	
			if (write_done) begin
				diff_write_counter --;
			end
		end
	end

	else begin
		diff_read_counter = 0;
		diff_write_counter = 0;
	end

end

always_comb begin 

	if (diff_read_counter == read_entries -1 +1 ) begin
		stop_reading = 1;
	end	
	else begin
		stop_reading = 0;
	end

	if (diff_write_counter == write_entries +1 ) begin
		stop_writing = 1;
	end	
	else begin
		stop_writing = 0;
	end

end


endmodule

