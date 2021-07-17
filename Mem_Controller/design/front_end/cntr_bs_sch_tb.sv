module cntr_bs_sch_tb();

parameter READ  = 1'b1;
parameter WRITE = 1'b0;

//veloce request format
parameter  CID_POS  = 0;
parameter  CA_POS   = 4;
parameter  RA_POS   = 14;
parameter  BA_POS   = 30;
parameter  BG_POS   = 32;
parameter  IDX_POS  = 34;
parameter  TYPE_POS = 41;
parameter  DQ_POS   = 42;
parameter  CID      = 4;
parameter  CA       = 10;
parameter  RA       = 16;
parameter  BA       = 2;
parameter  BG       = 2;
parameter  DQ       = 16;
parameter  TYPE     = 1;
parameter  IDX      = 7;
parameter  REQ_SIZE = CID + CA + RA + BA + BG + DQ + TYPE + IDX ; 

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

//inputs
reg clk;
reg rst_n;
reg mode;
reg ready;
reg                   valid_in_fifo; // valid bit from input source to fifos
reg [FIFO_NUM -1 : 0] push;
reg [DQ  -1 :0] dq_i;
reg [IDX -1 :0] idx_i;
reg [RA  -1 :0] ra_i;
reg [CA  -1 :0] ca_i;
reg             type_i;

//intermediate signals
wire [FIFO_NUM -1 : 0][BURST -1  : 0] burst_i ;  //input burst addresses from fifos
wire [FIFO_NUM -1 : 0] empty;  //valid output signals from fifos to scheduler
wire [FIFO_NUM -1 : 0] pop;    //pop siganls from scheduler to fifos

//output signals
wire             valid_sch_arbiter ;
wire [DQ  -1 :0] dq_o;
wire [IDX -1 :0] idx_o;
wire [RA  -1 :0] ra_o;
wire [CA  -1 :0] ca_o;
wire             type_o;

always #5 clk = ~clk;
byte rd_arr[4] = {8'd0, 8'd1, 8'd2, 8'd3};
byte wr_arr[3] = {8'd4, 8'd5, 8'd6};

/*integer  max_ ; 
task fill(idx,type_);
     max_ =  (type_ == READ)? RD_FIFO_SIZE : WR_FIFO_SIZE ;
     @ (posedge clk)
     push = 1<<idx;
    for(integer k = 0 ; k<max_ ; k=k+1 ) begin
        {idx_i,dq_i,ra_i,ca_i}  = {$urandom(),$urandom()};
    end
    
        
endtask*/


initial begin
    clk=0;
    rst_n = 0;
    mode = READ ; 
    ready = 1'b0;
    #6
    rst_n = 1;
    valid_in_fifo = 1'b1;
    //first fill in the fifos with random data
    repeat(30) begin //insert new input data
        @ (posedge clk);
        {idx_i,dq_i,ra_i,ca_i,type_i}  = {$urandom(),$urandom()};
        if(type_i == READ )  begin push = 7'b1<<rd_arr[$urandom%4];  end
        if(type_i == WRITE ) begin push = 7'b1<<wr_arr[$urandom%3];  end
    end
    @ (posedge clk);
    valid_in_fifo = 1'b0;
    // turn on scheduler
    ready = 1'b1;
end

cntr_bs_sch #(.READ(READ), .WRITE (WRITE), .RD_FIFO_NUM(RD_FIFO_NUM), .WR_FIFO_NUM(WR_FIFO_NUM), .BURST(BURST) ) scheduler
(
   .clk(clk),                  // Input clock
   .rst_n(rst_n),              // Synchronous reset                                                     -> active low
   .ready(ready),              // Ready signal from arbiter                                             -> active high
   .mode(mode),                // Input controller mode to switch memory interface bus into write mode 
   .burst_i(burst_i),          // Input burst addresses
   .empty(empty),              // Input valid from fifos                
   .pop(pop),                  // Output grant signals to fifos
   .valid_o(valid_sch_arbiter) //Output valid for arbiter
);


cntr_bs_dp #(.RD_FIFO_NUM(RD_FIFO_NUM), .WR_FIFO_NUM(WR_FIFO_NUM), .RD_FIFO_SIZE(RD_FIFO_SIZE), .WR_FIFO_SIZE(WR_FIFO_SIZE), .DQ(DQ), .IDX(IDX), .RA(RA), .CA(CA),.RA_POS(RA_POS),.READ(READ),.WRITE(WRITE)) bs_dp
(
   .clk(clk),        // Input clock
   .rst_n(rst_n),    // Synchronous reset
   .push(push),      // Input pop signals in a one-hot style to the bank scheduler fifos
   .pop(pop),         // Input pop signals in a one-hot style to the bank scheduler fifos
   .valid_i(valid_in_fifo),   // Input valid bit from txn controller/bank scheduler fifo
   .dq_i(dq_i),       // Input data from txn controller/bank scheduler fifo
   .idx_i(idx_i),     // Input index from txn controller/bank scheduler fifo
   .ra_i(ra_i),       // Input row address from txn controller/bank scheeduler fifo
   .ca_i(ca_i),       // Input col address from txn controller/bank scheeduler fifo
   .empty(empty),     // Output valid signals of scheduler fifos
   .dq_o(dq_o),       // Output data from txn controller/bank scheduler fifo
   .idx_o(idx_o),     // Output index from txn controller/bank scheduler fifo
   .ra_o(ra_o),       // output row address from txn controller/bank scheeduler fifo
   .ca_o(ca_o),       // output col address from txn controller/bank scheeduler fifo
   .first_burst(burst_i), //Output head burst of each fifo
   .type_o(type_o)   // Output type from scheduler fifo
);

endmodule