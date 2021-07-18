module sch_arbiter_tb();

parameter READ     = 1'b0;
parameter WRITE    = 1'b1;
parameter RA_POS   = 10;
parameter BA       = 2;
parameter BG       = 2;
parameter CA       = 10;
parameter RA       = 16;
parameter DQ       = 16;
parameter IDX      = 6;
parameter REQ_SIZE = DQ+1+IDX+RA+CA;
parameter WR_FIFO_SIZE = 2;
parameter WR_FIFO_NUM  = 3;


//inputs
reg  clk;
reg  rst_n;
reg  valid ; 
reg [REQ_SIZE -1 :0] data;

// Intermediate signals
wire             valid_fifo_sch;
wire [DQ  -1 :0] dq_i;
wire [IDX -1 :0] idx_i;
wire [RA  -1 :0] ra_i;
wire [CA  -1 :0] ca_i;
wire [BA  -1 :0] ba_i;
wire [BG  -1 :0] bg_i;
wire             t_i;
wire grant_sch_fifo;
wire [15 : 0 ] ready;
wire        valid_sch_arbiter;

wire [DQ  -1 :0] dq_sch_arb;
wire [IDX -1 :0] idx_sch_arb;
wire [RA  -1 :0] ra_sch_arb;
wire [CA  -1 :0] ca_sch_arb;
wire [BA  -1 :0] ba_sch_arb;
wire [BG  -1 :0] bg_sch_arb;
wire             t_sch_arb;

// from scheduler to controller mode
wire rd_empty;
wire [$clog2(WR_FIFO_SIZE * WR_FIFO_NUM)-1:0] num ;


//outputs
wire [DQ  -1 :0] dq_o;
wire [IDX -1 :0] idx_o;
wire [RA  -1 :0] ra_o;
wire [CA  -1 :0] ca_o;
wire [BA  -1 :0] ba_o;
wire [BG  -1 :0] bg_o;
wire             t_o;



always #5 clk = ~clk;

initial begin 
    clk = 0 ;  
    rst_n = 1'b0;
    valid = 1'b1;
	#8 
	rst_n = 1'b1;

	repeat(10) begin //insert new input data
        @ (posedge clk);
		data = {$urandom(),$urandom()};
    end

end
generic_fifo #( .DATA_WIDTH(REQ_SIZE),.DATA_DEPTH(10),.RA_POS(RA_POS),.RA_BITS(RA) ) mapper_fifo
(
    .clk(clk),
    .rst_n(rst_n),
    .data_i(data),
    .valid_i(valid),
    .data_o({dq_i,t_i,idx_i,ra_i,ca_i}),
    .valid_o(valid_fifo_sch),
    .grant_i(grant_sch_fifo)
);    
       
cntr_bs#(.READ(READ),.WRITE(WRITE),.RA_POS(RA_POS),.CA(CA),.RA(RA),.DQ(DQ),.IDX(IDX)) BankScheduler
(
   .clk(clk),         // Input clock
   .rst_n(rst_n),     // Synchronous reset
   .ready(ready[0]),     //ready bit from arbiter      
   .mode(READ),       // Input controller mode to switch memory interface bus into write mode 
   .valid_i(valid_fifo_sch),   // Input valid bit from txn controller/bank scheduler fifo
   .dq_i(dq_i),       // Input data from txn controller/bank scheduler fifo
   .idx_i(idx_i),     // Input index from txn controller/bank scheduler fifo
   .ra_i(ra_i),       // Input row address from txn controller/bank scheeduler fifo
   .ca_i(ca_i),       // Input col address from txn controller/bank scheeduler fifo
   .t_i(t_i),         // Input type from txn controller/bank scheeduler fifo
   .valid_o(valid_sch_arbiter), // Output valid for arbiter
   .dq_o(dq_sch_arb),       // Output data from from data path
   .idx_o(idx_sch_arb),     // Output index from from data path
   .ra_o(ra_sch_arb),       // output row address from data path
   .ca_o(ca_sch_arb),       // output col address from data path
   .t_o(t_sch_arb),         // Output type from scheduler fifo
   .rd_empty(rd_empty),     // Output empty signal for read requests for each bank
   .grant(grant_sch_fifo),     // pop from (Mapper-schedular) FIFO      
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


Arbiter #(.IDX(IDX),.RA(RA),.CA(CA),.DQ(DQ)) arbiter
(
    .clk(clk),
    .rst_n(rst_n),
    .valid({15'b0,valid_sch_arbiter}),
    .flag(1'b1) ,
    .data_i({  {15*DQ{1'b0}} , dq_sch_arb}) ,
    .idx_i({  {15*IDX{1'b0}} ,idx_sch_arb}) ,
    .row_i({  {15*RA{1'b0}} ,ra_sch_arb}) ,
    .col_i({  {15*CA{1'b0}} ,ca_sch_arb}) ,
    .t_i({  {15{1'b0}} ,t_sch_arb}),
    .data_o(dq_o) ,
    .idx_o(idx_o)  ,
    .row_o(ra_o)  ,
    .col_o(ca_o)  ,
    .t_o(t_o),
    .ba_o(ba_o) ,
    .bg_o(bg_o), 
    //.wr_en(wr_en),
    .ready(ready)
);






endmodule