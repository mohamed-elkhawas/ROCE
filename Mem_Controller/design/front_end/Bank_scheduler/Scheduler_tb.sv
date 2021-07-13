module Scheduler_tb();

localparam READ  = 1'b1,
           WRITE = 1'b0;

//veloce request format
localparam  CID_POS         =0,
            CA_POS          =4,
            RA_POS          =14,
            BA_POS          =30,
            BD_POS          =32,
            DATA_POS        =33,
            TYPE_POS        =49,
            INDEX_POS       =50,
            CID_BITS        =4,
            CA_BITS         =10,
            RA_BITS         =16,
            BA_BITS         =2,
            BD_BITS         =2,
            DATA_BITS       =16,
            TYPE_BITS       =1,
            INDEX_BITS      =7,
            REQ_SIZE        =CID_BITS+CA_BITS+RA_BITS+BA_BITS+BD_BITS+DATA_BITS+TYPE_BITS+INDEX_BITS ; 

//scheduler stored read requests format
localparam  RA_POS_READ     =0,
            INDEX_POS_READ  =16,
            REQ_SIZE_READ   =RA_BITS+INDEX_BITS;

//scheduler stored write requests format
localparam  RA_POS_WRITE    =0,
            DATA_POS_WRITE  =16,
            INDEX_POS_WRITE =32,
            REQ_SIZE_WRITE  =REQ_SIZE_READ+DATA_BITS;

//scedulaer parameters
localparam  ARR_SIZE_RD     =4,
            ARR_SIZE_WR     =2,
            ARR_NUM_WR      =3,
            ARR_NUM_RD      =4,
            NUM_OF_BUFFERS  =ARR_NUM_WR+ARR_NUM_RD;


localparam BURST_BITS = RA_BITS+CA_BITS-4;

//inputs
reg  clk;
reg  rst_n;

reg  valid ;

//intermediate signals
wire [(REQ_SIZE_READ*ARR_NUM_RD)-1:0]  in_rd;// input read data from fifos 
wire [(REQ_SIZE_WRITE*ARR_NUM_WR)-1:0] in_wr;// input write data from fifos
wire [NUM_OF_BUFFERS-1:0] pop; //pop siganls from scheduler to fifos
wire [NUM_OF_BUFFERS-1:0] grant_o , mid, valid_o ;
wire  [(( `NUM_OF_BUFFERS) * (`RA_BITS)) -1 :0] last_addr; 

//output signals
wire [`NUM_OF_BUFFERS-1:0] push;
wire [((`ARR_NUM_RD) * (`REQ_SIZE_READ))-1:0] data_out_read;
wire [((`ARR_NUM_WR) * (`REQ_SIZE_WRITE))-1:0] data_out_write;
always #5 clk = ~clk;

integer i ,f;
initial begin
    $monitor("(`NUM_OF_BUFFERS)*(`REQ_SIZE_READ) = %d `NUM_OF_BUFFERS*`REQ_SIZE_READ = %d",(`NUM_OF_BUFFERS)*(`REQ_SIZE_READ),`NUM_OF_BUFFERS*`REQ_SIZE_READ);
    //`ARR_NUM_RD,`ARR_NUM_WR);
    //f=$fopen("output.txt","w");
    clk=0;
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
                $monitor("%h\n",{in[`INDEX_POS+:`INDEX_BITS],in[`RA_POS +:`RA_BITS]});
            if(valid == 1'b1 && in[`TYPE_POS] == (`WRITE))
                $monitor("%h\n",{in[`INDEX_POS_WRITE+:`INDEX_BITS],in[`DATA_POS+:`DATA_BITS],in[`RA_POS+:`RA_BITS]});
        end
        /*repeat(200) begin //update valid signal before the next positive edge as valid is a mealy ouput from sender
            @ (negedge clk);
            valid = $urandom%2;
        end*/
    join
    //$fclose(f);
end


genvar g;
generate
    for (g=0; g < `ARR_NUM_RD; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(`REQ_SIZE_READ), .DATA_DEPTH(`ARR_SIZE_RD), .RA_POS(`RA_POS_READ) , .RA_BITS(`RA_BITS)) rd_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({in[`INDEX_POS+:`INDEX_BITS],in[`RA_POS +:`RA_BITS]}),.valid_i(push[g]),.grant_o(grant_o[g]),
        .last_addr(last_addr[g*`RA_BITS +: `RA_BITS]),.mid(mid[g]),.data_o(data_out_read[(g*(`REQ_SIZE_READ)) +: (`REQ_SIZE_READ)]),.valid_o(valid_o[g]),.grant_i(pop[g]));    
    end
    for (g= `ARR_NUM_RD; g < `NUM_OF_BUFFERS; g=g+1)  begin
       generic_fifo #(.DATA_WIDTH(`REQ_SIZE_WRITE) ,.DATA_DEPTH(`ARR_SIZE_WR), .RA_POS(`RA_POS_WRITE) , .RA_BITS(`RA_BITS)) wr_fifo
        (.clk(clk),.rst_n(rst_n),.data_i({in[`INDEX_POS_WRITE+:`INDEX_BITS],in[`DATA_POS+:`DATA_BITS],in[`RA_POS+:`RA_BITS]}),.valid_i(push[g]),.grant_o(grant_o[g]),
        .last_addr(last_addr[g*`RA_BITS +: `RA_BITS]),.mid(mid[g]),.data_o(data_out_write[(g-(`ARR_NUM_RD))*(`REQ_SIZE_WRITE)+:(`REQ_SIZE_WRITE)]),.valid_o(valid_o[g]),.grant_i(pop[g]));
    end      
endgenerate



Scheduler #(.READ(READ), .WRITE (WRITE), .ARR_NUM_RD(ARR_NUM_RD), .ARR_NUM_WR(ARR_NUM_WR), .REQ_SIZE_READ(REQ_SIZE_READ), .REQ_SIZE_WRITE(REQ_SIZE_WRITE), .BURST_BITS(BURST_BITS)) scheduler
(
   .clk(clk), .rst_n(rst_n), ready , mode, //mode-->read or write draining
   .in_rd(in_rd) ,// input read data 
   .in_wr(in_wr) ,// input write data
   .empty(~valid_o , 
   .pop(pop)       ,
   output  valid_o //to arbiter           
);
Selector #(.RA_BITS(`RA_BITS),.RA_POS(`RA_POS) , .READ(`READ), .WRITE (`WRITE), .ARR_NUM_WR(`ARR_NUM_WR), .ARR_NUM_RD(`ARR_NUM_RD)) selector
(.clk(clk), .rst_n(rst_n), .valid(valid), .in_type(in[`TYPE_POS]),.empty(~valid_o) , .full(~grant_o), .mid(mid),
 .last_addr(last_addr),.in_addr(in[`RA_POS +: `RA_BITS]), .push(push));

endmodule