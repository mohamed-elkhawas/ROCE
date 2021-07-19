//----------------------------------------------------------------------
//                                                                     
// Description: Top module of Bank scheduler of the memory controller                   
//              
//          
// Functionality: Receive all requests corresponding to the bank and drain bursts to the arbiter
//                with maximum row hits as possible.
//----------------------------------------------------------------------
 
module cntr_bs
#(
    parameter READ     = 1'b0,
    parameter WRITE    = 1'b1,
    parameter RA_POS   = 14,
    parameter CA       = 10,
    parameter RA       = 16,
    parameter DQ       = 16,
    parameter IDX      = 7
)
(
   clk,     // Input clock
   rst_n,   // Synchronous reset 
   ready,   //ready bit from arbiter      
   mode,    // Input controller mode to switch memory interface bus into write mode 
   valid_i, // Input valid bit from txn controller/bank scheduler fifo
   dq_i,    // Input data from txn controller/bank scheduler fifo
   idx_i,   // Input index from txn controller/bank scheduler fifo
   ra_i,    // Input row address from txn controller/bank scheeduler fifo
   ca_i,    // Input col address from txn controller/bank scheeduler fifo  
   t_i,     // Input type from txn controller/bank scheeduler fifo
   valid_o, // Output valid for arbiter
   dq_o,    // Output data from data path
   idx_o,   // Output index from data path
   ra_o,    // output row address from data path
   ca_o,    // output col address from data path
   t_o,     // Output type from scheeduler fifos
   rd_empty,// Output empty signal for read requests for each bank
   grant,   // pop from (Mapper-schedular) FIFO      
   num      // Number of write requests in the scheduler to controller mode
   
); 
     
//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************   
  parameter RD_FIFO_SIZE = 4 ; // size of read fifos
  parameter WR_FIFO_SIZE = 2 ; // size of write fifos     
  parameter RD_FIFO_NUM  = 4 ; // number of read fifos
  parameter WR_FIFO_NUM  = 3 ; // number of write fifos
  
  localparam FIFO_NUM = RD_FIFO_NUM + WR_FIFO_NUM;
  localparam BURST    = RA + CA - 4;
  localparam RA_ALL   = RA * FIFO_NUM;
  localparam RD_SIZE  = RA + IDX + CA;
  localparam WR_SIZE  = RD_SIZE + DQ ;
  localparam WR_BITS  = $clog2(WR_FIFO_SIZE * WR_FIFO_NUM) ; 
//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  input wire                    clk;          // Input clock
  input wire                    rst_n;        // Synchronous reset           
  input wire                    ready;        // Input ready bit from arbiter     
  input wire                    mode;         // Input controller mode to switch memory interface bus into write mode
  input wire                    valid_i;      // Input valid bit from txn controller/bank scheduler fifo
  input wire  [DQ       -1 : 0] dq_i;         // Input data from txn controller/bank scheeduler fifos
  input wire  [IDX      -1 : 0] idx_i;        // Input index from txn controller/bank scheeduler fifos
  input wire  [RA       -1 : 0] ra_i;         // Input row address from txn controller/bank scheduler fifo
  input wire  [CA       -1 : 0] ca_i;         // Input col address from txn controller/bank scheduler fifo
  input wire                    t_i;          // Input type from txn controller/bank scheeduler fifo
  output wire                   valid_o;      // Output valid for arbiter
  output reg  [DQ       -1 : 0] dq_o;         // Output data from txn controller/bank scheduler fifo
  output reg  [IDX      -1 : 0] idx_o;        // Output index from txn controller/bank scheeduler fifos
  output reg  [RA       -1 : 0] ra_o;         // output row address from txn controller/bank scheeduler fifo
  output reg  [CA       -1 : 0] ca_o;         // output col address from txn controller/bank scheeduler fifo
  output reg                    t_o;          // Output type from scheduler fifos
  output wire                   rd_empty;     // Output empty signal for read requests for each bank
  output wire                   grant;        // pop from (Mapper-schedular) FIFO      
  output wire [WR_BITS  -1 : 0] num;          // Number of write requests in the scheduler to controller mode
  


//*****************************************************************************
// Intermediate wires                                                            
//***************************************************************************** 
wire [FIFO_NUM -1 : 0][RA -1 : 0] last_ra ;
wire [FIFO_NUM -1 : 0] full, mid, empty, push, pop ; 
wire [FIFO_NUM -1 : 0] [BURST -1 : 0] burst_i  ;   

