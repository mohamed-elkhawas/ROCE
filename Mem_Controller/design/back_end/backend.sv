
module back_end import types_def::*;
#( parameter REQ_SIZE = 32 , parameter ADDR_BITS = 16 , parameter ADDR_POS = 16, parameter INDEX_BITS = 16, parameter INDEX_POS = 16, parameter DATA_BITS = 16, parameter DATA_POS = 16,parameter TYPE_POS = 50 , parameter TYPE_BITS = 1 )
 (
     //inputs
	input clk,    
	input rst_n,  
    //arbiter inputs
	input [15:0] valid , // from schedulers
    input [REQ_SIZE-1:0] data_in ,// from schedulers

    //output 
    output [15:0] ready , //arbiter output
    // burst handler outputs to returner
    output logic returner_valid,
	output r_type returner_type,
	output logic [data_width-1:0] returner_data,
	output logic [read_entries_log -1:0] returner_index
);



    // intemediate signals between arbiter and burst handler
    wire [REQ_SIZE-1:0] data_out;
    wire wr_en ; //enable write to burst handler

    // intemediate signals between burst handler and timing controller
    wire burst_states_type [no_of_bursts-1:0] burst_state; // started_filling ,almost_done , full , empty , returning_data
	wire r_type [no_of_bursts-1:0] burst_type;
	wire address_type [no_of_bursts-1:0] burst_address; /// I need the row , bank and bank_group bits

	wire command burst_cmd_o	// start cmd 
	wire [$clog2(no_of_bursts)-1:0] cmd_index_o;
    wire [$clog2(no_of_bursts) :0]  empty_bursts_counter;



Arbiter #(.REQ_SIZE(`REQ_SIZE)) arbiter
(.clk(clk),.rst_n(rst_n), .Valid(valid), .Data_in(data_in) , .Data_out(data_out) , .wr_en(wr_en),.Ready(ready));


burst_handler m (.clk(clk),.rst_n(rst_n),.out_burst_state(burst_state),.out_burst_type(burst_type),
	.out_burst_address(burst_address),.in_burst_cmd(burst_cmd_o),.in_cmd_index(cmd_index_o),.start_new_burst,.arbiter_valid(wr_en),.in_req_address(data_out[ADDR_POS+:ADDR_BITS]),
	.arbiter_data(data_out[DATA_POS+:DATA_BITS]),.arbiter_index((data_out[INDEX_POS+:INDEX_BITS])),.arbiter_type((data_out[TYPE_POS+:TYPE_BITS])),.returner_valid(returner_valid),.returner_type(returner_type),.returner_data(returner_data),.returner_index(returner_index));//,test);

timing_controller t (.clk(clk),.rst_n(rst_n),.in_burst_state(burst_state),.in_burst_type(burst_type),.in_burst_address(burst_address),.burst_start_next_cmd(burst_cmd_o),.cmd_i(cmd_index_o));


endmodule
