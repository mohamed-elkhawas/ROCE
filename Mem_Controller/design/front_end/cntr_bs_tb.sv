module cntr_bs_tb();

// pragma attribute txn_controller_tb partition_module_xrt


parameter READ  = 1'b0;
parameter WRITE = 1'b1;

parameter  RA_POS   = 10;
parameter  CA       = 10;
parameter  RA       = 16;
parameter  DQ       = 16;
parameter  IDX      = 6;

//scheduler stored requests format
localparam RD_SIZE    = RA + IDX + CA;
localparam WR_SIZE    = RD_SIZE + DQ ;


//scheduler fifos parameters
localparam  RD_FIFO_SIZE = 4;
localparam  WR_FIFO_SIZE = 2;
localparam  RD_FIFO_NUM  = 4;
localparam  WR_FIFO_NUM  = 3;


localparam FIFO_NUM     = RD_FIFO_NUM + WR_FIFO_NUM;
localparam BURST        = RA + CA - 4;
localparam RA_ALL       = RA * FIFO_NUM    ;

//*****************************************************************************
// Inputs                                                    
//***************************************************************************** 
reg clk;
reg rst_n;
reg ready;
reg [DQ  -1 :0] dq_i;
reg [IDX -1 :0] idx_i;
reg [RA  -1 :0] ra_i;
reg [CA  -1 :0] ca_i;
reg             t_i;
reg             valid_i;

//*****************************************************************************
// Outputs                                                
//***************************************************************************** 
wire [DQ  -1 :0] dq_o;
wire [IDX -1 :0] idx_o;
wire [RA  -1 :0] ra_o;
wire [CA  -1 :0] ca_o;
wire             t_o;



//*****************************************************************************
// Intermediate signals                                               
//***************************************************************************** 
// from controller mode to scheduler
wire mode ;
// from scheduler to arbiter
wire valid_o;
// from scheduler to mapper fifo
wire grant;
// from scheduler to controller mode 
wire rd_empty;
wire [$clog2(WR_FIFO_SIZE * WR_FIFO_NUM)-1:0] num ;


// Clock generator
// tbx clkgen inactive_negedge
initial  begin
    clk = 0;
    forever 
    #5 clk = ~clk;
end

//XlResetGenerator #(10) resetGenerator ( clk, rst);


initial begin   
    rst_n = 0;
    ready = 0;
    valid_i = 0;
    @(negedge clk);
    rst_n=1;
    valid_i=1'b1;
    repeat(10) begin //insert new input data
        {idx_i,dq_i,ra_i,ca_i,t_i}  = {$urandom(),$urandom()};
        @(negedge clk);
    end
    /*{idx_i,dq_i,ra_i,ca_i,t_i}  = {$urandom(),$urandom()};
    t_i = WRITE;
    @(negedge clk);
    {idx_i,dq_i,ra_i,ca_i,t_i}  = {$urandom(),$urandom()};
    t_i = READ;
    ready=1'b1;// Arbiter give access to scheduler to drain*/
end

cntr_bs#(.READ(READ),.WRITE(WRITE),.RA_POS(RA_POS),.CA(CA),.RA(RA),.DQ(DQ),.IDX(IDX)) BankScheduler
(
   .clk(clk),         // Input clock
   .rst_n(rst_n),     // Synchronous reset
   .ready(ready),     //ready bit from arbiter      
   .mode(mode),       // Input controller mode to switch memory interface bus into write mode 
   .valid_i(valid_i), // Input valid bit from txn controller/bank scheduler fifo
   .dq_i(dq_i),       // Input data from txn controller/bank scheduler fifo
   .idx_i(idx_i),     // Input index from txn controller/bank scheduler fifo
   .ra_i(ra_i),       // Input row address from txn controller/bank scheeduler fifo
   .ca_i(ca_i),       // Input col address from txn controller/bank scheeduler fifo
   .t_i(t_i),         // Input type from txn controller/bank scheeduler fifo
   .valid_o(valid_o), // Output valid for arbiter
   .dq_o(dq_o),       // Output data from from data path
   .idx_o(idx_o),     // Output index from from data path
   .ra_o(ra_o),       // output row address from data path
   .ca_o(ca_o),       // output col address from data path
   .t_o(t_o),         // Output type from scheduler fifo
   .rd_empty(rd_empty),     // Output empty signal for read requests for each bank
   .grant(grant),     // pop from (Mapper-schedular) FIFO      
   .num(num)          // Number of write requests in the scheduler to controller mode
); 

cntr_mode#(.WR_FIFO_SIZE(WR_FIFO_SIZE),.WR_FIFO_NUM(WR_FIFO_NUM),.READ(READ),.WRITE(WRITE)) cntr_mode
(
   .clk(clk),     // Input clock
   .rst_n(rst_n), // Synchronous reset
   .rd_empty({ {15{1'b1}},rd_empty }),     // Input empty signal for read requests for each bank 
   .num({45'd0,num}),     // Input number of write requests for each bank
   .mode(mode)    // Output controller mode
); 


endmodule