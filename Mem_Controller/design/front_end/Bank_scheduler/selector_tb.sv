`define READ  1'b1
`define WRITE 1'b0

//request definintions
`define CID_POS         0
`define CA_POS          4
`define RA_POS          14
`define BA_POS          30
`define BG_POS          32
`define DATA_POS        33
`define TYPE_POS        49
`define INDEX_POS       50

`define CID_BITS        4
`define CA_BITS         10
`define RA_BITS         16
`define BA_BITS         2
`define BD_BITS         2
`define DATA_BITS       16
`define TYPE_BITS       1
`define INDEX_BITS      7
`define REQ_SIZE        `CID_BITS+`CA_BITS+`RA_BITS+`BA_BITS+`BG_BITS+` DATA_BITS+`TYPE_BITS+`INDEX_BITS  

//read requests definitions
`define RA_POS_READ     0
`define INDEX_POS_READ  16
`define REQ_SIZE_READ  `RA_BITS+`INDEX_BITS

//write requests definitions
`define RA_POS_WRITE    0
`define DATA_POS_WRITE  16
`define INDEX_POS_WRITE 32
`define REQ_SIZE_WRITE  `REQ_SIZE_READ+`DATA_BITS

//selector+FIFO definitions
`define ARR_SIZE_RD     4 
`define ARR_SIZE_WR     2
`define ARR_NUM_WR      3
`define ARR_NUM_RD      4
`define NUM_OF_BUFFERS  `ARR_NUM_WR+`ARR_NUM_RD



module Selector_tb();

//inputs
reg  clk;
reg  rst_n;
reg  [`REQ_SIZE-1:0] in;
reg  valid ;
reg  [`NUM_OF_BUFFERS-1:0] pop;

//intermediate signals
wire  [`NUM_OF_BUFFERS-1:0] grant_o , mid, valid_o ;
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




Selector #(.RA_BITS(`RA_BITS),.RA_POS(`RA_POS) , .READ(`READ), .WRITE (`WRITE), .ARR_NUM_WR(`ARR_NUM_WR), .ARR_NUM_RD(`ARR_NUM_RD)) selector
(.clk(clk), .rst_n(rst_n), .valid(valid), .in_type(in[`TYPE_POS]),.empty(~valid_o) , .full(~grant_o), .mid(mid),
 .last_addr(last_addr),.in_addr(in[`RA_POS +: `RA_BITS]), .push(push));

endmodule