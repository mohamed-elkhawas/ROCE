/********************************************************************************************************
    - A Heuristic critera depends on my opinion, may not be the optimum way. It is a greedy sequence
    that always targets most empty fifo.
        1- First, check for hits in all arrays.
        2- If multiple hits are available, select first one.
        3- In case of no hits exists, check for empty arrays first.
        4- If multiple empty arrays are available, select first one.
        5- In case of no empty arrays, select first one.                            
********************************************************************************************************/

module Selector
#(parameter RA_BITS = 8 , parameter RA_POS = 8, parameter READ = 0 , parameter WRITE = 1 , parameter ARR_NUM_WR= 3 , parameter ARR_NUM_RD=4)
(
   input   clk , rst_n , valid , in_type ,
   input   [ARR_NUM_WR + ARR_NUM_RD -1:0] empty , full, mid ,
   input   [((ARR_NUM_WR + ARR_NUM_RD)*RA_BITS)-1:0] last_addr , 
   input   [RA_BITS-1:0] in_addr,   
   output  reg [ARR_NUM_WR + ARR_NUM_RD -1:0] push    /* write enable signal to add new request in all buffers*/
);

localparam  NUM_OF_BUFFERS = ARR_NUM_WR+ARR_NUM_RD;

/***************************************internal components and signals***************************************/
wire [ARR_NUM_RD-1 : 0 ] empty_rd , full_rd, mid_rd;
wire [ARR_NUM_WR-1 : 0 ] empty_wr , full_wr, mid_wr; 

reg [NUM_OF_BUFFERS-1:0] row_hits  ;

integer i ;

assign {empty_rd , full_rd  , mid_rd} = { empty[ARR_NUM_RD-1:0] , full[ARR_NUM_RD-1:0] , mid[ARR_NUM_RD-1:0] }; 
assign {empty_wr , full_wr  , mid_wr} = { empty[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] , full[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] , mid[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] }; 

/******************************************functions**********************************************************/

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
/*************************************************************************************************************/
always @(*) begin //find row Hits / burst hits signals
    for(i=0 ; i<NUM_OF_BUFFERS ; i=i+1) 
        row_hits[i]  = (valid==1'b1 && full[i]==1'b0) ? last_addr[i*RA_BITS +: RA_BITS] == in_addr :1'b0;//  input row hits
        //out_hits[i] = (valid_burst==1'b1 && empty[i]==1'b0)? first_addr[i*BURST_BITS +: BURST_BITS] ==  burst_addr[BURST_BITS-1:0]      :1'b0;// output burst hits
end

always @(*) begin // calculate push signals
    push=7'd0;
    casex({row_hits, in_type})  
        {7'bxxx0000,READ}, {7'b000xxxx,WRITE}: begin // no hits available
            if( (in_type == READ && |empty_rd == 1'b1 )|| (in_type == WRITE && |empty_wr == 1'b1 )) //an empty array found
                push[get_index(empty , in_type)]=1'b1;
            else if( (in_type == READ && &mid_rd == 1'b0 )|| (in_type == WRITE && &mid_wr == 1'b0 ))//almost empty array found, select first one
                push[get_index(~mid , in_type)]=1'b1;
            else if( (in_type == READ && &full_rd == 1'b0 )|| (in_type == WRITE && &full_wr == 1'b0 ))//unfull array found, select first unfull array
                push[get_index(~full , in_type)]=1'b1;                
        end
        // hits found, select first available hit
        default : push[get_index(row_hits, in_type)]=1'b1;
    endcase

    if(valid==1'b0) push = 7'd0 ;        
end

endmodule
