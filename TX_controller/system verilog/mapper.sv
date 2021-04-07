package types_def;

  typedef enum enum {read , write} r_type;
  typedef enum logic [1:0] { idle , read_state , write_state , busy_state } state ;

  typedef struct packed {
	logic [1:0] bank_group ;
	logic [1:0] bank ;
	logic [15:0] row ;
	logic [9:0] column ;	

} address_type;

  typedef struct packed {
	logic valid ;
	r_type req_type ;
	address_type address ;
	logic [data_width:0] data ;
  } request ;

endpackage



module mapper import types_def::*;
	#( parameter

		data_width = 5'd31, 	// 32 bit
		address_width = 5'd29, 	// 30 bit
		read_entries = 63,
		write_entries = 63,
		permutation_param_t = 5 /////////////// add the right  t number here
	)


	(
	input clk,    	// Clock
	input sending, 	// sending Enable
	input in_busy,
	input rst,  	// synchronous reset active low
	input r_type req_type,
	input logic [data_width:0] data,
	input logic [address_width:0] address,

	output out_busy,
	output logic  [0:15] [ 5 + 1 + 16 : 0 ] out_req


	);


state curr_state , next_state ; 


logic [5:0]	read_counter;
logic [5:0]	write_counter;


//		valid + address
logic [0:read_entries][ 1 + address_width : 0]					read_global_array;

//		valid + address + data
logic [0:write_entries][ 1 + address_width + data_width + 1 : 0]	write_global_array;

// 		valid + type + + address + data
request 	waiting_req;


address_type output_adress;

always_ff @(posedge clk ) begin
	if(rst) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= idle;

		read_counter <= 0;
		write_counter <= 0;

		out_busy <= 0;
		for (int i = 0; i < 16; i++) begin
			out_req[i] <= 0;
		end

	end
end


always_comb begin

	if (~in_busy) begin

		if (waiting_req.valid == 0 ) begin

			if (sending) begin
				if (req_type == read) begin
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
	
	else begin
		next_state = busy_state ;
	end	
end


// scheme applier

// output_adress =  { bank_group , bank , row , column }
//						2			2		16		10

always_comb begin
	output_adress.bank_group 	= address [5:4]	 ^ address[29 - t+3 :29 - t+2 ]	;
	output_adress.bank 			= address [13:12] ^ address[29 - t+1 :29 - t ]	; 
	output_adress.row 			= address [29:14]	;
	output_adress.column 		= { address [11:6] , address [3:0] }	;
end



always_comb begin
	case (curr_state)
		
		read_state : begin

			if (read_global_array [read_counter][0] == 0 ) begin
				read_global_array [read_counter] = { 1 , output_adress } ;
				
				for (int i = 0; i < 16; i++) begin
					if (i == { output_adress.bank_group , output_adress.bank} ) begin
						out_req [i] ={ read_counter , req_type , output_adress.row };					
					end
					else begin
						out_req[i] = 0;
					end
				end

				read_counter ++ ;
			end

			else begin
				waiting_req.valid = 1;
				waiting_req.req_type = req_type;
				waiting_req.address =  output_adress  ;
				waiting_req.data = data  ;
			end
		end
		
		write_state : begin

			if (write_global_array [write_counter][0] == 0 ) begin
				write_global_array [write_counter] = { 1 , output_adress , data } ;

				for (int i = 0; i < 16; i++) begin
					if (i == { output_adress.bank_group , output_adress.bank} ) begin
						out_req [i] = { write_counter , req_type , output_adress.row};					
					end
					else begin
						out_req[i] = 0;
					end
				end

				write_counter ++ ;
			end

			else begin
				waiting_req.valid = 1;
				waiting_req.req_type = req_type;
				waiting_req.address =  output_adress  ;
				waiting_req.data = data  ;
			end
		end
		
		busy_state : begin
			
			out_busy = 1;
			
			if (waiting_req.valid == 0) begin
				for (int i = 0; i < 16; i++) begin
					out_req[i] = 0;
				end
			end
			
			else begin


				if (waiting_req.req_type == read) begin

					if (read_global_array [read_counter][0] == 0 ) begin
						read_global_array [read_counter] = { 1 , waiting_req.address } ;
				
						for (int i = 0; i < 16; i++) begin
							if (i == { waiting_req.address.bank_group , waiting_req.address.bank} ) begin
								out_req [i] ={ read_counter  , waiting_req.req_type , waiting_req.adress.row  };					
							end
							else begin
								out_req[i] = 0;
							end
						end

					read_counter ++ ;
					waiting_req.valid = 0;
					end
							
				end

				else begin

					if (write_global_array [write_counter][0] == 0 ) begin
						write_global_array [write_counter] = { 1 , waiting_req.address , waiting_req.data } ;

						for (int i = 0; i < 16; i++) begin
							if (i == { waiting_req.address.bank_group , waiting_req.address.bank} ) begin
							out_req [i] = { write_counter , waiting_req.req_type , waiting_req.adress.row };					
							end
							else begin
								out_req[i] = 0;
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
			for (int i = 0; i < 16; i++) begin
				out_req[i] = 0;
			end
		end

		default : begin
			out_busy = 0;
			for (int i = 0; i < 16; i++) begin
				out_req[i] = 0;
			end
		end
	
	endcase
end

endmodule
