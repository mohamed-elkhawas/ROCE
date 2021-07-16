module memory_controller import types_def::*; (
	input clk,    // Clock
	input rst_n,  // synchronous reset active low

	//////////////////// rnic interface \\\\\\\\\\\\\\\\\\\\\\\\\
 	
 	/////////////////// 	input		 \\\\\\\\\\\\\\\\\\\\\\\\
	input in_valid, 	
	input logic in_request_type ,
    input logic [data_width-1:0] in_request_data ,
    input logic [address_width-1:0] in_request_address , 
	output logic out_busy, 

	///////////////////// 	output	 \\\\\\\\\\\\\\\\\\\\\\\\\
								  
	output logic write_done,
	output logic read_done,
	output logic  [ data_width -1 : 0 ] data_out,

	/////////////////// memory intrerface \\\\\\\\\\\\\\\\\\\

	output logic CS_n                ,// Chip Select -> active low
	output logic [13:0] CA           ,// Command / Address Port   
	output logic CAI                 ,// Command / Address inversion
	output logic [2:0] DM_n          ,// Data Mask -> byte based 
	inout [15:0] DQ           , // Data Port  
	inout [2:0] DQS_t , DQS_c , // Data Strobes (diff pair) // ~Data Strobes (diff pair)
 	inout ALERT_n               // CRC/Parity error flag
	
);


////////////// internal connections \\\\\\\\\\\\\\

parameter REQ_SIZE = 50; ///////////////////////////// change  it ya  hussin

logic [banks_no-1:0] [REQ_SIZE-1 :0] out;
logic [banks_no-1:0] grant_i;


logic request_done_valid;
logic the_type;
logic [ data_width -1  : 0 ] data_in;
logic [ read_entries_log -1 : 0 ] index;

// from arbiter to scheduler
wire [15:0] ready ;

//from scheduler ro arbiter
wire  [(DATA_BITS*16) -1 :0] data_o ,
wire  [(INDEX_BITS*16) -1 :0 ] idx_o ,
wire  [(RA_BITS*16)    -1 :0 ] row_o ,
wire  [(CA_BITS*16)    -1 :0 ] col_o ,
wire  [(1*16)          -1 :0 ] t_o, //  type bit

// .* connect every connection with it's name

front_end #( .REQ_SIZE(REQ_SIZE) ) the_front_end (.*); 

back_end #(.no_of_bursts(4),.INDEX_BITS(7) ,.RA_BITS(16) ,.CA_BITS(10) ,.DATA_BITS(16))

	the_back_end(
	//inputs from scheduler
	.data_i(data_o),.idx_i(idx_o),.row_i(row_o),.col_i(col_o),.t_i(t_o),
	// output to scheduler
	.Ready(ready),
	.returner_valid(request_done_valid),.returner_type(the_type),.returner_data(data_in),.returner_index(index), // to returner
	.CS_n,.CA,.CAI,.DM_n,.DQ,.DQS_t,.DQS_c,.ALERT_n // memory ports
	);





endmodule
