`define REQ_SIZE 32
`define CLK_PERIOD 10

/*****************************************************************************************
There is an issue that may violate time constraints, updating start signal after positive
edge will change output signals (wr_en / bank index). I think this might  voilate the write enable
signal that been read with external memory.
*****************************************************************************************/

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
wire [1:0] bank_sel;


reg [3:0][`REQ_SIZE-1 : 0 ] banks[0:3] ;
integer counter[3:0] , i , j;

/*****************tasks****************/
task set_counters ;
input [31:0] num;
integer i  ;
for(i = 0 ;i<num ; i=i+1)
    counter[i] = ($urandom%4) +1 ;
endtask


task update_valid;
input [5:0] index ;
if(ack[index] == 1) begin
    valid[index] = (counter[index] ==0)? 0: valid[index];  
    counter[index] = counter[index] -1;
end 
endtask

always #5 clk = ~clk;
initial begin   
    Data_in=0;
    clk=0;
    rst_n = 0;
    start = 0 ;
    req=4'b0000;
    valid=4'b0000;
    set_counters(4) ; //set random burst lengths for each bank
    #6
    start = 1 ; 
    rst_n = 1 ;
    valid = 4'b1111;
    req=4'b1111;
    fork  //use fork for  parallel operations
        
        forever begin //updating external signal 
            wait (done == 1'b1);
            $display("Hi iam done =1 ");
            @ (posedge clk);
            $display("Hi positive edge clock ");
            #3 start= 0; //wait 3 units as start signal is updated from moore master fsm
            #(($urandom%3 +1 )*`CLK_PERIOD) // wait (1 to 3) clocks to respond
            start = 1'b1 ;
        end

        forever begin         
            @ (negedge clk);
            for(i = 0 ;i<4 ; i=i+1)
                update_valid(i); //reset valid = zero in case of full burst is transmitted
            for(j = 0 ;j<16 ; j=j+1) //get random data
                Data_in[j] = $urandom ; 
                //Data_in = {16{$urandom}} ; 
        end

         forever begin    // reset counters after all bursts are empty     
            @ (negedge clk);
            if (valid == 4'b0000)
                set_counters(4); // insert new bursts lengths
        end



    join
end

Bank_Group_Fsm Bank( .clk(clk), .rst_n(rst_n), .start(start) , .Bank_Req(req) ,.Valid(valid) , .Ack_A(ack[0]), .Ack_B(ack[1]) , .Ack_C(ack[2]),
                .Ack_D(ack[3]) ,.sel(bank_sel) , .en(wr_en)  , .done(done) , .Req(Req) );
   
Data_Path #(.REQ_SIZE(`REQ_SIZE)) D_path
( .Data(Data_in), .bank_sel({6'b0000,bank_sel[1:0]}), .group_sel(2'd0), .out(Data_out));

endmodule



 /****************************************************************************************
        -scenario #1.
        -eight mixed type requests with different addresses .
        -input request format ---> (`ADDR_BITS+`INDEX_BITS+`TYPE_BIT+`DATA_BITS+`VALID_BIT )
    ****************************************************************************************/   

     //banks[bank][index]; 
  //if (!$feof(data_file)) begin
    //use captured_data as you would any other wire or reg value;
    
/*always @(ack) begin
    for (bank = 0 ; bank<16 ; bank=bank+1) begin
        if(ack[bank]==1'b1)begin
            #20
            valid[bank] = 0 ;
        end
    end
end*/