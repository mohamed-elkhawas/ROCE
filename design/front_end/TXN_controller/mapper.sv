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


	input [0:15] in_busy, // from bank
	output logic  [0:15] bank_out_valid, // to bank 
	output logic  [0:15] [ 5 + 1 + 16 : 0 ] bank_out_req // to bank


	);


typedef enum logic [2:0] { idle , read_state , write_state , busy_state , reset_state } my_states ;


my_states curr_state , next_state ; 


logic [read_entries_log:0]	read_counter;
logic [write_entries_log:0]	write_counter;



waiting_request 	waiting_req;

address_type output_adress;

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
			end
			
			else begin
				next_state = write_state;
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

// scheme   row   	bank 	column  bank_group	column	////////// 	the first scheme
//			16		2			6		2			4


// scheme   row   column	bank 	column  bank_group	column	////////// 	the second scheme
//			16		4		2			2		2			4




always_comb begin
	output_adress.bank_group 	= in_request.address [5:4]	 ^ in_request.address[29 - t+3 :29 - t+2 ]	;
	output_adress.bank 			= in_request.address [13:12] ^ in_request.address[29 - t+1 :29 - t ]	; 
	output_adress.row 			= in_request.address [29:14]	;
	output_adress.column 		= { in_request.address [11:6] , in_request.address [3:0] }	;
end



always_comb begin
	case (curr_state)
		
		read_state : begin

			if ( stop_reading == 0  &&  in_busy [{ output_adress.bank_group , output_adress.bank}] == 0 ) begin
			
				array_enable = 1;
				golbal_array_out_req.address = output_adress;
				golbal_array_out_req.req_type = read;				
				
				for (int i = 0; i < 16; i++) begin
					if (i == { output_adress.bank_group , output_adress.bank} ) begin
						bank_out_req [i] ={ read_counter , in_request.req_type , output_adress.row };					
					end
					else begin
						bank_out_req[i] = 0;
					end
				end

				read_counter ++ ;
			end

			else begin
				waiting_req.valid = 1;
				waiting_req.req_type = in_request.req_type;
				waiting_req.address =  output_adress  ;
				waiting_req.data = in_request.data  ;
			end
		end
		
		write_state : begin

			if ( stop_writing == 0  &&  in_busy [{ output_adress.bank_group , output_adress.bank}] == 0 ) begin

				array_enable = 1;
				golbal_array_out_req.address = output_adress;
				golbal_array_out_req.req_type = write;
				golbal_array_out_req.data = in_request.data;

				for (int i = 0; i < 16; i++) begin
					if (i == { output_adress.bank_group , output_adress.bank} ) begin
						bank_out_req [i] = { write_counter , in_request.req_type , output_adress.row};					
					end
					else begin
						bank_out_req[i] = 0;
					end
				end

				write_counter ++ ;
			end

			else begin
				waiting_req.valid = 1;
				waiting_req.req_type = in_request.req_type;
				waiting_req.address =  output_adress  ;
				waiting_req.data = in_request.data  ;
			end
		end
		
		busy_state : begin
			
			out_busy = 1;
			
			if (waiting_req.valid == 0) begin
				bank_out_valid = 0;
				for (int i = 0; i < 16; i++) begin
					bank_out_req[i] = 0;
				end
				array_enable = 0;
				golbal_array_out_req = 0;
				out_index = 0;
			end
			
			else begin


				if (waiting_req.req_type == read) begin

					if ( stop_reading == 0  &&  in_busy [{ output_adress.bank_group , output_adress.bank}] == 0 ) begin

						array_enable = 1;
						golbal_array_out_req.address = output_adress;
						golbal_array_out_req.req_type = read;
				
						for (int i = 0; i < 16; i++) begin
							if (i == { waiting_req.address.bank_group , waiting_req.address.bank} ) begin
								bank_out_req [i] ={ read_counter  , waiting_req.req_type , waiting_req.address.row  };					
							end
							else begin
								bank_out_req[i] = 0;
							end
						end

					read_counter ++ ;
					waiting_req.valid = 0;
					end
							
				end

				else begin

					if ( stop_writing == 0  &&  in_busy [{ output_adress.bank_group , output_adress.bank}] == 0) begin

						array_enable = 1;
						golbal_array_out_req.address = output_adress;
						golbal_array_out_req.req_type = write;
						golbal_array_out_req.data = in_request.data;
						
						for (int i = 0; i < 16; i++) begin
							if (i == { waiting_req.address.bank_group , waiting_req.address.bank} ) begin
							bank_out_req [i] = { write_counter , waiting_req.req_type , waiting_req.address.row };					
							end
							else begin
								bank_out_req[i] = 0;
							end
						end

						write_counter ++ ;
						waiting_req.valid = 0;
					end
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
			out_busy = 0;
			bank_out_valid = 0;
			for (int i = 0; i < 16; i++) begin
				bank_out_req[i] = 0;
			end
			array_enable = 0;
			golbal_array_out_req = 0;
			out_index = 0;
		end
	
	endcase
end

endmodule

