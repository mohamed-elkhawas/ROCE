//----------------------------------------------------------------------
//                                                                     
// Description: Datapath part of bank scheduler module of the controller                   
//              
//          
// Functionality: Redirects both in/out data flow accross the bank scheduler module away from other control submodules.
//               
//                
//    
// Modifications: entry demux logic and exit demux logic are both will be changed manually 
//                in case of changing of number of fifos.
//                Also, function hot2idx and exit mux will be edited.
//              
//----------------------------------------------------------------------

module cntr_bs_dp
#(parameter RD_FIFO_NUM = 4, parameter WR_FIFO_NUM  = 3, parameter RD_FIFO_SIZE = 4, parameter WR_FIFO_SIZE  = 3, parameter DQ = 16, parameter IDX = 7, parameter RA = 16, parameter CA = 10 ,parameter RA_POS_READ = 5 , parameter RA_POS_WRITE = 5 )
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
   valid_o, // Output valid signals of scheduler fifos
   dq_o,    // Output data from txn controller/bank scheduler fifo
   idx_o,   // Output index from txn controller/bank scheduler fifo
   ra_o,    // output row address from txn controller/bank scheeduler fifo
   ca_o,    // output col address from txn controller/bank scheeduler fifo
   grant
);

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
  localparam FIFO_NUM = RD_FIFO_NUM + WR_FIFO_NUM ;
  localparam RA_ALL   = RA          * FIFO_NUM    ;
  localparam RD_SIZE  = RA          + CA          + IDX ;
  localparam WR_SIZE  = RA          + CA          + IDX          + DQ ;
  localparam FIFOS_BITS = $clog2(FIFO_NUM);
//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  input wire                   clk;          // Input clock
  input wire                   rst_n;        // Synchronous reset           input wire [FIFO_NUM -1 : 0] push;         // Input push signals in a one-hot style to the bank scheduler fifos
  input wire [FIFO_NUM -1 : 0] push;         // Input pop signals in a one-hot style to the bank scheduler fifos                                              
  input wire [FIFO_NUM -1 : 0] pop;          // Input pop signals in a one-hot style to the bank scheduler fifos                                              
  input wire                   valid_i;      // Input valid bit from txn controller/bank scheduler fifo
  input wire [DQ       -1 : 0] dq_i;         // Input data from txn controller/bank scheeduler fifos
  input wire [IDX      -1 : 0] idx_i;        // Input index from txn controller/bank scheeduler fifos
  input wire [RA       -1 : 0] ra_i;         // Input row address from txn controller/bank scheeduler fifo
  input wire [RA       -1 : 0] ca_i;         // Input col address from txn controller/bank scheeduler fifo
  output wire[RA_ALL   -1 : 0] last_ra;      // output last row addresses from all bank scheduler fifosoutput reg [DQ       -1 : 0] dq_o;    // Output data from txn controller/bank scheeduler fifos
  output reg [FIFO_NUM -1 : 0] full ;        // Output full signals of scheduler fifos
  output reg [FIFO_NUM -1 : 0] mid ;         // Output mid signals of scheduler fifos
  output reg [FIFO_NUM -1 : 0] valid_o ;     // Output valid signals of scheduler fifos
  output reg [DQ       -1 : 0] dq_o;         // Output data from txn controller/bank scheduler fifo
  output reg [IDX      -1 : 0] idx_o;        // Output index from txn controller/bank scheeduler fifos
  output reg [RA       -1 : 0] ra_o;         // output row address from txn controller/bank scheeduler fifo
  output reg [RA       -1 : 0] ca_o;         // output col address from txn controller/bank scheeduler fifo
  output wor                   grant;        // Output grant from fifos to txn controller/bank scheduler fifo
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
  //intermedate input port signals with fifos
  reg [FIFO_NUM    -1 :0][CA  -1 :0] f_ca_i;
  reg [FIFO_NUM    -1 :0][RA  -1 :0] f_ra_i;
  reg [WR_FIFO_NUM -1 :0][DQ  -1 :0] f_dq_i;
  reg [FIFO_NUM    -1 :0][IDX -1 :0] f_idx_i;

  //intermedate output port signals with fifos
  reg [FIFO_NUM    -1 :0][CA  -1 :0] f_ca_o;
  reg [FIFO_NUM    -1 :0][RA  -1 :0] f_ra_o;
  reg [WR_FIFO_NUM -1 :0][DQ  -1 :0] f_dq_o;
  reg [FIFO_NUM     -1 :0][IDX -1 :0] f_idx_o;
  
  
  wire [FIFOS_BITS -1 : 0] en_sel;  // entry request Demux sel signal 
  wire [FIFOS_BITS -1 : 0] ex_sel;  // exit request Demux sel signal   
  
  assign en_sel  = hot2idx(push);
  assign ex_sel  = hot2idx(pop);
  assign grant_o = push ;

