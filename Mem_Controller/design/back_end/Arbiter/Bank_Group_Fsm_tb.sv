`define REQ_SIZE 32

module Bank_Group_Fsm_tb();

/***inputs***/
reg clk;
reg rst_n;
reg [3:0] valid , req;
reg [15:0] [`REQ_SIZE-1 : 0 ] Data_in ; 
reg  start ;


/***outputs***/
wire [`REQ_SIZE-1:0] Data_out ;
wire [3:0] ack;
wire wr_en ; 
wire  done ;
wire Req;

/*inner signals**/
wire [7:0] bank_sel;

always #5 clk = ~clk;
reg [3:0][`REQ_SIZE-1 : 0 ] banks[0:3] ;
integer bank , index  ,temp , counter;
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
    //$readmemb("requests.txt",banks);
    //$display(banks);
    Data_in=32'h00000000;
    clk=0;
    rst_n = 0;
    start = 0 ;
    req=4'b0000;
    valid=4'b0000;
    #6
    rst_n = 1;
    req=4'b1111;
    valid=4'b0000;
    #20
    valid=4'b1111;
    #10
    valid=4'b1110;
    #20
    start=1'b0;
    #20
    start=1'b1;
    req=4'b1010;
    #30
    valid=4'b0000;
    
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
/*always @(ack) begin
    for (bank = 0 ; bank<16 ; bank=bank+1) begin
        if(ack[bank]==1'b1)begin
            #20
            valid[bank] = 0 ;
        end
    end
end*/

always @(posedge clk +6) begin
    //Data_in=32'hffeeddcc;
    Data_in = Data_in+1;
end
    



Bank_Group_Fsm Bank( .clk(clk), .rst_n(rst_n), .start(start) , .Bank_Req(req) ,.Valid(valid) , .Ack_A(ack[0]), .Ack_B(ack[1]) , .Ack_C(ack[2]),
                .Ack_D(ack[3]) ,.sel(bank_sel[1:0]) , .en(wr_en)  , .done(done) , .Req(Req) );
   

Data_Path #(.REQ_SIZE(`REQ_SIZE)) D_path
( .Data(Data_in), .bank_sel({6'b0000,bank_sel[1:0]}), .group_sel(2'd0), .out(Data_out));


endmodule