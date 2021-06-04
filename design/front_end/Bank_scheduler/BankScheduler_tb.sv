`include "BS_Definitions.svh"

module BankScheduler_tb();

/***inputs***/
reg  clk;
reg  rst_n;
reg  grant_i;
reg [`REQUEST_SIZE-1:0] in;

/***outputs***/
wire  [`REQUEST_SIZE-2:0] data_out ;
wire  pop;



always #5 clk = ~clk;

integer i ;
reg [6:0] value;
initial begin   
    /****************************************************************************************
        -scenario #1.
        -eight mixed type requests with different addresses .
        -input request format ---> (`VALID_BIT+`ADDR_BITS+`INDEX_BITS+`TYPE_BIT+`DATA_BITS )
    ****************************************************************************************/

    /*for(i=0 ; i<10 ; i=i+1)begin
        type = `WRITE;
        value=1<<i;
        casex({value , type})  
        {7'bxxx0000,`READ}, {7'b000xxxx,`WRITE}: $display("no hits at %b  i=%d", value,i);
        default : value = value;
        endcase
    end*/
    
    
    clk=0;
    rst_n = 0;
    grant_i=0;
    #6
    rst_n=1;
    in={1'b1,8'hff,8'd1,`READ,7'd0}; 
    #10
    in={1'b1,8'hff,8'd2,`READ,7'd0}; 
    #10
    in={1'b1,8'hdf,8'd3,`READ,7'd0};    
    #20
    grant_i=1;
    in={1'b0,8'hdf,8'd3,`READ,7'd0};  
    /*in={1'b1,8'hdf,8'd5,`READ,7'd0}; 
    #10
    in={1'b1,8'hdf,8'd7,`READ,7'd0}; 
    #10
    in={1'b1,8'hbf,8'd8,`READ,7'd0}; 
    #10
    in={1'b1,8'haf,8'd9,`WRITE,7'd0}; 
    #10
    in={1'b1,8'hdf,8'd4,`WRITE,7'd0}; 
    #10
    in={1'b1,8'hdf,8'd6,`WRITE,7'd0};*/

end

BankScheduler #(.REQ_SIZE(`REQUEST_SIZE),.TYPE_POS(`TYPE_POS),.ROW_BITS(`ROW_BITS),.ROW_POS(`ROW_POS),.BURST_POS(`BURST_POS),.BURST_BITS(`BURST_BITS),.VALID_POS(`VALID_POS),.ADDR_BITS(`ADDR_BITS)) BS
( .clk(clk),.rst_n(rst_n),.grant_i(grant_i),.in(in),.pop(pop),.out(data_out) );


endmodule