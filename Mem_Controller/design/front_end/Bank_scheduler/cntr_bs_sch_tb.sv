/*module cntr_bs_sch_tb();

localparam READ  = 1'b1,
           WRITE = 1'b0;

//veloce request format
localparam  CID_POS    = 0,
            CA_POS     = 4,
            RA_POS     = 14,
            BA_POS     = 30,
            BD_POS     = 32,
            DATA_POS   = 33,
            TYPE_POS   = 49,
            INDEX_POS  = 50,
            CID        = 4,
            CA         = 10,
            RA         = 16,
            BA         = 2,
            BD         = 2,
            DATA       = 16,
            TYPE       = 1,
            INDEX      = 7,
            REQ_SIZE   = CID+CA+RA+BA+BD+DATA+TYPE+INDEX ; 

//scheduler stored read requests format
localparam  RA_POS_READ     =0,
            INDEX_POS_READ  =16,
            REQ_SIZE_READ   =RA+INDEX;

//scheduler stored write requests format
localparam  RA_POS_WRITE    =0,
            DATA_POS_WRITE  =16,
            INDEX_POS_WRITE =32,
            REQ_SIZE_WRITE  =REQ_SIZE_READ+DATA;

//fifos parameters
parameter  RD_FIFO_SIZE = 4;
parameter  WR_FIFO_SIZE = 2;
parameter  RD_FIFO_NUM  = 4;
parameter  WR_FIFO_NUM  = 3;
parameter  FIFO_NUM     = RD_FIFO_NUM + WR_FIFO_NUM;


localparam BURST = RA+CA-4;

//inputs
reg clk;
reg rst_n;
reg mode;
reg ready;
reg [FIFO_NUM       -1 : 0] valid_in_fifo;
reg [REQ_SIZE_WRITE -1 : 0] write_input;
reg [REQ_SIZE_READ  -1 : 0] read_input;

//inputs to fifos before scheduler
reg   [RA-1    : 0 ] row_i ;
reg   [CA-1    : 0 ] col_i ;
reg  valid ;

//intermediate signals
wire [(BURST*RD_FIFO_NUM) -1  : 0] rd_i ;           //input burst addresses from read fifos
wire [(BURST*WR_FIFO_NUM) -1  : 0] wr_i ;           //input burst addresses from write fifos
wire [FIFO_NUM            -1  : 0] valid_fifo_sch;  //valid output signals from fifos to scheduler
wire [FIFO_NUM            -1  : 0] grant_sch_fifo;  //pop siganls from scheduler to fifos
wire [FIFO_NUM            -1 :  0] grant_o ;
wire [FIFO_NUM            -1 :  0] mid  ;

//output signals
wire                   valid_sch_arbiter ;
wire [FIFO_NUM -1 : 0] grant_fifo_input  ; //grant from fifo to input source
wire [FIFO_NUM -1 : 0] mid  ;
always #5 clk = ~clk;

integer i ,f;
initial begin
    //$monitor("(`FIFO_NUM)*(`REQ_SIZE_READ) = %d `FIFO_NUM*`REQ_SIZE_READ = %d",(FIFO_NUM)*(REQ_SIZE_READ),`FIFO_NUM*`REQ_SIZE_READ);
    //`ARR_NUM_RD,`ARR_NUM_WR);
    //f=$fopen("output.txt","w");
    /*clk=0;
    rst_n = 0;
    #6
    rst_n=1;
    pop = 7'd0;
    valid = 1'b1 ;
    fork  //use fork for  parallel operations
        repeat(200) begin //insert new input data
            @ (posedge clk);
            in={$urandom(),$urandom()};
            // now write the stored requests in fifo to compare with results
           //$fwrite(f,"%h\n",5);
            if(valid == 1'b1 && in[`TYPE_POS] == (`READ))
                $monitor("%h\n",{in[`INDEX_POS+:`INDEX],in[`RA_POS +:`RA]});
            if(valid == 1'b1 && in[`TYPE_POS] == (`WRITE))
                $monitor("%h\n",{in[`INDEX_POS_WRITE+:`INDEX],in[`DATA_POS+:`DATA],in[`RA_POS+:`RA]});
        end
        /*repeat(200) begin //update valid signal before the next positive edge as valid is a mealy ouput from sender
            @ (negedge clk);
            valid = $urandom%2;
        end
    join
    //$fclose(f);
end


genvar g;
generate
    for (g=0; g < RD_FIFO_NUM; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(REQ_SIZE_READ), .DATA_DEPTH(RD_FIFO_SIZE), .RA_POS(RA_POS_READ) , .RA(RA)) rd_fifo
        (
            .clk(clk),
            .rst_n(rst_n),
            .data_i(read_input),
            .valid_i(valid_in_fifo[g]),
            .grant_o(grant_fifo_input[g]),
            .last_addr(rd_i[g*BURST +: BURST]),
            .mid(mid[g]),
            .data_o(data_out_read[(g*(REQ_SIZE_READ)) +: (REQ_SIZE_READ)]),
            .valid_o(valid_fifo_sch[g]),
            .grant_i(grant_o[g])
        );    
    end
    for (g= RD_FIFO_NUM; g < FIFO_NUM; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(REQ_SIZE_WRITE) ,.DATA_DEPTH(WR_FIFO_SIZE), .RA_POS(RA_POS_WRITE) , .RA(RA)) wr_fifo
        (
            .clk(clk),
            .rst_n(rst_n),
            .data_i(write_input),
            .valid_i(valid_in_fifo[g]),
            .grant_o(grant_fifo_input[g]),
            .last_addr(wr_i[g*BURST +: BURST]),
            .mid(mid[g]),
            .data_o(data_out_write[(g-(RD_FIFO_NUM))*(REQ_SIZE_WRITE)+:(REQ_SIZE_WRITE)]),
            .valid_o(valid_fifo_sch[g]),
            .grant_i(grant_o[g])
        );
    end      
endgenerate



cntr_bs_sch #(.READ(READ), .WRITE (WRITE), .RD_FIFO_NUM(RD_FIFO_NUM), .WR_FIFO_NUM(WR_FIFO_NUM), .BURST(BURST) ) scheduler
(
   .clk(clk),                  // Input clock
   .rst_n(rst_n),              // Synchronous reset                                                     -> active low
   .ready(ready),              // Ready signal from arbiter                                             -> active high
   .mode(mode),                // Input controller mode to switch memory interface bus into write mode 
   .rd_i(rd_i),                // Input read burst address
   .wr_i(wr_i),                // Input write burst address
   .valid_i(valid_fifo_sch),   // Input valid from fifos                
   .grant_o(grant_sch_fifo),   // Output grant signals to fifos
   .valid_o(valid_sch_arbiter) //Output valid for arbiter
);


Selector #(.RA_BITS(RA_BITS),.RA_POS(RA_POS) , .READ(READ), .WRITE (WRITE), .ARR_NUM_WR(WR_FIFO_NUM), .ARR_NUM_RD(RD_FIFO_NUM) selector
(.clk(clk), .rst_n(rst_n), .valid(valid), .in_type(in[TYPE_POS]),.empty(~valid_o) , .full(~grant_o), .mid(mid),
 .last_addr(last_addr),.in_addr(in[RA_POS +: RA]), .push(push));

endmodule*/