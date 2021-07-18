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
parameter READ     = 1'b0;
parameter WRITE    = 1'b1;
parameter RA_POS   = 10;
parameter CA_       = 10;
parameter RA       = 16;
parameter DQ_       = 16;
parameter IDX      = 6;
parameter WR_FIFO_SIZE = 2;
parameter WR_FIFO_NUM =3;




logic request_done_valid;
logic the_type;
logic [ data_width -1  : 0 ] data_in;
logic [ read_entries_log -1 : 0 ] index;



// from arbiter to scheduler
wire [15:0] ready ;

//from scheduler ro arbiter
wire [15:0]            valid_o;
wire [15:0][DQ_  -1 :0] dq_o;
wire [15:0][IDX -1 :0] idx_o;
wire [15:0][RA  -1 :0] ra_o;
wire [15:0][CA_  -1 :0] ca_o;
wire [15:0]            t_o;
// .* connect every connection with it's name

front_end #( .READ(READ),.WRITE(WRITE),.RA_POS(RA_POS),.CA(CA_),.RA(RA),.DQ(DQ_),.IDX(IDX),.WR_FIFO_SIZE(WR_FIFO_SIZE),.WR_FIFO_NUM(WR_FIFO_NUM) ) the_front_end
(.*); 

back_end #(.no_of_bursts(4),.IDX(IDX),.RA(RA),.CA_(CA_),.DQ_(DQ_))the_back_end
(
    .clk,    
    .rst_n,  
	.valid_i(valid_o),   // Input valid bit from txn controller/bank scheduler fifo
    .data_i(dq_o),       // Input data from txn controller/bank scheduler fifo
    .idx_i(idx_o),     // Input index from txn controller/bank scheduler fifo
    .row_i(ra_o),       // Input row address from txn controller/bank scheeduler fifo
    .col_i(ca_o),       // Input col address from txn controller/bank scheeduler fifo
    .t_i (t_o),
    .ready(ready) ,
    .returner_valid(request_done_valid),
	.returner_type(the_type),
	.returner_data(data_in),
	.returner_index(index), // to returner
	.CS_n,.CA,.CAI,.DM_n,.DQ,.DQS_t,.DQS_c,.ALERT_n // memory ports
);

	/*.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_request_type(t),
  	.in_request_data(in_request.data),
  	.in_request_address(in_request.address),
	.out_busy(out_busy),
	.request_done_valid(request_done_valid),
	.the_type(the_type),
	.data_in(in_data),
	.index(index),
	.write_done(write_done),
	.read_done(read_done),
	.data_out(data_out),
    .ready(ready),
	.valid_o(valid_o),
	.dq_o(dq_o),
	.idx_o(idx_o),
	.ra_o(ra_o),
	.ca_o(ca_o),
	.t_o(t_o)*/


endmodule

//veloce request format
/*parameter  CID_POS  = 0;
parameter  CA_POS   = 4;
parameter  RA_POS   = 14;
parameter  BA_POS   = 30;
parameter  BG_POS   = 32;
parameter  IDX_POS  = 34;
parameter  TYPE_POS = 41;
parameter  DQ_POS   = 42;
parameter  CID      = 4;
parameter  CA       = 10;
parameter  RA       = 16;
parameter  BA       = 2;
parameter  BG       = 2;
parameter  DQ       = 16;
parameter  TYPE     = 1;
parameter  IDX      = 7;
parameter  REQ_SIZE = CID + CA + RA + BA + BG + DQ + TYPE + IDX ; */