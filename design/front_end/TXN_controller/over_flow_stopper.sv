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

logic [read_entries_log+1:0] the_diffrence_in_read_counters ;
logic [write_entries_log+1:0] the_diffrence_in_write_counters ;


always_ff @(posedge clk  ) begin

	if (rst) begin
		if (mapper_valid) begin // mapper is sending req

			if (the_req_type == read ) begin
				if (read_done == 0) begin
					the_diffrence_in_read_counters ++;
				end	
			end

			else begin
				if (write_done == 0) begin
					the_diffrence_in_write_counters ++;
				end
			end
			
		end

		else begin
			if (read_done) begin
				the_diffrence_in_read_counters --;
			end	
			if (write_done) begin
				the_diffrence_in_write_counters --;
			end
		end
	end

	else begin
		the_diffrence_in_read_counters = 0;
		the_diffrence_in_write_counters = 0;
	end

end

always_comb begin 

	if (the_diffrence_in_read_counters == read_entries +1 ) begin
		stop_reading = 1;
	end	
	else begin
		stop_reading = 0;
	end

	if (the_diffrence_in_write_counters == write_entries +1 ) begin
		stop_writing = 1;
	end	
	else begin
		stop_writing = 0;
	end
end

endmodule
