module cntr_bs_dp_tb();

localparam READ  = 1'b1,
           WRITE = 1'b0;

//veloce request format
localparam  CID_POS  = 0,
            CA_POS   = 4,
            RA_POS   = 14,
            BA_POS   = 30,
            BG_POS   = 32,
            DQ_POS   = 33,
            TYPE_POS = 49,
            IDX_POS  = 50,
            CID      = 4,
            CA       = 10,
            RA       = 16,
            BA       = 2,
            BG       = 2,
            DQ       = 16,
            TYPE     = 1,
            IDX      = 7,
            REQ_SIZE = CID + CA + RA + BA + BG + DQ + TYPE + IDX ; 

//scheduler stored read requests format
localparam  RD_RA_POS  = 0,
            RD_IDX_POS = 16,
            RD_SIZE    = RA + IDX;

//scheduler stored write requests format
localparam  WR_RA_POS  = 0,
            WR_DQ_POS  = 16,
            WR_IDX_POS = 32,
            WR_SIZE    = RD_SIZE + DQ;

//fifos parameters
parameter  RD_FIFO_SIZE = 4;
parameter  WR_FIFO_SIZE = 2;
parameter  RD_FIFO_NUM  = 4;
parameter  WR_FIFO_NUM  = 3;
parameter  FIFO_NUM     = RD_FIFO_NUM + WR_FIFO_NUM;


localparam BURST = RA+CA-4;
localparam RA_ALL   = RA * FIFO_NUM    ;
//*****************************************************************************
// Inputs                                                    
//*****************************************************************************  
reg clk;
reg rst_n;
reg valid;
reg [FIFO_NUM -1 : 0] pop;
reg [FIFO_NUM -1 : 0] push;

reg [WR_SIZE  -1 : 0] in;
// new input wires
wire [DQ  -1 :0] dq_i;
wire [IDX -1 :0] idx_i;
wire [RA  -1 :0] ra_i;
wire [CA  -1 :0] ca_i;
assign {idx_i,dq_i,ra_i,ca_i} = in ;

//*****************************************************************************
// outputs                                                    
//*****************************************************************************  
wire [FIFO_NUM -1 : 0] full  ;
wire [FIFO_NUM -1 : 0] mid  ;
wire [FIFO_NUM -1 : 0] valid_o , empty  ;
assign empty = ~valid_o;

wire [WR_SIZE  -1 : 0] out ; 
wire [DQ  -1 :0] dq_o;
wire [IDX -1 :0] idx_o;
wire [RA  -1 :0] ra_o;
wire [CA  -1 :0] ca_o;
assign out = {idx_o,dq_o,ra_o,ca_o};

wire grant ;
wire [RA_ALL -1 : 0] last_ra;


byte rd_arr[4] = {8'd1, 8'd2, 8'd4, 8'd8};
byte wr_arr[3] = {8'd16, 8'd32, 8'd64};
always #5 clk = ~clk;

initial begin
    //$monitor("(`NUM_OF_BUFFERS)*(`REQ_SIZE_READ) = %d `NUM_OF_BUFFERS*`REQ_SIZE_READ = %d",(`NUM_OF_BUFFERS)*(`REQ_SIZE_READ),`NUM_OF_BUFFERS*`REQ_SIZE_READ);
    clk=0;
    rst_n = 0;
    #6
    rst_n=1;
    pop = 7'd0;
    push = 7'd0;
    valid = 1'b1 ;
    in = {$urandom(),$urandom()};
    repeat(10) begin //insert new input data
        @ (posedge clk);
        in = {$urandom(),$urandom()};
        if(in[TYPE_POS] == READ )  begin push = rd_arr[$urandom%4];  end
        if(in[TYPE_POS] == WRITE ) begin push = wr_arr[$urandom%3];  end
    end
    repeat(5) begin //drain new data
        @ (posedge clk);
        pop = rd_arr[$urandom%4];
    end
    repeat(5) begin //drain new data
        @ (posedge clk);
        pop = wr_arr[$urandom%3];
    end
end



cntr_bs_dp #(.RD_FIFO_NUM(RD_FIFO_NUM), .WR_FIFO_NUM(WR_FIFO_NUM), .RD_FIFO_SIZE(RD_FIFO_SIZE), .WR_FIFO_SIZE(WR_FIFO_SIZE), .DQ(DQ), .IDX(IDX), .RA(RA), .CA(CA),.RA_POS_READ(RD_RA_POS), .RA_POS_WRITE(WR_RA_POS) ) bs_dp
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
   .valid_o(valid_o), // Output valid signals of scheduler fifos
   .dq_o(dq_o),       // Output data from txn controller/bank scheduler fifo
   .idx_o(idx_o),     // Output index from txn controller/bank scheduler fifo
   .ra_o(ra_o),       // output row address from txn controller/bank scheeduler fifo
   .ca_o(ca_o),       // output col address from txn controller/bank scheeduler fifo
   .grant(grant)
);

endmodule