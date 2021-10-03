module returner  import types_def::*;

	#( parameter data_width  = 16 

	)

	(
	input clk,    	// Clock
	input rst_n,  	// synchronous reset active low
	input valid,
	input the_type,
	input [ data_width -1  : 0 ] data_in,
	input [ read_entries_log -1 : 0 ] index,

	output logic write_done,
	output logic read_done,
	output logic  [ data_width -1 : 0 ] data_out

	);


logic [read_entries_log -1:0]	read_counter;
logic [write_entries_log -1:0]	write_counter;


//		valid + data
logic [0:63][ 1 + data_width -1 : 0]	read_return_array;

//		valid 
logic [0:63]						write_return_array;


always_ff @(posedge clk ) begin
	
	if(rst_n) begin
		
		if (valid) begin
			
			if (the_type == read ) begin// new read
				if (index == read_counter) begin
					read_done <= 1;
					read_counter <= read_counter + 1;
					data_out <= data_in;
				end
				else begin
					read_return_array [index][ data_width -1  : 0 ] <= data_in;
					read_return_array [index][ data_width] <= 1'b1 ;

					if (read_return_array [read_counter][data_width] == 1) begin
						read_done <= 1;
						read_counter <= read_counter + 1;
						data_out <= data_in;
					end
					else begin 
						read_done <= 0;
						data_out <= 0;
					end 

					if (write_return_array [write_counter] == 1) begin
						write_done <= 1;
						write_counter <= write_counter + 1;
					end
					else write_done <= 0;

				end
			end

			else begin // new write
				if (index == write_counter) begin
					write_done <= 1;
					write_counter <= write_counter + 1;
				end
				else begin
					write_return_array [index] <= 1'b1 ;

					if (read_return_array [read_counter][data_width] == 1) begin
						read_done <= 1;
						read_counter <= read_counter + 1;
						data_out <= data_in;
					end
					else begin 
						read_done <= 0;
						data_out <= 0;
					end 

					if (write_return_array [write_counter] == 1) begin
						write_done <= 1;
						write_counter <= write_counter + 1;
					end
					else write_done <= 0;
				end
			end
		end

		else begin
			if (read_return_array [read_counter][data_width] == 1) begin
				read_done <= 1;
				read_counter <= read_counter + 1;
				data_out <= data_in;
			end
			else begin 
				read_done <= 0;
				data_out <= 0;
			end 

			if (write_return_array [write_counter] == 1) begin
				write_done <= 1;
				write_counter <= write_counter + 1;
			end
			else write_done <= 0;
		end
		
	end 
	else begin
		read_done <= 0;
		write_done <= 0;
		data_out <= 0;
		read_counter <= 0;
		write_counter <= 0;
		read_return_array <= 0;
		write_return_array <= 0;
	end
end


endmodule
