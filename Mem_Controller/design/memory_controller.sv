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


// .* connect every connection with it's name

front_end #( REQ_SIZE ) the_front_end (.*); 

back_end the_back_end(

	.CS_n,.CA,.CAI,.DM_n,.DQ,.DQS_t,.DQS_c,.ALERT_n // memory ports
	);


endmodule
