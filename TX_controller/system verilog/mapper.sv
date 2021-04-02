module mapper 
	#( parameter

		data_width = 5'd31, 	// 32 bit
		address_width = 5'd29 	// 30 bit
	)


	(
	input clk,    	// Clock
	input sending, 	// sending Enable
	input in_busy,
	input rst,  	// synchronous reset active low
	input enum {read , write} req_type,
	input logic [data_width:0] data,
	input logic [address_width:0] address,

	output out_busy,
	output logic  [0:15] [ 1 + 6 : 0 ] out_req


	);


typedef enum logic [1:0] { idle , read_state , write_state , busy_state } state ;

state curr_state , next_state ; 


logic [6:0]	read_counter;
logic [6:0]	write_counter;


//		valid + address
logic [0:63][ 1 + address_width : 0]					read_global_array;

//		valid + address + data
logic [0:63][ 1 + address_width + data_width + 1 : 0]	write_global_array;

// 		valid + type + + address + data
logic [ 1 + 1 + address_width + data_width + 1 : 0] waiting_req;


typedef struct packed {
	logic [1:0] bank_group ;
	logic [1:0] bank ;
	logic [15:0] row ;
	logic [9:0] column ;	

} address_type;

address_type output_adress;

always_ff @(posedge clk ) begin
	if(~rst) begin
		curr_state <= idle;
	end 
	else begin
		curr_state <= next_state ;
		read_counter <= 0;
		write_counter <= 0;
	end
end


always_comb begin

	if (~busy) begin

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


// scheme applier

// output_adress =  { bank_group , bank , row , column }
//						2			2		16		10

always_comb begin
	output_adress.bank_group 	= address [5:4]		;
	output_adress.bank 			= address [13:12]	; 
	output_adress.row 			= address [29:14]	;
	output_adress.column 		= { address [11:6] , address [3:0] }	;
end



always_comb begin
	case (curr_state)
		
		read_state : begin

			if (read_global_array [read_counter][0] == 0 ) begin
				read_global_array [read_counter] = { 1 , output_adress } ;
				out_req [ { output_adress.bank_group , output_adress.bank}] = read_counter;
				read_counter ++ ;
			end

			else begin
				// do not know yet

			end
		end
		
		write_state : begin

			if (write_global_array [write_counter][0] == 0 ) begin
				write_global_array [write_counter] = { 1 , output_adress , data } ;
				out_req [ { output_adress.bank_group , output_adress.bank}] = write_counter;
				write_counter ++ ;
			end

			else begin
				// do not know yet

			end
		end
		
		busy_state : begin
		end
		
		idle : begin
		end

		default : begin

		end
	
	endcase
end

endmodule
