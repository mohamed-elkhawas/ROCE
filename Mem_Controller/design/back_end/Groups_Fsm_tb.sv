`define REQ_SIZE 32
`define CLK_PERIOD 10

/*****************************************************************************************
There is an issue that may violate time constraints, updating start signal after positive
edge will change output signals (wr_en / bank index). I think this might  voilate the write enable
signal that been read with external memory.


--Important: in case of only one group bank x has request and rised done signal, the fsm will 
switch to idle before respond again to group x in case no other groups has request, hence wasting 
one more clock.
*****************************************************************************************/

module Groups_Fsm_tb();

/***inputs***/
reg clk;
reg rst_n;
reg [3:0] done ;
reg [3:0] req  ;

/***outputs***/
wire [1:0] group_sel  ;
wire [7:0] bank_sel  ;
wire [3:0] start_signals ;
wire Start_A, Start_B, Start_C, Start_D ; 
assign start_signals = { Start_D, Start_C, Start_B,Start_A};

reg [1:0] counter;
integer i ;

task update_done;
integer i ;
for(i = 0 ;i<4 ; i=i+1) begin
    if(start_signals[i] == 1'b1)begin
        #(($urandom%3 +1 )*`CLK_PERIOD); //return done to low state
        done[i] = 1'b1;
        #(`CLK_PERIOD); //return done to low state
        done = 0;
        counter = counter -1;
    end
end
endtask

task set_counter;  //counter = number of requests of the random value i.e req = 1011 --> counter =3, then after 3 start signals, update the req with another random value
integer i ;
counter = 0 ;
for(i = 0 ;i<4 ; i=i+1) begin
    if(req[i] == 1'b1)begin
       counter = counter+1;
    end
end
endtask

always #5 clk = ~clk;
initial begin   
    clk=0;
    rst_n = 0;
    req=4'b0000;
    done=4'b0000;
    counter = 2'd0;
    #6
    rst_n = 1 ;
    forever begin
        if(counter == 2'd0 )begin //all requests have been served, so start new req value
            req = $urandom_range(1,15) ; // update request state for bank groups
            set_counter();  
        end
       
        @(negedge clk);
        if(start_signals != 4'b0000 )
            update_done();           
    end
end

Groups_Fsm Bank_Groups(.clk(clk), .rst_n(rst_n), .Req(req), .Done(done), .Start_A(Start_A),
                       .Start_B(Start_B), .Start_C(Start_C), .Start_D(Start_D),.sel(group_sel) );
endmodule