assign rd_empty = &empty[RD_FIFO_NUM -1 : 0]; //rd_empty =1 in case of all read fifos are empty

cntr_bs_sel#(.RA(RA),.READ(READ),.WRITE(WRITE),.RD_FIFO_NUM(RD_FIFO_NUM),.WR_FIFO_NUM(WR_FIFO_NUM)) selector
(
   .valid_i(valid_i), // Input valid bit from txn controller/bank scheduler fifo
   .ra_i(ra_i),       // Input row address from txn controller/bank scheeduler fifo
   .t_i(t_i),         // Input type from txn controller/bank scheeduler fifo
   .last_ra(last_ra), // Output last row addresses from all bank scheduler fifos
   .full(full),       // Output full signals of scheduler fifos
   .mid(mid),         // Output mid signals of scheduler fifos
   .empty(empty),     // Output empty signals of scheduler fifos
   .push(push)        // Output push signals for all fifos
);


cntr_bs_cnt#(.WR_FIFO_NUM(WR_FIFO_NUM),.WR_FIFO_SIZE(WR_FIFO_SIZE),.READ(READ),.WRITE(WRITE)) counter
(
   .clk(clk),        // Input clock
   .rst_n(rst_n),    // Synchronous reset  
   .t_i(t_i),        // Input type from txn controller/bank scheduler fifo
   .t_o(t_o),        // Input type of output from scheduler to Arbiter
   .wr_valid(grant), // Input successful push to scheduler fifo
   .rd_valid(|pop),  // Input successful pop from scheduler fifo
   .wr_cnt(num)      // Output Number of write requests in the scheduler to controller mode
); 

cntr_bs_sch #(.READ(READ),.WRITE(WRITE),.RD_FIFO_NUM(RD_FIFO_NUM),.WR_FIFO_NUM(WR_FIFO_NUM),.BURST(BURST) ) scheduler
(
   .clk(clk),                  // Input clock
   .rst_n(rst_n),              // Synchronous reset                                                     -> active low
   .ready(ready),              // Ready signal from arbiter                                             -> active high
   .mode(mode),                // Input controller mode to switch memory interface bus into write mode 
   .burst_i(burst_i),          // Input burst addresses
   .empty(empty),              // Input valid from fifos                
   .pop(pop),                  // Output grant signals to fifos
   .valid_o(valid_o) //Output valid for arbiter
);


cntr_bs_dp #(.RD_FIFO_NUM(RD_FIFO_NUM), .WR_FIFO_NUM(WR_FIFO_NUM), .RD_FIFO_SIZE(RD_FIFO_SIZE), .WR_FIFO_SIZE(WR_FIFO_SIZE), .DQ(DQ), .IDX(IDX), .RA(RA), .CA(CA),.RA_POS(RA_POS),.READ(READ),.WRITE(WRITE)) bs_dp
(
   .clk(clk),         // Input clock
   .rst_n(rst_n),     // Synchronous reset
   .push(push),       // Input push signals in a one-hot style to the bank scheduler fifos
   .pop(pop),         // Input pop signals in a one-hot style to the bank scheduler fifos
   .valid_i(valid_i),   // Input valid bit from txn controller/bank scheduler fifo
   .dq_i(dq_i),       // Input data from txn controller/bank scheduler fifo
   .idx_i(idx_i),     // Input index from txn controller/bank scheduler fifo
   .ra_i(ra_i),       // Input row address from txn controller/bank scheeduler fifo
   .ca_i(ca_i),       // Input col address from txn controller/bank scheeduler fifo
   .last_ra(last_ra), // Output last row addresses from all bank scheduler fifos
   .full(full),       // Output full signals of scheduler fifos
   .mid(mid),         // Output mid signals of scheduler fifos
   .empty(empty),     // Output valid signals of scheduler fifos
   .dq_o(dq_o),       // Output data from txn controller/bank scheduler fifo
   .idx_o(idx_o),     // Output index from txn controller/bank scheduler fifo
   .ra_o(ra_o),       // output row address from txn controller/bank scheeduler fifo
   .ca_o(ca_o),       // output col address from txn controller/bank scheeduler fifo
   .type_o(t_o),   // Output type from scheduler fifo
   .first_burst(burst_i),      //Output head burst of each fifo
   .grant(grant)
);


endmodule







