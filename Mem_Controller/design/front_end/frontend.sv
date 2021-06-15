`include "BS_Definitions.svh"

module front_end import types_def::*;
#( parameter REQ_SIZE = 32 )
 (
	input clk,    // Clock
	input rst_n,  // synchronous reset active low
	
//////////////////// the mapper \\\\\\\\\\\\\\\\\\\\\\\\\
 
	input in_valid, 	// from rnic
	input logic in_request_type ,
    input logic [data_width-1:0] in_request_data ,
    input logic [address_width-1:0] in_request_address , // from rnic
	output logic out_busy, // to rnic
///////////////////// the returner \\\\\\\\\\\\\\\\\\\\\\\\\
								  
	input request_done_valid,
	input the_type,
	input [ data_width -1  : 0 ] data_in,
	input [ read_entries_log -1 : 0 ] index,

	output logic write_done,
	output logic read_done,
	output logic  [ data_width -1 : 0 ] data_out,

    ///////////////////// scheduler  \\\\\\\\\\\\\\\\\\\\\\\\\
	output [banks_no-1:0] [REQ_SIZE-1 :0] out,//////////////////////////////////////////////////////////////////
    input [banks_no-1:0] grant_i
);

/**********************************************constant parameters**********************************************/
localparam BANK_NUM = 16;
		  
/*************************************************************************************************************/


opt_request request_out; 
wire [read_entries_log-1:0] out_index;
wire [banks_no-1:0] grant_o , bank_out_valid ;
wire [banks_no-1:0] pop , valid_out;
opt_request [banks_no-1:0] out_fifo_sch;
wire [banks_no-1:0] [read_entries_log-1:0] idx_out;


txn_controller tx(.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_request({in_request_type ,in_request_data ,in_request_address}),
                  .out_busy2(out_busy),.out_req2(request_out),.out_index2(out_index),
                  .fifo_grant_o(grant_o),.bank_out_valid2(bank_out_valid),.request_done_valid(request_done_valid),
                  .the_type(the_type),.data_in(data_in),.index(index),.write_done(write_done),.read_done(read_done),.data_out(data_out));


genvar g;
generate
    for (g=0; g < BANK_NUM; g=g+1)  begin
        modified_fifo m (.clk(clk),.rst_n(rst_n),.request_i(request_out),.index_i(out_index),
        .valid_i(bank_out_valid[g]),.grant_o(grant_o[g]),.request_o( out_fifo_sch[g]),.index_o(idx_out[g]),
        .valid_o(valid_out[g]), .grant_i(pop[g]));    
        
        BankScheduler #(.REQ_SIZE(REQ_SIZE),.TYPE_POS(`TYPE_POS),.ROW_BITS(`ROW_BITS),.ROW_POS(`ROW_POS),.BURST_POS(`BURST_POS),
        	.BURST_BITS(`BURST_BITS),.VALID_POS(`VALID_POS),.ADDR_BITS(`ADDR_BITS)) 
        BS      ( .clk(clk),.rst_n(rst_n),.grant_i(grant_i[g]),.in({valid_out[g],out_fifo_sch[g].address,idx_out[g],out_fifo_sch[g].req_type,out_fifo_sch[g].data}),.pop(pop[g]),.out(out[g]) );
    end   
endgenerate


endmodule