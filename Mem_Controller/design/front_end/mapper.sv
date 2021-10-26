module mapper import types_def::*;
	
	(
	input clk,    	// Clock

	input rst_n,  	// synchronous reset active low

	input in_valid, 	// from rnic
	input request in_request, // from rnic
	output logic out_busy_o, // to rnic

	input stop_reading, // from over flow stopper
	input stop_writing, // from over flow stopper
	output logic  valid_out_o, // to over flow stopper
	
	output opt_request out_req_o,// to bank
	output logic [read_entries_log -1:0] out_index_o,// to the bank 


	input [15:0] in_busy, // from bank
	output logic  [15:0] bank_out_valid_o // to bank 


	);


typedef struct packed {
	logic valid ;
	r_type req_type ;
	address_type address ;
	logic [data_width -1:0] data ;
} waiting_request ;

waiting_request waiting_req;

address_type mapped_address;

logic [read_entries_log -1:0]	read_counter;
logic [write_entries_log -1:0]	write_counter;

logic  [15:0] bank_out_valid;

logic [3:0] bank_id ,waiting_bank_id;

/*
// permutation
/////////////////////////////////// scheme applier \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

// mapped_address =  { bank_group , bank , row , column }
//						2			2		16		10

// scheme   row   	bank 	column  bank_group	column	////////// 	the mapping scheme
// bits_no.	 16		 2			6		2			4

always_comb begin
	mapped_address.bank_group = in_request.address [5:4]	 ^ in_request.address[29 - t+3 :29 - t+2 ];
	mapped_address.bank 		 = in_request.address [13:12] ^ in_request.address[29 - t+1 :29 - t ]	; 
	mapped_address.row 		 = in_request.address [29:14];
	mapped_address.column 	 = { in_request.address [11:6] , in_request.address [3:0] };
end

/////////////////////////////////// scheme applier \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
*/

//direct mapping
/////////////////////////////////// scheme applier \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

// mapped_address =  { bank_group , bank , row , column }
//						2			2		16		10

// scheme   row   	bank 	column  bank_group	column	////////// 	the mapping scheme
// bits_no.	 16		 2			6		2			4

always_comb begin
	mapped_address.bank_group = in_request.address [5:4]	 ;// ^ in_request.address[29 - t+3 :29 - t+2 ];
	mapped_address.bank 		 = in_request.address [13:12];// ^ in_request.address[29 - t+1 :29 - t ]	; 
	mapped_address.row 		 = in_request.address [29:14];
	mapped_address.column 	 = { in_request.address [11:6] , in_request.address [3:0] };
end

/////////////////////////////////// scheme applier \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

always_comb begin 

	waiting_bank_id = { waiting_req.address.bank_group , waiting_req.address.bank};
	bank_id = { mapped_address.bank_group , mapped_address.bank};
	bank_out_valid = 0;
	bank_out_valid[bank_id] = 1;
end


always_ff @(posedge clk) begin 

	if(rst_n) begin

		if (waiting_req.valid) begin 

			if ( ( (waiting_req.req_type == write && stop_writing == 0) || (waiting_req.req_type == read && stop_reading == 0) ) &&  in_busy [waiting_bank_id] == 0) begin  // send the saved req
				
				out_req_o.address.column <= waiting_req.address.column;
				out_req_o.address.row <= waiting_req.address.row;
				out_req_o.data <= waiting_req.data;
				out_req_o.req_type <= waiting_req.req_type;

				if (waiting_req.req_type == read) begin
					out_index_o <= read_counter;
					read_counter <= read_counter +1;
				end
				else begin
					out_index_o <= write_counter;
					write_counter <= write_counter +1;
				end
				
				bank_out_valid_o <= bank_out_valid;
				valid_out_o <= 1;

				out_busy_o <= 0;

				waiting_req <= 0;				

			end

			else begin // idle but still busy
				out_busy_o <= 1;
				bank_out_valid_o <= 0;
				valid_out_o <= 0;
				out_index_o <= 0;
				out_req_o <= 0;
			end
			

		end
		else begin 

			if (in_valid) begin  
				
				if (( (in_request.req_type == write && stop_writing == 0) || (in_request.req_type == read && stop_reading == 0) ) &&  in_busy [bank_id] == 0) begin  // send new req 
					
					out_req_o.address.column <= mapped_address.column;
					out_req_o.address.row <= mapped_address.row;
					out_req_o.data <= in_request.data;
					out_req_o.req_type <= in_request.req_type;

					if (in_request.req_type == read) begin
						out_index_o <= read_counter;
						read_counter <= read_counter +1;
					end
					else begin
						out_index_o <= write_counter;
						write_counter <= write_counter +1;
					end								
					
					bank_out_valid_o <= bank_out_valid;
					valid_out_o <= 1;
					out_busy_o <= 0;
				end

				else begin // save new req & idle & busy

					waiting_req.valid <= 1;
					waiting_req.req_type <= in_request.req_type;
					waiting_req.address <=  mapped_address;
					waiting_req.data <= in_request.data;

					out_busy_o <= 1;
					bank_out_valid_o <= 0;
					valid_out_o <= 0;
					out_index_o <= 0;
					out_req_o <= 0;
				end

			end

			else begin // idle
				out_busy_o <= 0;
				bank_out_valid_o <= 0;
				valid_out_o <= 0;
				out_index_o <= 0;
				out_req_o <= 0;
			end
		end
	end

	else begin // reset
		read_counter <= 0;
		write_counter <= 0;
		waiting_req <= 0; //
		out_busy_o <= 0; //
		bank_out_valid_o <= 0; //
		valid_out_o <= 0;
		out_index_o <= 0; //

	end
end


endmodule
