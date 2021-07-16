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
#(
    parameter REQ  = 5 ,
    parameter TYPE_POS= 5 ,
    parameter RA   = 4 , 
    parameter RA_POS     = 20 ,
    parameter BURST_POS  =20 ,
    parameter BURST =3,
    parameter ADDR =8 ,
    parameter READ =0 ,
    parameter WRITE =1,
    parameter IDX = 7 ,
    parameter RA_POS_READ=5,
    parameter DQ = 16,
    parameter RA_POS_WRITE = 7,
    parameter DATA_POS_WRITE = 16
)
(
   clk,     // Input clock
   rst_n,   // Synchronous reset 
   ready,   //ready bit from arbiter      
   valid_i, // Input valid bit from txn controller/bank scheduler fifo
   dq_i,    // Input data from txn controller/bank scheduler fifo
   idx_i,   // Input index from txn controller/bank scheduler fifo
   ra_i,    // Input row address from txn controller/bank scheeduler fifo
   ca_i,    // Input col address from txn controller/bank scheeduler fifo  
   valid_o, // Output valid for arbiter
   dq_o,    // Output data from data path
   idx_o,   // Output index from data path
   ra_o,    // output row address from data path
   ca_o,    // output col address from data path
   grant,   // pop from (Mapper-schedular) FIFO      
   lwm,     // Low watermark for write requests quantity in the bank scheduler
   hwm      // High watermark for write requests quantity in the bank scheduler
); 
   

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************   
  parameter RD_FIFO_SIZE =  4 ; // size of read fifos
  parameter WR_FIFO_SIZE =  4 ; // size of read fifos  
           
  parameter RD_FIFO_NUM = 4 ; // number of read fifos
  parameter WR_FIFO_NUM = 3 ; // number of write fifos

  localparam FIFO_NUM =  RD_FIFO_NUM + WR_FIFO_NUM;
  localparam REQ      =  IDX + DQ + CA + RA ;
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
wire  in_type , out_type , valid_burst; //valid burst--> indicats whether the last burst address stored is currently used burst.*
/*******************************************************************************************************************
//assign grant = |push ; // whenever new request is processed, then it will be stored in arrays successfully




//assign valid_burst = burst_addr[BURST_BITS] ; //valid bit is the last bit in burst address register.

//assign out_type = ( |rd_en ==1'b1 && |rd_en[ALL_ARR-1:ARR_NUM_RD] == 1'b1 )? `WRITE:`READ; //if there is read enable and its on a write array. 



//assign req = ! (&empty) ; // if at least one array is not full, issue request for arbiter to control the bus

always @ (posedge clk) begin //update burst address register
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

cntr_bs_sel #(.REQ_SIZE(REQ_SIZE),.ROW_BITS(RA_BITS),.ROW_POS(RA_POS),.READ(READ),.WRITE(WRITE),.ARR_NUM_WR(ARR_NUM_WR),.ARR_NUM_RD(ARR_NUM_RD)) sel
(
    .clk(clk),
    .rst_n(rst_n),
    .valid(valid),
    .in_type(data_in[TYPE_POS]),
    .empty(~valid_o),
    .full(~grant_o),
    .mid(mid),
    .last_addr(last_addr),
    .in_addr(data_in[RA_POS +: RA_BITS]),
    .push(push)
);



Write_Counter #(.ARR_NUM_WR(ARR_NUM_WR) , .ARR_SIZE_WR(ARR_SIZE_WR),.READ(READ) , .WRITE(WRITE)) wr_cnt
(   
    .clk(clk),
    .rst_n(rst_n),
    .in_type(data_in[TYPE_POS]),
    .out_type(),
    .grant_o(),
    .lwm(lwm) ,
    .hwm(hwm)
);




endmodule*/







