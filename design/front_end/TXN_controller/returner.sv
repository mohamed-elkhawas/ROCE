module returner_v2  import types_def::*;

	#( parameter data_Width = 5'd31 

	)

	(
	input clk,    	// Clock
	input rst,  	// synchronous reset active low
	input valid,
	input the_type,
	input [ data_Width  : 0 ] data_in,
	input [ read_entries_log : 0 ] index,

	output logic write_done,
	output logic read_done,
	output logic  [ data_Width : 0 ] data_out

	);


typedef enum logic [1:0] { idle , working ,reset_s } state ;

state curr_state , next_state ; 


logic [5:0]	read_counter;
logic [5:0]	write_counter;


//		valid + data
logic [0:63][ 1 + data_Width : 0]	read_return_array;

//		valid 
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

					if ( read_counter == index ) begin
						data_out = data_in ;
						read_done = 1 ;
						read_counter ++ ;
					end

					else begin
						read_done = 0;
						data_out = 0;
						read_return_array [index] = { 1 , data_in };
					end

				end
				
				else begin
					if ( write_counter == index ) begin
						write_done = 1 ;
						write_counter ++ ;
					end

					else begin
						write_done = 0;
						write_return_array [index] = 1;
					end	
				end
			end

			else begin
				if (read_return_array [read_counter][0] == 1) begin
					data_out = read_return_array [read_counter][data_Width:0];
					read_done =1;
					read_counter ++ ;
				end
				else begin
					data_out = 0;
					read_done = 0;
				end
				if (write_return_array [write_counter] == 1) begin
					write_done = 1 ;
					write_return_array [write_counter] = 0 ;
					write_counter ++ ;					
				end
				else begin
					write_done = 0;
				end
			end
		end
		
		idle : begin
			write_done = 0 ;
			read_done = 0 ;
			data_out = 0;
		end

		reset_s : begin
			read_counter = 0;
			write_counter = 0;
			write_done = 0 ;
			read_done = 0 ;
			data_out = 0;
		end

		default : begin
			write_done = 0 ;
			read_done = 0 ;
			data_out = 0;
		end
	
	endcase
end

endmodule

