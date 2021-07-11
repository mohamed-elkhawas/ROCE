`define REQ_SIZE 16
`define CLK_PERIOD 5

module Arbiter_tb();

/***inputs***/
reg clk;
reg rst_n;
reg [15:0] valid /*, req*/;
reg [15:0] [`REQ_SIZE-1 : 0 ] data_in ; 


/***outputs***/
wire [`REQ_SIZE-1:0] data_out ;
//wire [15:0] ack;
wire [15:0] ready;
wire wr_en ; 

reg [15:0] [3:0]counter ;
integer index,i,j ;

task set_counters ;
input [31:0] num;
integer i_;
for(i_ = 0 ;i_<num ; i_=i_+1)begin
    counter[i_] = ($urandom%5)  ;
end
endtask

task update_valid;
integer ii ;
for(ii = 0 ;ii<16 ; ii=ii+1) begin
    valid[ii] = (counter[ii] !=0)? 1'b1: 1'b0; // there is a burst, then set valid = 1      
end
endtask

task update_single_bank_data;
input [32:0] index;
data_in[index] = $urandom ; 
endtask


task update_all_data;
integer k;
for(k = 0 ;k<16 ; k=k+1) //get random data
    update_single_bank_data(k);
    //data_in[j] =$urandom : data_in[j] ; 
endtask


always #`CLK_PERIOD clk = ~clk;
initial begin   
    clk=0;
    rst_n = 0;
    //req=16'h0000;
    valid=16'h0000;
    #6
    rst_n = 1; 
    update_all_data(); // insert new data input
    fork  //use fork for  parallel operations        
        forever begin
            wait(ready != 0); // update valid bit for corresponding ready signals
            @(posedge clk) ; //we must update it at the next positive edge, as its mealy machine so we wait till the edge that new current state is updated
            for(i = 0 ;i<16 ; i=i+1) begin
                if(ready[i] ==1'b1) begin
                    counter[i] = counter[i]-1;
                    #3 // wait as this valid is updated from mealy machine 
                    update_valid(); 
                end
            end
            
        end

        forever begin
            wait (ready != 0 );
            @(posedge clk) ;
            //wait(ready != 0); // update data output for banks with ready signals
            for(j = 0 ;j<16 ; j=j+1) begin
                if(ready[j] ==1'b1) 
                    update_single_bank_data(j);
            end
            
        end

        forever begin    // reset counters after all bursts are empty     
            @ (negedge clk);
            if (valid == 16'd0) begin
                set_counters(16); // insert new bursts lengths
                update_valid();
            end
                
        end
    join     
end

Arbiter #(.REQ_SIZE(`REQ_SIZE)) arbiter
(.clk(clk),.rst_n(rst_n), .Valid(valid), .Data_in(data_in) , .Data_out(data_out) , .wr_en(wr_en),.Ready(ready));



endmodule