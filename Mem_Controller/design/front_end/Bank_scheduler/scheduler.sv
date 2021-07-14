module Scheduler();
#(parameter READ =1'b1 , parameter WRITE = 1'b0 , parameter ARR_NUM_RD = 4, parameter ARR_NUM_WR = 3, parameter REQ_SIZE_READ = 5 , parameter REQ_SIZE_WRITE = 5 ,parameter BURST_BITS = 16 )
(
   input   clk , rst_n , ready , mode, //mode-->read or write draining
   input   [(REQ_SIZE_READ*ARR_NUM_RD)-1:0]  in_rd ,// input read data 
   input   [(REQ_SIZE_WRITE*ARR_NUM_WR)-1:0] in_wr ,// input write data
   input   [(ARR_NUM_RD+ARR_NUM_WR)-1:0]     empty , 
   output  [(ARR_NUM_RD+ARR_NUM_WR)-1:0] pop       ,
   output  valid_o //to arbiter           
);


localparam NUM_OF_BUFFERS = ARR_NUM_RD + ARR_NUM_WR ;

/************************************************needed signals*****************************************************/
wire [ARR_NUM_RD-1:0] empty_rd  ;
wire [ARR_NUM_WR-1:0] empty_wr  ;

assign {empty_rd , empty_wr} = { empty[ARR_NUM_RD-1:0] , empty[NUM_OF_BUFFERS -1:ARR_NUM_RD] }; 

reg [NUM_OF_BUFFERS-1:0] hits ;
  


reg [$clog2(ARR_NUM_RD):0] cnt_rd ; //counter for next read fifo to be accessed
reg [$clog2(ARR_NUM_WR):0] cnt_wr ; //counter for next write fifo to be accessed


integer i ;
/*************************************************************************************************************/