//*****************************************************************************
// Bank scheduler fifos instances                                                          
//*****************************************************************************   

genvar g;
generate
    for (g=0; g < RD_FIFO_NUM; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(RD_SIZE), .DATA_DEPTH(RD_FIFO_SIZE), .RA_POS(RA_POS_READ) , .RA_BITS(RA) ) rd_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({f_idx_i[g],f_ra_i[g],f_ca_i[g]}),.valid_i(push[g]),
        .last_addr(last_ra[g*RA +: RA]),.mid(mid[g]),.data_o({f_idx_o[g],f_ra_o[g],f_ca_o[g]}),.valid_o(valid_o[g]),.grant_i(pop[g]));    
    end
    for (g= RD_FIFO_NUM; g < FIFO_NUM; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(WR_SIZE) ,.DATA_DEPTH(WR_FIFO_SIZE), .RA_POS(RA_POS_WRITE) , .RA_BITS(RA) ) wr_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({f_idx_i[g],f_dq_i[g-RD_FIFO_NUM],f_ra_i[g],f_ca_i[g]}),.valid_i(push[g]),
        .last_addr(last_ra[g*RA +: RA]),.mid(mid[g]),.data_o({f_idx_o[g],f_dq_o[g-RD_FIFO_NUM],f_ra_o[g],f_ca_o[g]}),.valid_o(valid_o[g]),.grant_i(pop[g]));
    end      
endgenerate

//*****************************************************************************
// entry demux
// we dont assign data to read fifos to optmize chip area
//***************************************************************************** 
always @(*) begin 
  case (en_sel) 
    3'd0 :   {      f_idx_i[0],f_ra_i[0],f_ca_i[0]} = {     idx_i,ra_i,ca_i} ;
    3'd1 :   {      f_idx_i[1],f_ra_i[1],f_ca_i[1]} = {     idx_i,ra_i,ca_i} ;
    3'd2 :   {      f_idx_i[2],f_ra_i[2],f_ca_i[2]} = {     idx_i,ra_i,ca_i} ;
    3'd3 :   {      f_idx_i[3],f_ra_i[3],f_ca_i[3]} = {     idx_i,ra_i,ca_i} ;
    3'd4 :   {f_dq_i[0],f_idx_i[4],f_ra_i[4],f_ca_i[4]} = {dq_i,idx_i,ra_i,ca_i} ;
    3'd5 :   {f_dq_i[1],f_idx_i[5],f_ra_i[5],f_ca_i[5]} = {dq_i,idx_i,ra_i,ca_i} ;
    3'd6 :   {f_dq_i[2],f_idx_i[6],f_ra_i[6],f_ca_i[6]} = {dq_i,idx_i,ra_i,ca_i} ;
    default: {f_dq_i[0],f_idx_i[4],f_ra_i[4],f_ca_i[4]} = {dq_i,idx_i,ra_i,ca_i} ; // any decision will be okay as all push signals will be zero
  endcase
end

//*****************************************************************************
// exit mux
//***************************************************************************** 
always @(*) begin 
  case (ex_sel) 
    3'd0 :   {dq_o,idx_o,ra_o,ca_o} = {16'd0,f_idx_o[0],f_ra_o[0],f_ca_o[0]} ;
    3'd1 :   {dq_o,idx_o,ra_o,ca_o} = {16'd0,f_idx_o[1],f_ra_o[1],f_ca_o[1]} ;
    3'd2 :   {dq_o,idx_o,ra_o,ca_o} = {16'd0,f_idx_o[2],f_ra_o[2],f_ca_o[2]} ;
    3'd3 :   {dq_o,idx_o,ra_o,ca_o} = {16'd0,f_idx_o[3],f_ra_o[3],f_ca_o[3]} ;
    3'd4 :   {dq_o,idx_o,ra_o,ca_o} = {f_dq_o[0],f_idx_o[4],f_ra_o[4],f_ca_o[4]} ;
    3'd5 :   {dq_o,idx_o,ra_o,ca_o} = {f_dq_o[1],f_idx_o[5],f_ra_o[5],f_ca_o[5]} ;
    3'd6 :   {dq_o,idx_o,ra_o,ca_o} = {f_dq_o[2],f_idx_o[6],f_ra_o[6],f_ca_o[6]} ;
    default: {dq_o,idx_o,ra_o,ca_o} = {f_dq_o[0],f_idx_o[4],f_ra_o[4],f_ca_o[4]} ; // any decision will be okay as all push signals will be zero
  endcase
end

endmodule