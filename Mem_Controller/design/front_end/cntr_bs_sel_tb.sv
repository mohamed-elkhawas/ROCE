//`define rand_(len) $urandom_range(2^(len)-1,0)
module cntr_bs_sel_tb();
// pragma attribute txn_controller_tb partition_module_xrt

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
reg                    clk;
reg  [FIFO_NUM -1 : 0] full;
reg  [FIFO_NUM -1 : 0] mid;
reg  [FIFO_NUM -1 : 0] empty;
reg                    valid ;
reg [RA        -1 : 0] ra_i ;
reg                    t_i ;
reg [FIFO_NUM -1 : 0][RA -1 : 0] last_ra;

//output signals
wire [FIFO_NUM -1 : 0] push;


//always #5 clk = ~clk;
/*integer k;

initial begin
    clk = 0 ;
    valid = 1'b1 ;
    repeat(200) begin 
        @ (posedge clk);
        // new input request
        {t_i , ra_i} = {$urandom%2 , `rand_(FIFO_NUM)}; 
        // random state of fifos
        {full , mid} = {`rand_(FIFO_NUM),`rand_(FIFO_NUM)};
        empty = ~full ;
        mid = mid & empty ; //if a fifo is empty then it can not have a mid signal
        for(k = 0 ; k< FIFO_NUM ; k=k+1) 
            last_ra[k] = `rand_(RA);
    end
end*/
cntr_bs_sel#(.RA(RA),.READ(READ),.WRITE(WRITE),.RD_FIFO_NUM(RD_FIFO_NUM),.WR_FIFO_NUM(WR_FIFO_NUM)) selector
(
   .valid_i(valid),   // Input valid bit from txn controller/bank scheduler fifo
   .ra_i(ra_i),       // Input row address from txn controller/bank scheeduler fifo
   .t_i(t_i),         // Input type from txn controller/bank scheeduler fifo
   .last_ra(last_ra), // Output last row addresses from all bank scheduler fifos
   .full(full),       // Output full signals of scheduler fifos
   .mid(mid),         // Output mid signals of scheduler fifos
   .empty(empty),     // Output empty signals of scheduler fifos
   .push(push)        // Output push signals for all fifos
);

endmodule