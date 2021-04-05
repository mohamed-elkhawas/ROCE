module returner 
	#( parameter

		data_width = 5'd31, 	// 32 bit
		address_width = 5'd29 	// 30 bit
	)


	(
	input clk,    	// Clock
	input rst,  	// synchronous reset active low
	output write_done,
	output read_done,
	output logic  [ data_width : 0 ] data

	);


typedef enum logic { idle , working } state ;

state curr_state , next_state ; 


logic [5:0]	read_counter;
logic [5:0]	write_counter;


//		valid + address
logic [0:63][ 1 + data_width : 0]	read_return_array;

//		valid
logic [0:63]				write_return_array;



always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= idle;
		
		read_counter <= 0;
		write_counter <= 0;
		
		read_done <= 0;
		write_done <= 0;
		data <= 0;		
	end
end


always_comb begin

	if ( read_return_array[read_counter][0] == 1 || write_return_array[write_counter] == 1 ) begin
		next_state = working ;
	end
	
	else begin
		next_state = idle ;
	end	
end


always_comb begin //////////////////////////  don't know if it will work ///////////////////////////////
	case (curr_state)
		
		working : begin

			if (read_return_array [read_counter][0] == 1 ) begin
				data = read_return_array [read_counter][data_width:1] ;
				read_done = 1 ;
				read_return_array [read_counter][0] = 0;
				read_counter ++ ;
			end

			else begin
				read_done = 0;
				data = 0;
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
			data = 0;
		end

		default : begin
			write_done = 0 ;
			read_done = 0 ;
			data = 0;
		end
	
	endcase
end

endmodule
