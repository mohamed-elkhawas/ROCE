`define REQ_SIZE 32

module Arbiter_tb();

/***inputs***/
reg clk;
reg rst_n;
reg [15:0] valid , req;
reg [15:0] [`REQ_SIZE-1 : 0 ] data_in ; 


/***outputs***/
wire [`REQ_SIZE-1:0] data_out ;
wire [15:0] ack;
wire wr_en ; 

always #5 clk = ~clk;
reg [15:0][`REQ_SIZE-1 : 0 ] banks[0:15] ;
integer bank , index  ,temp;
initial begin   
    /****************************************************************************************
        -scenario #1.
        -eight mixed type requests with different addresses .
        -input request format ---> (`ADDR_BITS+`INDEX_BITS+`TYPE_BIT+`DATA_BITS+`VALID_BIT )
    ****************************************************************************************/   
/*for (bank = 0 ; bank<16 ; bank=bank+1) begin
    for (index = 0 ; index<16 ; index=index+1) begin
        temp = $fscanf(requests.txt, "%d\n");
        
        //banks[bank][index]; 
  //if (!$feof(data_file)) begin
    //use captured_data as you would any other wire or reg value;
  end
end*/
    $readmemb("requests.txt",banks);
    $display(banks);
    clk=0;
    rst_n = 0;
    #6
    req=16'hFFFF;
    valid=16'h0000;
    
        
        
        //banks[bank][index]; 
  //if (!$feof(data_file)) begin
    //use captured_data as you would any other wire or reg value;

    /*@(posedge clk)
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
    in={8'hdf,8'd6,`WRITE,7'd0};*/

end
always @(ack) begin
    for (bank = 0 ; bank<16 ; bank=bank+1) begin
        if(ack[bank]==1'b1)begin
            data_in = banks[bank];
        end
    end
end
Arbiter #(.REQ_SIZE(`REQ_SIZE)) arbiter
(.clk(clk),.rst_n(rst_n), .Req(req) ,.Valid(valid), .Data_in(data_in) , .Data_out(data_out) , .Ack(ack));



endmodule