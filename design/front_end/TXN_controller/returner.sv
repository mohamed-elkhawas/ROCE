module returner  import types_def::*;

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


typedef enum logic [1:0] { idle , working_with_new_req ,working_with_old_req ,reset_s } state ;

state curr_state , next_state ; 


logic [5:0]	read_counter;
logic [5:0]	write_counter;


//		valid + data
logic [0:63][ 1 + data_Width : 0]	read_return_array;

//		valid 
logic [0:63]						write_return_array;


typedef struct packed {
	logic the_type ;
	logic [ data_Width  : 0 ] data_in;
	logic [ read_entries_log : 0 ] index;
	logic valid;

} previous_input_type;

previous_input_type previous_input;


task save_the_input ();
	previous_input.the_type <= the_type;
	previous_input.data_in <= data_in;
	previous_input.index <= index;
	previous_input.valid <= valid;
endtask


logic read_counter_up , write_counter_up;


always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
		save_the_input ();
		if(read_counter_up) begin
			read_counter ++;
		end
		if(write_counter_up) begin
			write_counter ++;
		end
	end 
	else begin
		curr_state <= reset_s;
		read_counter <= 0;
		write_counter <= 0;
	end
end


always_comb begin

	case (curr_state)
		idle: begin
			if (valid) begin
				next_state = working_with_new_req ;
			end
			else begin
					next_state = idle ;
			end
		end
		reset_s: begin
			if (valid) begin
				next_state = working_with_new_req ;
			end
			else begin
					next_state = idle ;
			end
		end
		working_with_new_req: begin
			if (read_return_array[read_counter][0] == 1 || write_return_array[write_counter] == 1 ) begin
				next_state = working_with_old_req ;
			end
			else begin
				if (valid) begin
					next_state = working_with_new_req ;
				end
				else begin
					next_state = idle ;
				end
			end
		end
		working_with_old_req: begin
			if (read_return_array[read_counter][0] == 1 || write_return_array[write_counter] == 1 ) begin
				next_state = working_with_old_req ;
			end
			else begin
				if (valid) begin
					next_state = working_with_new_req ;
				end
				else begin
					next_state = idle ;
				end
			end
		end

		default : next_state = idle ;
	endcase
end




always_comb begin 

	read_counter_up = 0;
	write_counter_up = 0;

	case (curr_state)
		
		working_with_new_req : begin
			if (previous_input.the_type == read) begin
				if ( read_counter == previous_input.index ) begin
					data_out = previous_input.data_in ;
					read_done = 1 ;
					read_counter_up = 1;
				end

				else begin
					read_done = 0;
					data_out = 0;
					read_return_array [previous_input.index] = { 1 , previous_input.data_in };
				end					
			end
				
			else begin
				if ( write_counter == previous_input.index ) begin
					write_done = 1 ;
					write_counter_up = 1;
				end

				else begin
					write_done = 0;
					write_return_array [previous_input.index] = 1;
				end	
			end
		end

		working_with_old_req : begin
			if (read_return_array [read_counter][0] == 1) begin
				data_out = read_return_array [read_counter][data_Width:0];
				read_done =1;
				read_counter_up = 1;
			end
			else begin
				data_out = 0;
				read_done = 0;
			end
			if (write_return_array [write_counter] == 1) begin
				write_done = 1 ;
				write_return_array [write_counter] = 0 ;
				write_counter_up = 1;					
			end
			else begin
				write_done = 0;
			end

			if (previous_input.the_type == read) begin
				read_return_array [previous_input.index] = { 1 , previous_input.data_in };
			end
				
			else begin
				write_return_array [previous_input.index] = 1;
			end
		end
		
		idle : begin
			write_done = 0 ;
			read_done = 0 ;
			data_out = 0;
		end

		reset_s : begin
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
