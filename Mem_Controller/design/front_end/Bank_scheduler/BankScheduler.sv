/********************************************************************************************************
-This block applies the scheme published on :
    Fang, Kun & Iliev, Nick & Noohi, Ehsan & Zhang, Suyu & Zhu, Zhichun. (2012). Thread Fair Memory Request Reordering - DRAM controller. 
-ROB requests are not considered it this block.
-when issue a new Burst, we select the next array index based one last index we drained requests from; in a
    round robin style, not in a FCFS way.

-The rules applied for draining new requests:
    1) Read is processed before writes (read first) unless the “write first” rule is triggered (with high water mark).
    2) When the write queue is about to be full (high watermark), process writes before reads until the
             write queue reach (low watermark).
    3) When at “read burst”, issue next arrays after last array index accessed last time.
    4) When at “write first”, issue next arrays after last array index accessed last time.


-Regarding any modifications in the module, any change is ok except number of each array parameter.
-Changing number of arrays requires editing only both functions to fit the new quantity of arrays,
    as all signals communcating with arrays are one hot encoded with each bit represents a single array.
********************************************************************************************************/
`include "BS_Definitions.svh"


module BankScheduler
#(parameter REQ_SIZE = 5 , parameter TYPE_POS = 5 ,parameter RA_BITS = 4 , parameter RA_POS=20 , parameter BURST_POS =20 ,parameter BURST_BITS =3,parameter ADDR_BITS=8 , parameter READ =0 , parameter WRITE =1,
  parameter INDEX_BITS = 7 ,parameter RA_POS_READ=5,  parameter DATA_BITS = 16, parameter RA_POS_WRITE = 7, parameter DATA_POS_WRITE = 16 )
(
   input   clk , rst_n , valid, grant_i  ,  //valid input request ------- arbiter needs new burst 
   input   [REQ_SIZE-1:0] data_in        ,// input data 
   output  grant                         ,// pop from (Mapper-schedular) FIFO      
   output  [REQ_SIZE-1:0] data_out       ,// output data 
   output  lwm , hwm
); 
   

/**********************************************Tunable parameters**********************************************/
localparam ARR_SIZE_RD =  4 ,//size of read array
           ARR_SIZE_WR =  2 ;//size of write array
           
localparam ARR_NUM_RD = 4,//number of read arrays
           ARR_NUM_WR = 3;//number of write arrays 

localparam NUM_OF_BUFFERS = ARR_NUM_WR+ARR_NUM_RD;
/*************************************************************************************************************/

/**********************************************Request Definitions*********************************************/
localparam REQ_SIZE_READ  =  RA_BITS+INDEX_BITS;
localparam REQ_SIZE_WRITE = REQ_SIZE_READ+DATA_BITS;

/*************************************************************************************************************/

/*********************************************Internal signals******************************************************/
wire [(NUM_OF_BUFFERS*RA_BITS)-1:0] last_addr  ; 
wire [NUM_OF_BUFFERS-1:0] full , empty , mid , push , valid_o, grant_o,pop;

/*reg [ALL_ARR-1:0] out_hits ;//find burst hits with current burst address stored in burst address register


reg [BURST_BITS+1 -1:0] burst_addr ; //burst address bits + valid
reg rst_burst; // active low
wire  in_type , out_type , valid_burst; //valid burst--> indicats whether the last burst address stored is currently used burst.*/
/*******************************************************************************************************************/
assign grant = |push ; // whenever new request is processed, then it will be stored in arrays successfully




//assign valid_burst = burst_addr[BURST_BITS] ; //valid bit is the last bit in burst address register.

//assign out_type = ( |rd_en ==1'b1 && |rd_en[ALL_ARR-1:ARR_NUM_RD] == 1'b1 )? `WRITE:`READ; //if there is read enable and its on a write array. 



//assign req = ! (&empty) ; // if at least one array is not full, issue request for arbiter to control the bus

/*always @ (posedge clk) begin //update burst address register
    if(!rst_n || !rst_burst)  
        burst_addr <= 0; 
    else
        burst_addr <= { 1'b1 , array_out[BURST_POS + hot2idx(rd_en)*(REQ_SIZE-1)   +: BURST_BITS]};
end

always @ (posedge clk) begin //update output
    if(!rst_n ) 
        data_out <= 0; 
    else if( rd_en !=0) //a new request will be drained from scheduler
        data_out <= array_out[hot2idx(rd_en)*(REQ_SIZE) +: REQ_SIZE ];
end*/

Selector #(.REQ_SIZE(REQ_SIZE), .ROW_BITS(RA_BITS), .ROW_POS(RA_POS),.READ(READ),.WRITE(WRITE),.ARR_NUM_WR(ARR_NUM_WR), .ARR_NUM_RD(ARR_NUM_RD)) selector
(.clk(clk),.rst_n(rst_n),.valid(valid),.in_type(data_in[TYPE_POS]),.empty(~valid_o) , .full(~grant_o),
 .mid(mid), .last_addr(last_addr),.in_addr(data_in[RA_POS +: RA_BITS]),.push(push));

/******************************************************FIFOS******************************************************/
genvar g;
generate
    for (g=0; g < ARR_NUM_RD; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(REQ_SIZE_READ), .DATA_DEPTH(ARR_SIZE_RD), .RA_POS(RA_POS_READ) , .RA_BITS(RA_BITS)) rd_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({data_in[INDEX_POS+:INDEX_BITS],data_in[RA_POS+:RA_BITS]}),.valid_i(push[g]),.grant_o(grant_o[g]),
        .last_addr(last_addr[g*RA_BITS +: RA_BITS]),.mid(mid[g]),.data_o(data_out[g]),.valid_o(valid_o),.grant_i(pop[g]));    
    end
    for (g= ARR_NUM_RD; g < NUM_OF_BUFFERS; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(REQ_SIZE_WRITE) ,.DATA_DEPTH(ARR_SIZE_WR), .RA_POS(RA_POS_WRITE) , .RA_BITS(RA_BITS)) wr_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({data_in[INDEX_POS+:INDEX_BITS],data_in[DATA_POS+:DATA_BITS],data_in[RA_POS+:RA_BITS]}),.valid_i(push[g]),.grant_o(grant_o[g]),
        .last_addr(last_addr[g*RA_BITS +: RA_BITS]),.mid(mid[g]),.data_o(data_out[g]),.valid_o(valid_o),.grant_i(pop[g]));
    end      
endgenerate
/******************************************************FIFOS******************************************************/

Write_Counter #(.ARR_NUM_WR(ARR_NUM_WR) , .ARR_SIZE_WR(ARR_SIZE_WR),.READ(READ) , .WRITE(WRITE)) wr_cnt
(   .clk(clk),.rst_n(rst_n),.in_type(data_in[TYPE_POS]),.out_type(),
     .grant_o(), .lwm(lwm) , .hwm(hwm) );




endmodule