/************************************************functions*****************************************************/
// return index of set bit in an input with one hot encoding style based on type of given request type
function [$clog2(NUM_OF_BUFFERS)-1:0]  get_index;
    input [NUM_OF_BUFFERS-1:0] in ;
    input request_type ;
    get_index = (request_type == READ)?
                    hot2idx( { 3'b000, in[ARR_NUM_RD-1:0]}):
                    hot2idx( { in[NUM_OF_BUFFERS-1:ARR_NUM_RD] , 4'b0000});
endfunction


// It returns index of first one bit with one hot style.
// we use casex to call function for non-hot encoded input.
function [$clog2(NUM_OF_BUFFERS)-1:0]  hot2idx;
    input [NUM_OF_BUFFERS-1:0] in ;
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
/**********************************************************************************************************/



always @(*) begin //find burst hits 
    for(i=0 ; i<ARR_NUM_RD ; i=i+1) 
        hits[i] = (empty[i] ==1'b0 )? in_rd[((i+1)*REQ_SIZE_READ)-1 : ((i+1)*REQ_SIZE_READ)-BURST_BITS-1]   ==  CB[BURST_BITS:1]  :1'b0;
    for(i=ARR_NUM_RD ; i<NUM_OF_BUFFERS ; i=i+1) 
        hits[i] = (empty[i] ==1'b0 )? in_wr[((i+1)*REQ_SIZE_WRITE)-1 : ((i+1)*REQ_SIZE_WRITE)-BURST_BITS-1] ==  CB[BURST_BITS:1]  :1'b0;
end

always @(posedge clk)begin //calculating next fifos to be accessed
    if(rst_n) begin
        cnt_rd <= 0 ; 
        cnt_wr <= 0 ;
    end
    else begin
        if(cnt_up_rd)begin
            if(cnt_rd == ARR_NUM_RD-1) 
                cnt_rd <= 0 ;  
            else
                cnt_rd <= cnt_rd +1 ;
        end
        if(cnt_up_wr)begin
            if(cnt_wr == ARR_NUM_WR-1) 
                cnt_wr <= 0 ;  
            else
                cnt_wr <= cnt_wr +1 ;
        end
    end
end

/************************************************FSM signals*****************************************************/
localparam [2:0] // 3 states are required
    EMPTY       = 3'b000,
    WAITING     = 3'b001,
    FINISH      = 3'b010,
    WRITE_BURST = 3'b011,
    READ_BURST  = 3'b100;

reg [1:0] CS, NS;
reg valid_o , cnt_up_rd , cnt_up_wr ;  //valid_o =1 in case of ready new burst is needed to be drained
reg [BURST_BITS-1:0] CB , NB; //CB-> valid bit + current burst address ----- NB-> next burst
/*****************************************************************************************************************/


// UPDATE FSM 
always @(posedge clk)begin
    if(!rst_n)begin
        CS <= EMPTY;
        CB <= {BURST_BITS{1'b0};
    end
    else begin
        CS  <= NS ;
        CB  <= NB ; 
    end
end


// Compute Next State and outputs
always @(*) begin
    NS = CS ;
    NB = {{BURST_BITS{1'b0}} ;  
    valid_o = 1'b0 ; 
    pop = {NUM_OF_BUFFERS{1'b0}};
    cnt_up_rd = 1'b0;
    cnt_up_wr = 1'b0;
    case(CS) 
        EMPTY , FINISH:begin
            if(mode == READ) begin
                if( &empty_rd == 1'b1  )  //all read fifos are empty
                    NS = EMPTY ;
                else if( &empty_rd == 1'b0 ) begin // at least one read fifo is not empty
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
            end
            else if(mode == WRITE) begin
                if( &empty_wr == 1'b1  ) //all write fifos are empty
                    NS = EMPTY ;
                else if( &empty_wr == 1'b0 ) begin // at least one write fifo is not empty
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
            end
        end
        WAITING:begin
            if(mode == READ) begin
                if( &empty_rd == 1'b1  )
                    NS = EMPTY ;
                else if( &empty_rd == 1'b0 ) begin
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
                else if( ready = 1'b1 ) begin
                    NS = READ_BURST;
                    valid_o = 1'b1 ;
                    if(empty[cnt_rd] == 1'b0) // next fifo to be accessed is not empty
                        pop[cnt_rd] = 1'b1;
                    else if(empty[cnt_rd] == 1'b1) //if it is an empty fifo, then find first un empty one
                        pop[get_index(empty,READ)] = 1'b1;
                        
                    NB = in_rd[get_index(pop,READ)][REQ_SIZE_READ-BURST_BITS-1 +: BURST_BITS];
                end
            end
            else if(mode == WRITE) begin
                if( &empty_wr == 1'b1  )
                    NS = EMPTY ;
                else if( &empty_wr == 1'b0 ) begin
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
                else if( ready = 1'b1 ) begin
                    NS = WRITE_BURST;
                    valid_o = 1'b1 ; 
                    if(empty[cnt_wr+ARR_NUM_RD] == 1'b0) // next fifo to be accessed is not empty
                        pop[cnt_wr+ARR_NUM_RD] = 1'b1;
                    else if(empty[cnt_wr+ARR_NUM_RD] == 1'b1) //if it is an empty fifo, then find first un empty one
                        pop[get_index(empty,WRITE)] = 1'b1;

                    NB = in_wr[get_index(pop,WRITE)][REQ_SIZE_WRITE-BURST_BITS-1 +: BURST_BITS];
                end
            end
        end
        READ_BURST : begin
            if ( |hits[ARR_NUM_RD-1:0] == 1'b1 ) begin // burst hit exists
                NS  = READ_BURST;
                valid_o= 1'b1 ;
                pop[get_index(hits,READ)]=1'b1;
            end
            else begin // burst hit does not exist 
                NS = FINISH ;
                cnt_up_rd = 1'b1; //increment counter for round robin over fifos
            end                             
        end
        WRITE_BURST : begin
            if ( |hits[NUM_OF_BUFFERS-1:ARR_NUM_RD] == 1'b1 ) begin // burst hit exists
                NS  = WRITE_BURST;
                valid_o= 1'b1 ;
                pop[get_index(hits,WRITE)]=1'b1;
            end
            else begin // burst hit does not exist 
                NS = FINISH ;
                cnt_up_wr = 1'b1;
            end       
        end 
    endcase
end

endmodule