//----------------------------------------------------------------------
//                                                                     
// Description: Datapath part of bank scheduler module of the controller                   
//              
//          
// Functionality: Redirects both in/out data flow accross the bank scheduler module away from other control submodules.
//               
//                
//    
// Modifications: Exit mux logic will be changed manually in case of changing of
//                number of fifos.
//                Also, function hot2idx and exit mux will be edited.
//              
//----------------------------------------------------------------------

module cntr_bs_dp
#(
  parameter RD_FIFO_NUM  = 4,
  parameter WR_FIFO_NUM  = 3,
  parameter RD_FIFO_SIZE = 4,
  parameter WR_FIFO_SIZE = 3,
  parameter DQ           = 16,
  parameter IDX          = 6,
  parameter RA           = 16,
  parameter CA           = 10 ,
  parameter RA_POS       = 5 ,
  parameter READ         = 1'b1,
  parameter WRITE        = 1'b0
)
(
   clk,     // Input clock
   rst_n,   // Synchronous reset      
   push,    // Input push signals in a one-hot style to the bank scheduler fifos
   pop,     // Input pop signals in a one-hot style to the bank scheduler fifos
   valid_i, // Input valid bit from txn controller/bank scheduler fifo
   dq_i,    // Input data from txn controller/bank scheduler fifo
   idx_i,   // Input index from txn controller/bank scheduler fifo
   ra_i,    // Input row address from txn controller/bank scheeduler fifo
   ca_i,    // Input col address from txn controller/bank scheeduler fifo
   last_ra, // Output last row addresses from all bank scheduler fifos
   full,    // Output full signals of scheduler fifos
   mid,     // Output mid signals of scheduler fifos
   empty,   // Output empty signals of scheduler fifos
   dq_o,    // Output data from data path
   idx_o,   // Output index from data path
   ra_o,    // output row address from data path
   ca_o,    // output col address from data path
   type_o,  // Output type from scheduler fifo
   first_burst, //Output head burst of each fifo
   grant
);

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
  localparam FIFO_NUM = RD_FIFO_NUM + WR_FIFO_NUM ;
  localparam RA_ALL   = RA          * FIFO_NUM    ;
  localparam CA_ALL   = CA          * FIFO_NUM    ;
  localparam IDX_ALL  = IDX         * FIFO_NUM    ;
  localparam DQ_ALL   = DQ          * FIFO_NUM    ;
  localparam RD_SIZE  = RA          + CA          +IDX ; //1 for type bit
  localparam WR_SIZE  = RD_SIZE     + DQ ;
  localparam BURST    = CA          + RA   - 4    ;
  localparam FIFOS_BITS = $clog2(FIFO_NUM);
//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  input wire                    clk;          // Input clock
  input wire                    rst_n;        // Synchronous reset           input wire [FIFO_NUM -1 : 0] push;         // Input push signals in a one-hot style to the bank scheduler fifos
  input wire  [FIFO_NUM -1 : 0] push;         // Input pop signals in a one-hot style to the bank scheduler fifos                                              
  input wire  [FIFO_NUM -1 : 0] pop;          // Input pop signals in a one-hot style to the bank scheduler fifos                                              
  input wire                    valid_i;      // Input valid bit from txn controller/bank scheduler fifo
  input wire  [DQ       -1 : 0] dq_i;         // Input data from txn controller/bank scheeduler fifos
  input wire  [IDX      -1 : 0] idx_i;        // Input index from txn controller/bank scheeduler fifos
  input wire  [RA       -1 : 0] ra_i;         // Input row address from txn controller/bank scheeduler fifo
  input wire  [CA       -1 : 0] ca_i;         // Input col address from txn controller/bank scheeduler fifo
  output wire [RA_ALL   -1 : 0] last_ra;      // output last row addresses from all bank scheduler fifosoutput reg [DQ       -1 : 0] dq_o;    // Output data from txn controller/bank scheeduler fifos
  output wire [FIFO_NUM -1 : 0] full ;        // Output full signals of scheduler fifos
  output reg  [FIFO_NUM -1 : 0] mid ;         // Output mid signals of scheduler fifos
  output wire [FIFO_NUM -1 : 0] empty ;       // Output empty signals of scheduler fifos
  output reg  [DQ       -1 : 0] dq_o;         // Output data from txn controller/bank scheduler fifo
  output reg  [IDX      -1 : 0] idx_o;        // Output index from txn controller/bank scheeduler fifos
  output reg  [RA       -1 : 0] ra_o;         // output row address from txn controller/bank scheeduler fifo
  output reg  [CA       -1 : 0] ca_o;         // output col address from txn controller/bank scheeduler fifo
  output reg                    type_o;       // Output type from scheduler fifos
  output reg [FIFO_NUM -1 : 0] [BURST -1 : 0] first_burst; //Output head burst of each fifo
  output wire                    grant;        // Output grant from fifos to txn controller/bank scheduler fifo
