/*`include "BS_Definitions.svh"

module BankScheduler_tb();

/***inputs**
reg clk;
reg rst_n;
reg grant_i;
reg [`REQUEST_SIZE-1:0] in;
reg valid_i ; 


/***outputs**
wire [`REQUEST_SIZE-1:0] out ;
wire req;
wire fifo_grant_to_mapper;

//////////// fifo - scheduler wires

//from fifo to scehduler
wire [`REQUEST_SIZE-1:0] data_out ; 
wire valid_o;


// from scheduler to fifo
wire grant_o;

always #5 clk = ~clk;

initial begin   
    /****************************************************************************************
        -scenario #1.
        -eight mixed type requests with different addresses .
        -input request format ---> (`VALID_BIT+`ADDR_BITS+`INDEX_BITS+`TYPE_BIT+`DATA_BITS )
    **************************************************************************************** 
    
    clk=0;
    rst_n = 0;
    grant_i=0;
    #6
    rst_n=1;
    valid_i=1'b1;
    //@(posedge clk)
    in={8'hff,8'd1,`WRITE,7'd0};
    #10
    in={8'hff,8'd2,`WRITE,7'd0};
    #10
    in={8'hff,8'd3,`READ,7'd0};
    #10
    in={8'hdf,8'd4,`WRITE,7'd0};
    #10
    in={8'haf,8'd5,`WRITE,7'd0};
    #10
    in={8'hdf,8'd6,`WRITE,7'd0};
    #10
    in={8'hdf,8'd7,`WRITE,7'd0};
    grant_i=1;
    #10
    in={8'hbf,8'd8,`WRITE,7'd0}; 
    #10
    in={8'haf,8'd9,`READ,7'd0};
    /*#10
    in={8'hdf,8'd4,`WRITE,7'd0}; 
    #10
    in={8'hdf,8'd6,`WRITE,7'd0};

end

generic_fifo #(.DATA_WIDTH(`REQUEST_SIZE) ,.DATA_DEPTH(4)) fifo
( .clk(clk),.rst_n(rst_n), .data_i(in),.valid_i(valid_i),.grant_o(fifo_grant_to_mapper),.data_o(data_out), .valid_o(valid_o),.grant_i(grant_o) ,.test_mode_i(1'b0));


BankScheduler #(.REQ_SIZE(`REQUEST_SIZE),.TYPE_POS(`TYPE_POS),.ROW_BITS(`ROW_BITS),.ROW_POS(`ROW_POS),.BURST_POS(`BURST_POS),.BURST_BITS(`BURST_BITS),.ADDR_BITS(`ADDR_BITS)) BS
( .clk(clk),.rst_n(rst_n),.grant_i(grant_i),.valid_i(valid_o),.data_in(data_out),.grant_o(grant_o),.data_out(out),.req(req) );


endmodule*/