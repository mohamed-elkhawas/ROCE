module returner  import types_def::*;

	#( parameter data_Width = 5'd31 

	)

	(
	input clk,    	// Clock
	input rst,  	// synchronous reset active low
	input valid,
	input the_type,
	input [ data_Width  : 0 ] in_data,
	input [ read_entries_log : 0 ] index,

	output logic write_done,
	output logic read_done,
	output logic  [ data_Width : 0 ] out_data

	);


typedef enum logic [1:0] { idle , working ,reset_s } state ;

state curr_state , next_state ; 


logic [5:0]	read_counter;
logic [5:0]	write_counter;


//		valid + address
logic [0:63][ 1 + data_Width : 0]	read_return_array;

//		valid + address + data
logic [0:63]						write_return_array;



always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= reset_s;
	end
end


always_comb begin

	if ( read_return_array[read_counter][0] == 1 || write_return_array[write_counter] == 1 || valid) begin
		next_state = working ;
	end
	
	else begin
		next_state = idle ;
	end	
end


always_comb begin 
	case (curr_state)
		
		working : begin

			if (valid) begin
				if (the_type == read) begin
					read_return_array [index] = in_data;
				end
				else begin
					write_return_array [index] = 1;
				end
			end

			if (read_return_array [read_counter][0] == 1 ) begin
				out_data = read_return_array [read_counter][data_Width:1] ;
				read_done = 1 ;
				read_return_array [read_counter][0] = 0;
				read_counter ++ ;
			end

			else begin
				read_done = 0;
				out_data = 0;
			end

			if (write_return_array [write_counter] == 1 ) begin
				write_done = 1 ;
				write_return_array [write_counter] = 0 ;
				write_counter ++ ;
			end

			else begin
				write_done = 0;
			end
		end
		
		idle : begin
			write_done = 0 ;
			read_done = 0 ;
			out_data = 0;
		end

		reset_s : begin
			
			read_counter = 0;
			write_counter = 0;
			write_done = 0 ;
			read_done = 0 ;
			out_data = 0;
		end

		default : begin
			write_done = 0 ;
			read_done = 0 ;
			out_data = 0;
		end
	
	endcase
end

endmodule

