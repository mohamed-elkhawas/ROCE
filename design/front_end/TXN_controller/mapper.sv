package types_def;

parameter

	data_width = 5'd31, 	// 32 bit
	address_width = 5'd29, 	// 30 bit
	read_entries = 63,
	read_entries_log = 5,
	write_entries = 63,
	write_entries_log = 5,

	t = 5 ;		///////////////  add the right  permutation_param_t number here

  typedef enum logic {read , write} r_type;

  typedef struct packed {
	logic [1:0] bank_group ;
	logic [1:0] bank ;
	logic [15:0] row ;
	logic [9:0] column ;	

} address_type;

  typedef struct packed {
	r_type req_type ;
	logic [data_width:0] data ;
	address_type address ;
  } request ;

  typedef struct packed {
	logic valid ;
	r_type req_type ;
	address_type address ;
	logic [data_width:0] data ;
  } waiting_request ;

endpackage



module mapper import types_def::*;
	
	(
	input clk,    	// Clock

	input rst,  	// synchronous reset active low

	input in_valid, 	// from rnic
	input request in_request, // from rnic
	output logic out_busy, // to rnic

	input stop_reading, // from global array
	input stop_writing, // from global array
	output logic  array_enable, // to global array
	output request golbal_array_out_req,// to global array
	output logic [read_entries_log:0] out_index,// to global array


	input [15:0] in_busy, // from bank
	output logic  [15:0] bank_out_valid, // to bank 
	output logic  [ 5 + 1 + 16 : 0 ] bank_out_req // to bank {index , type ,row}


	);


typedef enum logic [2:0] { idle , read_state , write_state , busy_state , reset_state } my_states ;


my_states curr_state , next_state ; 


logic [read_entries_log:0]	read_counter;
logic [write_entries_log:0]	write_counter;



waiting_request waiting_req;

address_type output_adress;




typedef struct packed {

	logic in_valid,
		stop_reading,
		stop_writing;
	logic [0:15] in_busy;
	request in_request;

} previous_input_type;

previous_input_type previous_input;


task save_the_input ();
	previous_input.in_valid = in_valid;
	previous_input.stop_reading = stop_reading;
	previous_input.stop_writing = stop_writing;
	previous_input.in_busy = in_busy;
	previous_input.in_request = in_request;
endtask


always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= reset_state;
	end
end


always_comb begin

	if (waiting_req.valid == 0 ) begin

		if (in_valid) begin
			if (in_request.req_type == read) begin
				next_state = read_state;
				save_the_input ();
			end
			
			else begin
				next_state = write_state;
				save_the_input ();
			end

		end

		else begin
			next_state = idle ;
		end		
		
	end

	else begin
		next_state = busy_state ;
	end
	
end


// scheme applier

// output_adress =  { bank_group , bank , row , column }
//						2			2		16		10

// scheme   row   	bank 	column  bank_group	column	////////// 	the mapping scheme
//			16		2			6		2			4


always_comb begin
	output_adress.bank_group 	= previous_input.in_request.address [5:4]	 ^ previous_input.in_request.address[29 - t+3 :29 - t+2 ]	;
	output_adress.bank 			= previous_input.in_request.address [13:12] ^ previous_input.in_request.address[29 - t+1 :29 - t ]	; 
	output_adress.row 			= previous_input.in_request.address [29:14]	;
	output_adress.column 		= { previous_input.in_request.address [11:6] , previous_input.in_request.address [3:0] }	;
end



always_comb begin
	case (curr_state)
		
		read_state : begin

			if ( previous_input.stop_reading == 0  &&  previous_input.in_busy [{ output_adress.bank_group , output_adress.bank}] == 0 ) begin
			
				array_enable = 1;
				golbal_array_out_req.address = output_adress;
				golbal_array_out_req.req_type = read;
				out_index = read_counter;

				bank_out_req ={ read_counter , previous_input.in_request.req_type , output_adress.row };				

				bank_out_valid =0;
				bank_out_valid[{ output_adress.bank_group , output_adress.bank}]=1;

				read_counter ++ ;
			end

			else begin
				waiting_req.valid = 1;
				waiting_req.req_type = previous_input.in_request.req_type;
				waiting_req.address =  output_adress  ;
				waiting_req.data = previous_input.in_request.data  ;

				bank_out_valid = 0;
				array_enable = 0;
			end
		end
		
		write_state : begin

			if ( previous_input.stop_writing == 0  &&  previous_input.in_busy [{ output_adress.bank_group , output_adress.bank}] == 0 ) begin

				array_enable = 1;
				golbal_array_out_req.address = output_adress;
				golbal_array_out_req.req_type = write;
				golbal_array_out_req.data = previous_input.in_request.data;
				out_index = write_counter;

				bank_out_req = { write_counter , previous_input.in_request.req_type , output_adress.row};

				bank_out_valid =0;
				bank_out_valid[{ output_adress.bank_group , output_adress.bank}]=1;

				write_counter ++ ;
			end

			else begin
				waiting_req.valid = 1;
				waiting_req.req_type = previous_input.in_request.req_type;
				waiting_req.address =  output_adress  ;
				waiting_req.data = previous_input.in_request.data  ;

				bank_out_valid = 0;
				array_enable = 0;
			end
		end
		
		busy_state : begin
			
			out_busy = 1;
			if (waiting_req.req_type == read) begin

				if ( stop_reading == 0  &&  in_busy [{ waiting_req.address.bank_group , waiting_req.address.bank}] == 0 ) begin

					array_enable = 1;
					golbal_array_out_req.address = waiting_req.address;
					golbal_array_out_req.req_type = read;
					out_index =read_counter;

					bank_out_req ={ read_counter  , waiting_req.req_type , waiting_req.address.row  };
				
					bank_out_valid =0;
					bank_out_valid[{waiting_req.address.bank_group , waiting_req.address.bank}]=1;

					read_counter ++ ;
					waiting_req.valid = 0;
				end
							
			end	

			else begin
				if ( previous_input.stop_writing == 0  &&  previous_input.in_busy [{ waiting_req.address.bank_group , waiting_req.address.bank}] == 0) begin

					array_enable = 1;
					golbal_array_out_req.address = waiting_req.address;
					golbal_array_out_req.req_type = write;
					golbal_array_out_req.data = previous_input.in_request.data;
					out_index = write_counter;

					bank_out_req ={ write_counter  , waiting_req.req_type , waiting_req.address.row  };

					bank_out_valid =0;
					bank_out_valid[{waiting_req.address.bank_group , waiting_req.address.bank}]=1;

					write_counter ++ ;
					waiting_req.valid = 0;
				end
			end		

		end
		
		idle : begin
			out_busy = 0;
			bank_out_valid = 0;
			for (int i = 0; i < 16; i++) begin
				bank_out_req[i] = 0;
			end
			array_enable = 0;
			golbal_array_out_req = 0;
			out_index = 0;
		end

		reset_state : begin
			waiting_req =0;
			read_counter = 0;
			write_counter = 0;
			out_busy = 0;
			bank_out_valid = 0;
			for (int i = 0; i < 16; i++) begin
				bank_out_req[i] = 0;
			end
			array_enable = 0;
			golbal_array_out_req = 0;
			out_index = 0;
		end

		default : begin
			waiting_req =0;
			out_busy = 0;
			bank_out_valid = 0;
			
			bank_out_req = 0;
			
			array_enable = 0;
			golbal_array_out_req = 0;
			out_index = 0;
		end
	
	endcase
end

endmodule

