
module front_end import types_def::*;
#( parameter READ     = 1'b1,
   parameter WRITE    = 1'b0,
   parameter RA_POS   = 10,
   parameter CA       = 10,
   parameter RA       = 16,
   parameter DQ       = 16,
   parameter IDX      = 6,
   parameter WR_FIFO_SIZE = 2,
   parameter WR_FIFO_NUM =3
)
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
    input  [15:0] ready,
    output [15:0] valid_o, // Output valid for arbiter
    output [15:0] [DQ  -1 : 0] dq_o,    // Output data from data path
    output [15:0] [IDX -1 : 0] idx_o,   // Output index from data path
    output [15:0] [RA -1 : 0] ra_o,    // output row address from data path
    output [15:0] [CA -1 : 0] ca_o,    // output col address from data path
    output [15:0] t_o  // Output type from scheduler fifo     
);

     
//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************   
  parameter BANK_NUM = 16;

  localparam WR_BITS  = $clog2(WR_FIFO_SIZE * WR_FIFO_NUM) ; 


//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  /*input wire                    clk;          // Input clock
  input wire                    rst_n;        // Synchronous reset           
  input wire                    ready;        // Input ready bit from arbiter     
  input wire                    mode;         // Input controller mode to switch memory interface bus into write mode
  
*/

//*****************************************************************************
// Intermediate wires                                                            
//***************************************************************************** 
opt_request request_out; 
wire [read_entries_log-1:0] out_index;
wire [banks_no-1:0] grant_o , bank_out_valid ;
wire [banks_no-1:0] pop , valid_out;
opt_request [banks_no-1:0] out_fifo_sch;
wire [banks_no-1:0] [read_entries_log-1:0] idx_out;
wire [15:0] [WR_BITS  -1 : 0] num;

// schedulers and controller mode 
wire mode ;
wire [15:0] rd_empty;
txn_controller #(.data_width(16)) tx
(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid(in_valid),
  .in_request({in_request_type ,in_request_data ,in_request_address}),
  .out_busy2(out_busy),.out_req2(request_out),.out_index2(out_index),
  .fifo_grant_o(grant_o),.bank_out_valid2(bank_out_valid),
  .request_done_valid(request_done_valid),
  .the_type(the_type),
  .data_in(data_in),
  .index(index),
  .write_done(write_done),
  .read_done(read_done),
  .data_out(data_out)
);


genvar g;
generate
    for (g=0; g < BANK_NUM; g=g+1)  begin
        modified_fifo m (.clk(clk),.rst_n(rst_n),.request_i(request_out),.index_i(out_index),
        .valid_i(bank_out_valid[g]),.grant_o(grant_o[g]),.request_o( out_fifo_sch[g]),.index_o(idx_out[g]),
        .valid_o(valid_out[g]), .grant_i(pop[g]));    
               	
        cntr_bs#(.READ(READ),.WRITE(WRITE),.RA_POS(RA_POS),.CA(CA),.RA(RA),.DQ(DQ),.IDX(IDX)) BankScheduler
        (
            .clk(clk),         // Input clock
            .rst_n(rst_n),     // Synchronous reset
            .ready(ready[g]),     //ready bit from arbiter      
            .mode(mode),       // Input controller mode to switch memory interface bus into write mode 
            .valid_i(valid_out[g]), // Input valid bit from txn controller/bank scheduler fifo
            .dq_i(out_fifo_sch[g].data),       // Input data from txn controller/bank scheduler fifo
            .idx_i(idx_out[g]),     // Input index from txn controller/bank scheduler fifo
            .ra_i(out_fifo_sch[g].address.row),       // Input row address from txn controller/bank scheeduler fifo
            .ca_i(out_fifo_sch[g].address.column),       // Input col address from txn controller/bank scheeduler fifo
            .t_i(out_fifo_sch[g].req_type),         // Input type from txn controller/bank scheeduler fifo
            .valid_o(valid_o[g]), // Output valid for arbiter
            .dq_o(dq_o[g]),       // Output data from from data path
            .idx_o(idx_o[g]),     // Output index from from data path
            .ra_o(ra_o[g]),       // output row address from data path
            .ca_o(ca_o[g]),       // output col address from data path
            .t_o(t_o[g]),         // Output type from scheduler fifo
            .rd_empty(rd_empty),  // Output empty signal for read requests for each bank
            .grant(pop[g]),       // pop from (Mapper-schedular) FIFO      
            .num(num[g])          // Number of write requests in the scheduler to controller mode
        ); 
end   
endgenerate

cntr_mode#(.WR_FIFO_SIZE(WR_FIFO_SIZE),.WR_FIFO_NUM(WR_FIFO_NUM),.READ(READ),.WRITE(WRITE)) cntr_mode
(
.clk(clk),           // Input clock
.rst_n(rst_n),       // Synchronous reset  
.rd_empty(rd_empty), // Input empty signal for read requests for each bank
.num(num),           // Input number of write requests for each bank
.mode(mode)          // Output controller mode
);
endmodule
