
module back_end import types_def::*;
#(parameter INDEX_BITS = 7 , parameter RA_BITS = 16 , parameter CA_BITS = 10 , parameter DATA_BITS = 16)
(  //inputs
	input clk,    
	input rst_n,  
    //arbiter inputs
	input [15:0] valid , // from schedulers
    input  [(16 * DATA_BITS) -1 :0] data_i ,
    input  [(INDEX_BITS*16) -1 :0 ] idx_i ,
    input  [(RA_BITS*16)    -1 :0 ] row_i ,
    input  [(CA_BITS*16)    -1 :0 ] col_i ,

    //output 
    output [15:0] ready , //arbiter output
    // burst handler outputs to returner
    output logic returner_valid,
	output r_type returner_type,
	output logic [data_width-1:0] returner_data,
	output logic [read_entries_log -1:0] returner_index
);

//velcoce request format
localparam  CID_POS         =0,
            CA_POS          =4,
            RA_POS          =14,
            BA_POS          =30,
            BG_POS          =32,
            DATA_POS        =33,
            TYPE_POS        =49,
            INDEX_POS       =50,
            CID_BITS        =4,
            CA_BITS         =10,
            RA_BITS         =16,
            BA_BITS         =2,
            BG_BITS         =2,
            DATA_BITS       =16,
            TYPE_BITS       =1,
            INDEX_BITS      =7,
            REQ_SIZE        =CA_BITS+RA_BITS+BA_BITS+BG_BITS+DATA_BITS+TYPE_BITS+INDEX_BITS ; // +CID_BITS -->removed as we deal with one chip 





    // intemediate signals between arbiter and burst handler
    wire   [DATA_BITS-1  : 0 ] data_o ;
    wire   [INDEX_BITS-1 : 0 ] idx_o ;
    wire   [RA_BITS-1    : 0 ] row_o ;
    wire   [CA_BITS-1    : 0 ] col_o ;
    wire wr_en ; //enable write to burst handler

    // intemediate signals between burst handler and timing controller
    wire burst_states_type [no_of_bursts-1:0] burst_state; // started_filling ,almost_done , full , empty , returning_data
	wire r_type [no_of_bursts-1:0] burst_type;
	wire address_type [no_of_bursts-1:0] burst_address; /// I need the row , bank and bank_group bits

	wire command burst_cmd_o	// start cmd 
	wire [$clog2(no_of_bursts)-1:0] cmd_index_o;
    wire [$clog2(no_of_bursts) :0]  empty_bursts_counter;


Arbiter #(.INDEX_BITS(INDEX_BITS), .RA_BITS(RA_BITS), .CA_BITS(CA_BITS), .DATA_BITS(DATA_BITS)) arbiter
(.clk(clk),.rst_n(rst_n), .valid(valid), .data_i(data_i) ,.idx_i(idx_i) ,.row_i(row_i) ,
    .col_i(col_i) ,  .data_o(data_o) ,.idx_o(idx_o)  ,.row_o(row_o)  , .col_o(col_o)  ,
    .ba_o(ba_o) ,.bg_o(bg_o), .wr_en(wr_en),.Ready(ready));



burst_handler m (.clk(clk),.rst_n(rst_n),.out_burst_state(burst_state),.out_burst_type(burst_type),
	.out_burst_address(burst_address),.in_burst_cmd(burst_cmd_o),.in_cmd_index(cmd_index_o),.start_new_burst,.arbiter_valid(wr_en),.in_req_address({col_o,row_o}),
	.arbiter_data(data_o),.arbiter_index((idx_o),.arbiter_type((data_out[TYPE_POS+:TYPE_BITS])),.returner_valid(returner_valid),.returner_type(returner_type),.returner_data(returner_data),.returner_index(returner_index));//,test);

timing_controller t (.clk(clk),.rst_n(rst_n),.in_burst_state(burst_state),.in_burst_type(burst_type),.in_burst_address(burst_address),.burst_start_next_cmd(burst_cmd_o),.cmd_i(cmd_index_o));


endmodule
