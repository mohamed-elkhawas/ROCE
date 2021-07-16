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
parameter  RD_RA_POS  = 0;
parameter  RD_IDX_POS = 16;
parameter  RD_SIZE    = RA + IDX + CA + TYPE;

//scheduler stored write requests format
parameter  WR_RA_POS  = 0;
parameter  WR_DQ_POS  = 16;
parameter  WR_IDX_POS = 32;
parameter  WR_SIZE    = RD_SIZE + DQ ;

//fifos parameters
parameter  RD_FIFO_SIZE = 4;
parameter  WR_FIFO_SIZE = 2;
parameter  RD_FIFO_NUM  = 4;
parameter  WR_FIFO_NUM  = 3;


localparam FIFO_NUM     = RD_FIFO_NUM + WR_FIFO_NUM;
localparam BURST        = RA+CA-4;
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
wire [FIFO_NUM -1 : 0] valid_o , empty  ;
assign empty = ~valid_o;

wire [WR_SIZE  -1 : 0] out ; 
wire [DQ  -1 :0] dq_o;
wire [IDX -1 :0] idx_o;
wire [RA  -1 :0] ra_o;
wire [CA  -1 :0] ca_o;
wire             type_o;
assign out = {idx_o,dq_o,ra_o,ca_o,type_o};

wire grant ;
wire [RA_ALL -1 : 0] last_ra;


byte rd_arr[4] = {8'd0, 8'd1, 8'd2, 8'd3};
byte wr_arr[3] = {8'd4, 8'd5, 8'd6};
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
    {idx_i,dq_i,ra_i,ca_i,type_i}  = {$urandom(),$urandom()};
    repeat(10) begin //insert new input data
        @ (posedge clk);
        {idx_i,dq_i,ra_i,ca_i,type_i}  = {$urandom(),$urandom()};
        if(type_i == READ )  begin push = 7'b1<<rd_arr[0];  end
        if(type_i == WRITE ) begin push = 7'b1<<wr_arr[2];  end
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



cntr_bs_dp #(.RD_FIFO_NUM(RD_FIFO_NUM), .WR_FIFO_NUM(WR_FIFO_NUM), .RD_FIFO_SIZE(RD_FIFO_SIZE), .WR_FIFO_SIZE(WR_FIFO_SIZE), .DQ(DQ), .IDX(IDX), .RA(RA), .CA(CA),.RA_POS_READ(RD_RA_POS), .RA_POS_WRITE(WR_RA_POS),.READ(READ),.WRITE(WRITE)) bs_dp
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
   .type_o(type_o),  // Output type from scheduler fifo
   .grant(grant)
);

endmodule