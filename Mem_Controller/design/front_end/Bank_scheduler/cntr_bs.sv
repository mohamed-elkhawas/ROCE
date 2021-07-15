//----------------------------------------------------------------------
//                                                                     
// Description: Top module of Bank scheduler of the memory controller                   
//              
//          
// Functionality: Receive all requests corresponding to the bank and drain bursts to the arbiter
//                with maximum row hits as possible.
//                
//    
// Modifications: entry demux logic and exit demux logic are both will be changed manually 
//                in case of changing of number of fifos.
//                Also, function hot2idx and exit mux will be edited.
//              
//----------------------------------------------------------------------


/*module cntr_bs
#(parameter REQ_SIZE = 5 , parameter TYPE_POS = 5 ,parameter RA_BITS = 4 , parameter RA_POS=20 , parameter BURST_POS =20 ,parameter BURST_BITS =3,parameter ADDR_BITS=8 , parameter READ =0 , parameter WRITE =1,
  parameter IDX = 7 ,parameter RA_POS_READ=5,  parameter DATA_BITS = 16, parameter RA_POS_WRITE = 7, parameter DATA_POS_WRITE = 16 )
(
   input   clk , rst_n , valid, ready  ,  //ready bit from arbiter 
   input   [REQ_SIZE-1:0] data_in        ,// input data 
   output  grant                         ,// pop from (Mapper-schedular) FIFO      
   output  [REQ_SIZE-1:0] data_out       ,// output data 
   output  lwm , hwm
); 
   

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
localparam ARR_SIZE_RD =  4 ,//size of read array
           ARR_SIZE_WR =  2 ;//size of write array
           
localparam ARR_NUM_RD = 4,//number of read arrays
           ARR_NUM_WR = 3;//number of write arrays 

localparam NUM_OF_BUFFERS = ARR_NUM_WR+ARR_NUM_RD;
/*************************************************************************************************************/

/**********************************************Request Definitions*********************************************/
//localparam REQ_SIZE_READ  =  RA_BITS+INDEX_BITS;
//localparam REQ_SIZE_WRITE = REQ_SIZE_READ+DATA_BITS;

/*************************************************************************************************************/

/*********************************************Internal signals******************************************************/
//wire [(NUM_OF_BUFFERS*RA_BITS)-1:0] last_addr  ; 
//wire [NUM_OF_BUFFERS-1:0] full , empty , mid , push , valid_o, grant_o,pop;

/*reg [ALL_ARR-1:0] out_hits ;//find burst hits with current burst address stored in burst address register


reg [BURST_BITS+1 -1:0] burst_addr ; //burst address bits + valid
reg rst_burst; // active low
wire  in_type , out_type , valid_burst; //valid burst--> indicats whether the last burst address stored is currently used burst.*/
/*******************************************************************************************************************/
//assign grant = |push ; // whenever new request is processed, then it will be stored in arrays successfully




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
end

Selector #(.REQ_SIZE(REQ_SIZE), .ROW_BITS(RA_BITS), .ROW_POS(RA_POS),.READ(READ),.WRITE(WRITE),.ARR_NUM_WR(ARR_NUM_WR), .ARR_NUM_RD(ARR_NUM_RD)) selector
(.clk(clk),.rst_n(rst_n),.valid(valid),.in_type(data_in[TYPE_POS]),.empty(~valid_o) , .full(~grant_o),
 .mid(mid), .last_addr(last_addr),.in_addr(data_in[RA_POS +: RA_BITS]),.push(push));

/******************************************************FIFOS******************************************************/

/******************************************************FIFOS******************************************************

Write_Counter #(.ARR_NUM_WR(ARR_NUM_WR) , .ARR_SIZE_WR(ARR_SIZE_WR),.READ(READ) , .WRITE(WRITE)) wr_cnt
(   .clk(clk),.rst_n(rst_n),.in_type(data_in[TYPE_POS]),.out_type(),
     .grant_o(), .lwm(lwm) , .hwm(hwm) );




endmodule
*/