//*****************************************************************************
// Functions declarations                                                             
//*****************************************************************************    
function [FIFOS_BITS-1:0]  hot2idx;
    input [FIFO_NUM -1 : 0] in ;
    case (in)
        7'b0000001 : hot2idx = 0 ;
        7'b0000010 : hot2idx = 1 ;
        7'b0000100 : hot2idx = 2 ;
        7'b0001000 : hot2idx = 3 ;
        7'b0010000 : hot2idx = 4 ;
        7'b0100000 : hot2idx = 5 ;
        7'b1000000 : hot2idx = 6 ;            
        default    : hot2idx = 0 ;
    endcase
endfunction 


//*****************************************************************************
// Internal signals declarations                                                             
//*****************************************************************************
  //intermedate output port signals with fifos
  reg [FIFO_NUM    -1 : 0][CA  -1 :0] f_ca_o;
  reg [FIFO_NUM    -1 : 0][RA  -1 :0] f_ra_o;
  reg [WR_FIFO_NUM -1 : 0][DQ  -1 :0] f_dq_o;
  reg [FIFO_NUM    -1 : 0][IDX -1 :0] f_idx_o;
  
  
  wire [FIFOS_BITS -1 : 0] ex_sel;  // exit request mux sel signal   
  wire [FIFO_NUM   -1 : 0] grant_o;
  wire [FIFO_NUM   -1 : 0] valid_o;
  assign ex_sel  = hot2idx(pop);
  assign full = ~grant_o;
  assign empty = ~valid_o;
  assign grant = |push ;
  integer i ;
//*****************************************************************************
// Bank scheduler fifos instances                                                          
//*****************************************************************************   

genvar g;
generate
    for (g=0; g < RD_FIFO_NUM; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(RD_SIZE), .DATA_DEPTH(RD_FIFO_SIZE), .RA_POS(RA_POS) , .RA_BITS(RA) ) rd_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({idx_i,ra_i,ca_i}),.valid_i(push[g]),.grant_o(grant_o[g]),
        .last_addr(last_ra[g*RA +: RA]),.mid(mid[g]),.data_o({f_idx_o[g],f_ra_o[g],f_ca_o[g]}),.valid_o(valid_o[g]),.grant_i(pop[g]));    
    end
    for (g= RD_FIFO_NUM; g < FIFO_NUM; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(WR_SIZE) ,.DATA_DEPTH(WR_FIFO_SIZE), .RA_POS(RA_POS) , .RA_BITS(RA) ) wr_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({dq_i,idx_i,ra_i,ca_i}),.valid_i(push[g]),.grant_o(grant_o[g]),
        .last_addr(last_ra[g*RA +: RA]),.mid(mid[g]),.data_o({f_dq_o[(g-RD_FIFO_NUM)],f_idx_o[g],f_ra_o[g],f_ca_o[g]}),.valid_o(valid_o[g]),.grant_i(pop[g]));
    end      
endgenerate                                                 

//*****************************************************************************
// Assigning burst bits                                                        
//*****************************************************************************
always @(*) begin
  for(i =0 ;i< FIFO_NUM ; i++)
      first_burst[i] = {f_ra_o[i] , f_ca_o[i][CA-1:4]};
end

//*****************************************************************************
// exit mux
//***************************************************************************** 
always @(*) begin 
  case (ex_sel) 
    3'd0 :   {dq_o,idx_o,type_o,ra_o,ca_o} = {16'd0,f_idx_o[0],READ,f_ra_o[0],f_ca_o[0]} ;
    3'd1 :   {dq_o,idx_o,type_o,ra_o,ca_o} = {16'd0,f_idx_o[1],READ,f_ra_o[1],f_ca_o[1]} ;
    3'd2 :   {dq_o,idx_o,type_o,ra_o,ca_o} = {16'd0,f_idx_o[2],READ,f_ra_o[2],f_ca_o[2]} ;
    3'd3 :   {dq_o,idx_o,type_o,ra_o,ca_o} = {16'd0,f_idx_o[3],READ,f_ra_o[3],f_ca_o[3]} ;
    3'd4 :   {dq_o,idx_o,type_o,ra_o,ca_o} = {f_dq_o[0],f_idx_o[4],WRITE,f_ra_o[4],f_ca_o[4]} ;
    3'd5 :   {dq_o,idx_o,type_o,ra_o,ca_o} = {f_dq_o[1],f_idx_o[5],WRITE,f_ra_o[5],f_ca_o[5]} ;
    3'd6 :   {dq_o,idx_o,type_o,ra_o,ca_o} = {f_dq_o[2],f_idx_o[6],WRITE,f_ra_o[6],f_ca_o[6]} ;
    default: {dq_o,idx_o,type_o,ra_o,ca_o} = {f_dq_o[0],f_idx_o[4],WRITE,f_ra_o[4],f_ca_o[4]} ; // any decision will be okay as all push signals will be zero
  endcase
end

endmodule