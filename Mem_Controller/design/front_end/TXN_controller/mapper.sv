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


logic out_busy;
logic  valid_out;
request out_req;
logic [read_entries_log -1:0] out_index;
logic  [15:0] bank_out_valid;

typedef enum logic [2:0] { idle , read_state , write_state , busy_state , reset_state } my_states ;

my_states curr_state , next_state ; 

logic [read_entries_log -1:0]	read_counter;
logic [write_entries_log -1:0]	write_counter;

typedef struct packed {
	logic valid ;
	r_type req_type ;
	address_type address ;
	logic [data_width -1:0] data ;
} waiting_request ;

waiting_request waiting_req;

address_type output_address;

logic read_counter_up , write_counter_up ,update_waiting_req ,save_waiting_req;

logic save_waiting_req_reg, update_waiting_req_reg;

task save_the_waiting_req ();	
	waiting_req.valid <= 1;
	waiting_req.req_type <= in_request.req_type;
	waiting_req.address <=  output_address  ;
	waiting_req.data <= in_request.data  ;
	bank_out_valid <= 0;			
endtask


always_ff @(posedge clk ) begin
	if(rst_n) begin
		curr_state <= next_state ;
	end 
	else begin
		curr_state <= reset_state;
	end
end

always_ff @(posedge clk ) begin
	
	if(rst_n) begin
				
		if(read_counter_up) begin
			read_counter <= read_counter +1;
		end
		if(write_counter_up) begin
			write_counter <= write_counter +1;
		end
		
		if (update_waiting_req) begin
			save_the_waiting_req();
		end
		if (save_waiting_req == 0 && update_waiting_req == 0) begin
			waiting_req.valid <= 0;
		end

	end 
	else begin		
		read_counter <= 0;
		write_counter <= 0;
		
	end
end


/////////////////////////////////// scheme applier \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

// output_address =  { bank_group , bank , row , column }
//						2			2		16		10

// scheme   row   	bank 	column  bank_group	column	////////// 	the mapping scheme
// bits_no.	 16		 2			6		2			4

always_comb begin
	output_address.bank_group = in_request.address [5:4]	 ^ in_request.address[29 - t+3 :29 - t+2 ];
	output_address.bank 		 = in_request.address [13:12] ^ in_request.address[29 - t+1 :29 - t ]	; 
	output_address.row 		 = in_request.address [29:14];
	output_address.column 	 = { in_request.address [11:6] , in_request.address [3:0] };
end

/////////////////////////////////// scheme applier \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


always_comb begin 
	if (rst_n) begin
		if (save_waiting_req_reg == 0 && update_waiting_req_reg == 0) begin
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
		else next_state = busy_state;
	end
	
	else next_state = reset_state;
	
end


always_comb begin

	read_counter_up = 0;
	write_counter_up = 0;
	valid_out = 0;
	out_busy = 0;
	update_waiting_req= 0;
	bank_out_valid =0;

	case (next_state)
		
		read_state : begin

			if ( stop_reading == 0  &&  in_busy [{ output_address.bank_group , output_address.bank}] == 0 ) begin
			
				valid_out = 1;
				
				out_req.address.column = output_address.column;
				out_req.address.row = output_address.row;

				out_req.req_type = read;
				out_index = read_counter;

				
				bank_out_valid[{ output_address.bank_group , output_address.bank}]=1;

				read_counter_up =1;
			end

			else begin
				update_waiting_req = 1;
				out_busy = 1;
			end
		end
		
		write_state : begin

			if ( stop_writing == 0  &&  in_busy [{ output_address.bank_group , output_address.bank}] == 0 ) begin

				valid_out = 1;

				out_req.address.column = output_address.column;
				out_req.address.row = output_address.row;

				out_req.req_type = write;
				out_req.data = in_request.data;
				out_index = write_counter;

				bank_out_valid[{ output_address.bank_group , output_address.bank}]=1;

				write_counter_up = 1;
			end

			else begin
				update_waiting_req = 1;
				out_busy = 1;
			end
		end
		
		busy_state : begin
			
			save_waiting_req = 1;

			if (waiting_req.req_type == read) begin

				if ( stop_reading == 0  &&  in_busy [{ waiting_req.address.bank_group , waiting_req.address.bank}] == 0 ) begin
					
					valid_out = 1;

					out_req.address.column = waiting_req.address.column;
					out_req.address.row = waiting_req.address.row;

					out_req.req_type = read;
					out_index =read_counter;				
					bank_out_valid[{waiting_req.address.bank_group , waiting_req.address.bank}]=1;
					read_counter_up =1;
					save_waiting_req = 0;

				end
				else begin
					out_busy = 1;
				end
							
			end	

			else begin
				if ( stop_writing == 0  &&  in_busy [{ waiting_req.address.bank_group , waiting_req.address.bank}] == 0) begin

					valid_out = 1;
					
					out_req.address.column = waiting_req.address.column;
					out_req.address.row = waiting_req.address.row;
					
					out_req.req_type = write;
					out_req.data = in_request.data;
					out_index = write_counter;
					bank_out_valid[{waiting_req.address.bank_group , waiting_req.address.bank}]=1;
					write_counter_up = 1;
					save_waiting_req = 0;
				
				end
				else begin
					out_busy = 1;
				end
			end		

		end
		
		idle : begin
			out_req = 0;
			out_index = 0;
		end

		reset_state : begin
			update_waiting_req =0;
			save_waiting_req = 0;			
			out_req = 0;
			out_index = 0;
		end

		default : begin
			update_waiting_req =0;
			save_waiting_req = 0;					
			out_req = 0;
			out_index = 0;
		end
	
	endcase
end


always_ff @(posedge clk ) begin 
	out_busy_o <= out_busy;
	valid_out_o <= valid_out;
	{out_req_o.req_type ,out_req_o.data ,out_req_o.address.row ,out_req_o.address.column} <= {out_req.req_type ,out_req.data,out_req.address.row ,out_req.address.column};
	out_index_o <= out_index;
	bank_out_valid_o <= bank_out_valid;
	
	save_waiting_req_reg <= save_waiting_req;
	update_waiting_req_reg <= update_waiting_req;
end

endmodule
