`define REQ_SIZE 16
`define CLK_PERIOD 10

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
reg [15:0] [3:0]counter ;
integer index,j,i ;

task set_counters ;
input [31:0] num;
for(i = 0 ;i<num ; i=i+1)begin
    counter[i] = ($urandom%4) +1 ;
end
endtask


task update_valid;
input [15:0] index ;
if(ack[index] == 1) begin
    valid[index] = (counter[index] ==0)? 0: valid[index];  // valid = zero in case of empty burst
    counter[index] = counter[index] -1;
end 
endtask



task update_single_bank_data;
input reg[32:0] index;
data_in[index] = $urandom ; 
endtask


task update_all_data;
integer k;
for(k = 0 ;k<16 ; k=k+1) //get random data
    update_single_bank_data(k);
    //data_in[j] =$urandom : data_in[j] ; 
endtask


initial begin   
    clk=0;
    rst_n = 0;
    req=16'h0000;
    valid=16'hFFFF;
    #6
    rst_n = 1; 
    req = $urandom%(2^16) +1;
    update_all_data();     
    fork  //use fork for  parallel operations
        
        /*forever begin //updating external signal 
            wait (done == 1'b1);
            $display("Hi iam done =1 ");
            @ (posedge clk);
            $display("Hi positive edge clock ");
            #3 start= 0; //wait 3 units as start signal is updated from moore master fsm
            #(($urandom%3 +1 )*`CLK_PERIOD) // wait (1 to 3) clocks to respond
            start = 1'b1 ;
        end*/

        /*forever begin // update input data and valid bits         
            @ (negedge clk);
            for(i = 0 ;i<16 ; i=i+1)begin
                #(($urandom%3 +1 )*`CLK_PERIOD)
                update_valid(i); //reset valid = zero in case of full burst is transmitted
            end
        end*/

        forever begin
            @(|ack == 1'b1); //only update the input data when there is an ack signal
            @ (negedge clk);
            for(j = 0 ;j<16 ; j=j+1) begin
                if(ack[j] ==1'b1) begin
                    update_valid(j); 
                    update_single_bank_data(j);
                end
            end
        end

         forever begin    // reset counters after all bursts are empty     
            @ (negedge clk);
            if (valid == 16'd0) begin
                set_counters(16); // insert new bursts lengths
                update_all_data(); // insert new data input
            end
                
        end
    join     
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
        //banks[bank][index]; 
  //if (!$feof(data_file)) begin
    //use captured_data as you would any other wire or reg value;
end

Arbiter #(.REQ_SIZE(`REQ_SIZE)) arbiter
(.clk(clk),.rst_n(rst_n), .Req(req) ,.Valid(valid), .Data_in(data_in) , .Data_out(data_out) , .wr_en(wr_en),.Ack(ack));



endmodule