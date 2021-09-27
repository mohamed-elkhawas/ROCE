//----------------------------------------------------------------------
//                                                                     
// Description: scheduler part of bank scheduling module of the controller                   
//              
//          
// Functionality: This block applies the scheme published on :
//                Fang, Kun & Iliev, Nick & Noohi, Ehsan & Zhang, Suyu & Zhu, Zhichun. (2012). Thread Fair Memory Request Reordering - DRAM controller.
//                ROB requests are not considered it this block.
//                when issue a new Burst, we select the next array index based one last fifo index we drained requests from; in a
//                in a round robin style, not in a FCFS way.

//                -The rules applied for draining new requests:
//                      1) Read is processed before writes (read first) unless the “write first” mode is triggered (with high water mark).
//                      2) When the write queue is about to be full (high watermark), process writes before reads until the
//                          write queue reach (low watermark).
//                      3) When at “read mode”, issue next arrays after last fifo index accessed last time.
//                      4) When at “write mode”, issue next arrays after last fifo index accessed last time.
//    
// Modifications: Any change is ok except editing othe total number of fifos.
//                Changing number of fifos requires editing signals width in both functions,
//                as all signals communcating with fifos are one hot encoded with each bit represents a single fifo.
//
//----------------------------------------------------------------------

module cntr_bs_sch
#(
    parameter READ        = 1'b1 ,
    parameter WRITE       = 1'b0 ,
    parameter RD_FIFO_NUM = 4,
    parameter WR_FIFO_NUM = 3,
    parameter BURST       = 16
)
(
   clk,      // Input clock
   rst_n,    // Synchronous reset                                                     -> active low
   ready,    // Ready signal from arbiter                                             -> active high
   mode,     // Input controller mode to switch memory interface bus into write mode 
   burst_i,  // Input burst addresses
   empty,    // Input empty signals from fifos                
   pop,      // Output pop signals to fifos
   valid_o   // Output valid for arbiter
);

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
  localparam FIFO_NUM = RD_FIFO_NUM + WR_FIFO_NUM ;
  localparam FIFOS_BITS = $clog2(FIFO_NUM);

//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  input wire                                 clk;      // Input clock
  input wire                                 rst_n;    // Synchronous reset                                                    -> active low                               
  input wire                                 ready;    // Input Ready signal from arbiter                                      -> active high        
  input wire                                 mode;     // Input controller mode to switch memory interface bus into write mode
  input wire [FIFO_NUM -1 : 0][BURST -1 : 0] burst_i;  // Input burst addresses
  input wire [FIFO_NUM -1 : 0]               empty;    // Input empty signals from fifos                           
  output reg [FIFO_NUM -1 : 0]               pop;      // Output pop signals to fifos
  output reg                                 valid_o;  // Output valid for arbiter

//*****************************************************************************
// Internal signals declarations                                                             
//*****************************************************************************
  wire [RD_FIFO_NUM -1         : 0] rd_empty ;
  wire [WR_FIFO_NUM -1         : 0] wr_empty ;
  //wire                              rd_start  ;
  //wire                              wr_start  ;
  //reg  [1                      : 0] start;          // Start signals to index counters    
  reg  [FIFO_NUM            -1 : 0] hits ;

  assign {rd_empty , wr_empty} = { empty[RD_FIFO_NUM-1:0] , empty[FIFO_NUM -1 : RD_FIFO_NUM] }; 
  //assign {wr_Start , rd_Start} = {start[1] , start[0]};
  integer i ;


  // FSM states
  enum reg [2:0] { EMPTY, WAITING, FINISH, WR_BURST, RD_BURST } CS, NS;
  reg [BURST -1 : 0] CB , NB; //CB-> current burst address ----- NB-> next burst
  reg [$clog2(RD_FIFO_NUM) -1 : 0] CRD , NRD   ;       // read counter index
  reg [$clog2(WR_FIFO_NUM) -1 : 0] CWR , NWR   ;       // write counter index

//*****************************************************************************
// Functions declarations                                                             
//*****************************************************************************    

