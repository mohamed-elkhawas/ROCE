//----------------------------------------------------------------------
//                                                                     
// Description: Selector part of bank scheduler module of the controller.                   
//              
//          
// Functionality: Selecting best fifo to insert new input in it stisfying a heuristic criteria, 
//                may not be the optimum way. It is a greedy sequence that always targets 
//                most empty fifo.
//                   1- First, check for hits in all fifos.
//                   2- If multiple hits are available, select first one.
//                   3- In case of no hits exists, check for empty fifos first.
//                   4- If multiple empty fifos are available, select first one.
//                   5- In case of no empty fifos, select first one.                         
//                
//    
// Modifications: Editing number of fifos requires edit signal width in both functions.
//                Also, It requires manual edit on computing push signals block.
//----------------------------------------------------------------------

module cntr_bs_sel
#(
    parameter RA           = 8,
    parameter READ         = 30,
    parameter WRITE        = 36,
    parameter RD_FIFO_NUM  = 4,
    parameter WR_FIFO_NUM  = 3
)
(
   valid_i, // Input valid bit from txn controller/bank scheduler fifo
   ra_i,    // Input row address from txn controller/bank scheeduler fifo
   t_i,     // Input type from txn controller/bank scheeduler fifo
   last_ra, // Input last row addresses from all bank scheduler fifos
   full,    // Input full signals of scheduler fifos
   mid,     // Input mid signals of scheduler fifos
   empty,   // Input empty signals of scheduler fifos
   push     // Output push signals for all fifos
);

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
  localparam FIFO_NUM = RD_FIFO_NUM + WR_FIFO_NUM ;
  localparam FIFOS_BITS = $clog2(FIFO_NUM);
//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************   
  input wire                               valid_i; // Input valid bit from txn controller/bank scheduler fifo
  input wire  [RA       -1 : 0]            ra_i;    // Input row address from txn controller/bank scheeduler fifo
  input wire                               t_i;     // Input type from txn controller/bank scheeduler fifo
  input wire [FIFO_NUM -1 : 0][RA -1 : 0] last_ra;  // Input last row addresses from all bank scheduler fifosoutput reg [DQ       -1 : 0] dq_o;    // Output data from txn controller/bank scheeduler fifos
  input wire [FIFO_NUM -1 : 0] full ;               // Input full signals of scheduler fifos
  input wire [FIFO_NUM -1 : 0] mid ;                // Input mid signals of scheduler fifos
  input wire [FIFO_NUM -1 : 0] empty ;              // Input empty signals of scheduler fifos
  output reg [FIFO_NUM -1 : 0] push;                // Output push signals for all fifos

//*****************************************************************************
// Functions declarations                                                             
//*****************************************************************************    

// return index of set bit in an input with one hot encoding style based on type of given request type
function [FIFOS_BITS -1:0]  get_index;
    input [FIFO_NUM -1 :0] in ;
    input request_type ;
    get_index = (request_type == READ)?
                    hot2idx( { 3'b000, in[RD_FIFO_NUM-1:0]}):
                    hot2idx( { in[FIFO_NUM -1 : RD_FIFO_NUM] , 4'b0000});
endfunction

// It returns index of first one bit with one hot style.
// we use casex to call function for non-hot encoded input.

function [FIFOS_BITS -1 :0]  hot2idx;
    input [FIFO_NUM -1 :0] in ;
    casex (in)
            7'bxxxxxx1 : hot2idx = 0 ;
            7'bxxxxx10 : hot2idx = 1 ;
            7'bxxxx100 : hot2idx = 2 ;
            7'bxxx1000 : hot2idx = 3 ;
            7'bxx10000 : hot2idx = 4 ;
            7'bx100000 : hot2idx = 5 ;
            7'b1000000 : hot2idx = 6 ;            
            default    : hot2idx = 0 ;
    endcase
endfunction 

//*****************************************************************************
// Internal signals declarations                                                             
//*****************************************************************************
wire [RD_FIFO_NUM -1 : 0] rd_empty , rd_full, rd_mid;
wire [WR_FIFO_NUM -1 : 0] wr_empty , wr_full, wr_mid; 

reg [FIFO_NUM -1 : 0] hits  ;

integer i ;

assign {rd_empty , rd_full  , rd_mid} = { empty[RD_FIFO_NUM             -1 :           0] , full[RD_FIFO_NUM -1 :           0] , mid[RD_FIFO_NUM -1 :           0] }; 
assign {wr_empty , wr_full  , wr_mid} = { empty[FIFO_NUM -1 : RD_FIFO_NUM] , full[FIFO_NUM    -1 : RD_FIFO_NUM] , mid[FIFO_NUM    -1 : RD_FIFO_NUM] }; 



//*****************************************************************************
// Find row Hits                                                       
//*****************************************************************************
always @(*) begin 
    for(i=0 ; i<FIFO_NUM ; i=i+1) 
        hits[i]  = (valid_i == 1'b1 && full[i] == 1'b0) ? last_ra[i] == ra_i :1'b0;//  input row hits
end


//*****************************************************************************
// calculate push signals                                              
//*****************************************************************************
always @(*) begin  
    push=7'd0;
    casex({hits, t_i})  
        {7'bxxx0000,READ}, {7'b000xxxx,WRITE}: begin // no hits available
            if( (t_i == READ && |rd_empty == 1'b1 )|| (t_i == WRITE && |wr_empty == 1'b1 )) //an empty array found
                push[get_index(empty , t_i)]=1'b1;
            else if( (t_i == READ && &rd_mid == 1'b0 )|| (t_i == WRITE && &wr_mid == 1'b0 ))//almost empty array found, select first one
                push[get_index(~mid , t_i)]=1'b1;
            else if( (t_i == READ && &rd_full == 1'b0 )|| (t_i == WRITE && &wr_full == 1'b0 ))//unfull array found, select first unfull array
                push[get_index(~full , t_i)]=1'b1;                
        end
        // hits found, select first available hit
        default : push[get_index(hits, t_i)]=1'b1;
    endcase

    if(valid_i == 1'b0) push = 7'd0 ;        
end

endmodule