module cntr_bs_dp_tb();

parameter READ  = 1'b0;
parameter WRITE = 1'b1;

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
parameter  IDX      = 6;
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
//*****************************************************************************
// Inputs                                                    
//*****************************************************************************  
reg clk;
reg rst_n;
reg valid;
reg [FIFO_NUM -1 : 0] pop;
reg [FIFO_NUM -1 : 0] push;

reg [DQ  -1 :0] dq_i;
reg [IDX -1 :0] idx_i;
reg [RA  -1 :0] ra_i;
reg [CA  -1 :0] ca_i;
reg             type_i;


//*****************************************************************************
// outputs                                                    
//*****************************************************************************  
wire [FIFO_NUM -1 : 0] full  ;
wire [FIFO_NUM -1 : 0] mid  ;
wire [FIFO_NUM -1 : 0] empty  ;

wire [DQ  -1 :0] dq_o;
wire [IDX -1 :0] idx_o;
wire [RA  -1 :0] ra_o;
wire [CA  -1 :0] ca_o;
wire             type_o;
wire [FIFO_NUM -1 : 0] [BURST -1 : 0] first_burst;

wire grant ;
wire [RA_ALL -1 : 0] last_ra;


byte rd_arr[4] = {8'd0, 8'd1, 8'd2, 8'd3};
byte wr_arr[3] = {8'd4, 8'd5, 8'd6};
always #5 clk = ~clk;

initial begin
    clk=0;
    rst_n = 0;
    #6
    rst_n=1;
    pop = 7'd0;
    push = 7'd0;
    valid = 1'b1 ;
    {idx_i,dq_i,ra_i,ca_i,type_i}  = {$urandom(),$urandom()};
    repeat(10) begin //insert new input data
        @ (posedge clk);
        {idx_i,dq_i,ra_i,ca_i,type_i}  = {$urandom(),$urandom()};
        if(type_i == READ )  begin push = 7'b1<<rd_arr[$urandom%4];  end
        if(type_i == WRITE ) begin push = 7'b1<<wr_arr[$urandom%3];  end
    end
    repeat(5) begin //drain new data
        @ (posedge clk);
        pop = 7'b1<<rd_arr[$urandom%4];
    end
    repeat(5) begin //drain new data
        @ (posedge clk);
        pop = 7'b1<<wr_arr[$urandom%3];
    end
end



cntr_bs_dp #(.RD_FIFO_NUM(RD_FIFO_NUM), .WR_FIFO_NUM(WR_FIFO_NUM), .RD_FIFO_SIZE(RD_FIFO_SIZE), .WR_FIFO_SIZE(WR_FIFO_SIZE), .DQ(DQ), .IDX(IDX), .RA(RA), .CA(CA),.RA_POS(RA_POS),.READ(READ),.WRITE(WRITE)) bs_dp
(
   .clk(clk),         // Input clock
   .rst_n(rst_n),     // Synchronous reset
   .push(push),       // Input push signals in a one-hot style to the bank scheduler fifos
   .pop(pop),         // Input pop signals in a one-hot style to the bank scheduler fifos
   .valid_i(valid),   // Input valid bit from txn controller/bank scheduler fifo
   .dq_i(dq_i),       // Input data from txn controller/bank scheduler fifo
   .idx_i(idx_i),     // Input index from txn controller/bank scheduler fifo
   .ra_i(ra_i),       // Input row address from txn controller/bank scheeduler fifo
   .ca_i(ca_i),       // Input col address from txn controller/bank scheeduler fifo
   .last_ra(last_ra), // Output last row addresses from all bank scheduler fifos
   .full(full),       // Output full signals of scheduler fifos
   .mid(mid),         // Output mid signals of scheduler fifos
   .empty(empty),     // Output valid signals of scheduler fifos
   .dq_o(dq_o),       // Output data from txn controller/bank scheduler fifo
   .idx_o(idx_o),     // Output index from txn controller/bank scheduler fifo
   .ra_o(ra_o),       // output row address from txn controller/bank scheeduler fifo
   .ca_o(ca_o),       // output col address from txn controller/bank scheeduler fifo
   .type_o(type_o),   // Output type from scheduler fifo
   .first_burst(first_burst),      //Output head burst of each fifo
   .grant(grant)
);

endmodule