// return index of set bit in an input with one hot encoding style based on type of given request type
function [FIFOS_BITS-1:0]  get_index;
    input [FIFO_NUM -1 : 0] in ;
    input request_type ;
    get_index = (request_type == READ)?
                    hot2idx( { 3'b000, in[RD_FIFO_NUM-1:0]}):
                    hot2idx( { in[FIFO_NUM -1 : RD_FIFO_NUM] , 4'b0000});
endfunction


// It returns index of first one bit with one hot style.
// we use casex to call function for non-hot encoded input.
function [FIFOS_BITS -1 : 0] hot2idx;
    input [FIFO_NUM - 1 : 0] in ;
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
// find burst hits                                                         
//*****************************************************************************    
always @(*) begin 
    for(i = 0 ; i<FIFO_NUM ; i=i+1) 
        hits[i] = (empty[i] == 1'b0 )? burst_i[i] == CB : 1'b0;
end


//*****************************************************************************
// Update the FSM                                                  
//***************************************************************************** 
always @(posedge clk)begin
    if(!rst_n) begin
        CS <= EMPTY;
        CB <= {BURST{1'b0}};
        CRD <= 0 ;
        CWR <= 0 ;
    end
    else begin
        CS  <= NS ;
        CB  <= NB ;
        CRD <= NRD ;
        CWR <= NWR ; 
    end
end

//*****************************************************************************
// Compute Next State and outputs                                        
//***************************************************************************** 
always @(*) begin
    NS = CS ;
    NB = CB ;
    NRD = CRD ;
    NWR = CWR ;   
    valid_o = 1'b0 ; 
    pop = {FIFO_NUM{1'b0}};
    //rd_start = 1'b0;
    //wr_start = 1'b0;
    case(CS) 
        EMPTY :begin
            if(mode == READ) begin
                if( &rd_empty == 1'b1  )  //all read fifos are empty
                    NS = EMPTY ;
                else if( &rd_empty == 1'b0 ) begin // at least one read fifo is not empty
                    NS = WAITING;
                    //valid_o  = 1'b1 ;
                    //rd_start = 1'b1 ; 
                end
            end
            else if(mode == WRITE) begin
                if( &wr_empty == 1'b1  ) //all write fifos are empty
                    NS = EMPTY ;
                else if( &wr_empty == 1'b0 ) begin // at least one write fifo is not empty
                    NS = WAITING;
                    //valid_o  = 1'b1 ;
                    //wr_start = 1'b1 ;  
                end
            end
        end
        WAITING:begin 
            //valid_o = 1'b1; 
            if(mode == READ && &rd_empty == 1'b1 || mode == WRITE && &wr_empty == 1'b1 )begin //current mode has no requests
                NS = EMPTY ;
                valid_o = 1'b0 ; 
                //$display("hi iam at NS = EMPTY");
            end
            else if (ready == 1'b0) begin   // Current mode has already stored requests
                NS = WAITING ;
                valid_o = 1'b1; 
                //$display("hi iam at ready = 1'b0 ");
            end 
            else if (ready == 1'b1) begin
                if(mode == READ)begin
                    NS = RD_BURST ;
                    valid_o = 1'b1;
                    if (rd_empty[CRD] == 1'b0) begin
                        pop[get_index(~empty,READ)] = 1'b1;
                        NB = burst_i[get_index(~empty,READ)] ;
                    end
                    else begin
                        pop[CRD] = 1'b1;
                        NB  = burst_i[CRD] ;                       
                    end
                    NRD = CRD + 1 ;
                    //$display("hi iam at ready = 1'b1 , mode = read ");
                    //pop[rd_idx] = 1'b1;
                    //NB = rd_i[rd_idx] ;  
                end  
                else if(mode == WRITE)begin
                    NS = WR_BURST ;
                    valid_o = 1'b1;
                    if (wr_empty[CWR] == 1'b0) begin
                        pop[get_index(~empty,WRITE)] = 1'b1;
                        NB = burst_i[get_index(~empty,WRITE)] ;
                    end
                    else begin
                        pop[CWR] = 1'b1;
                        NB = burst_i[CWR] ; 
                    end
                    NWR = CWR + 1 ;////////////////////////
                    //$display("hi iam at ready = 1'b1 , mode = write ");
                    //pop[wr_idx] = 1'b1;
                    //NB = wr_i[wr_idx] ;   
                end                     
            end
        end
        FINISH :begin
            //valid_o = 1'b0 ; 
            if(mode == READ && &rd_empty == 1'b1 || mode == WRITE && &wr_empty == 1'b1 ) begin//current mode has no requests
                NS = EMPTY ; 
                valid_o = 1'b0;   
            end  
            else  begin// Current mode has already stored requests      
                NS = WAITING ;
                valid_o = 1'b1;
            end
        end           
        RD_BURST :begin         
            //valid_o= 1'b1 ;
            if ( |hits[RD_FIFO_NUM-1:0] == 1'b1 ) begin // burst hit exists
                NS  = RD_BURST;  
                pop[get_index(hits,READ)] = 1'b1;
                valid_o = 1'b1 ;  
            end
            else begin // burst hit does not exist 
                NS = FINISH ;
                //rd_start = 1'b1 ; //increment counter for round robin over fifos
                valid_o = 1'b0 ;
            end                             
        end
        WR_BURST : begin 
            //valid_o= 1'b1 ;
            if ( |hits[FIFO_NUM-1:RD_FIFO_NUM] == 1'b1 ) begin // burst hit exists
                NS  = WR_BURST;
                pop[get_index(hits,WRITE)] = 1'b1;
                valid_o= 1'b1 ;
            end
            else begin // burst hit does not exist 
                NS = FINISH ;
                //wr_start = 1'b1;
                valid_o= 1'b0 ;
            end       
        end 
    endcase
end


//*****************************************************************************
// Index counters instants                                      
//*****************************************************************************
/*cntr_bs_sch_wr wr_cnt(   
   .clk(clk),        // Input clock
   .rst_n(rst_n),    // Synchronous reset                                    -> active low
   .start(wr_start), // Input start signal to increment the out              -> active high
   .valid(valid_i),  // Input valid signals to help choose proper next out 
   .idx(wr_idx)      // Output idx value
);

cntr_bs_sch_rc rd_cnt(   
   .clk(clk),        // Input clock
   .rst_n(rst_n),    // Synchronous reset                                    -> active low
   .start(rd_start), // Input start signal to increment the out              -> active high
   .valid(valid_i),  // Input valid signals to help choose proper next out 
   .idx(wr_idx)      // Output idx value
);*/

endmodule