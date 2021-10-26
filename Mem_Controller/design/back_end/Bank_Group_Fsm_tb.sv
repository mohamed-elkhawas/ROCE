
/*****************************************************************************************
There is an issue that may violate time constraints, updating start signal after positive
edge will change output signals (wr_en / bank index). I think this might  voilate the write enable
signal that been read with external memory.
*****************************************************************************************/

module Bank_Group_Fsm_tb();


parameter READ  = 1'b0;
parameter WRITE = 1'b1;

//veloce request format
parameter  CA       = 10;
parameter  RA       = 16;
parameter  DQ       = 16;
parameter  IDX      = 6;
parameter  TYPE     = 1;
parameter  REQ_SIZE = CA + RA + DQ + TYPE + IDX ; 

localparam CLK_PERIOD = 10;

/***inputs***/
reg clk;
reg rst_n;
reg [3:0] valid ;/*, req*/
reg [3:0] [REQ_SIZE-1 : 0 ] Data_in ; 
reg  start ;


/***outputs***/
wire [REQ_SIZE-1:0] Data_out ;
wire [3:0] ready;
wire wr_en ; 
wire  done ;
wire Req;

/*inner signals**/
wire [1:0] bank_sel;


reg [3:0][REQ_SIZE-1 : 0 ] banks[0:3] ;
integer counter[3:0] , i , j;

/*****************tasks****************/
task set_counters ;
input [31:0] num;
integer i  ;
for(i = 0 ;i<num ; i=i+1)
    counter[i] = ($urandom%3) +1 ;
endtask


task update_valid;
input [5:0] index ;
valid[index] = (counter[index] ==0)? 0: valid[index];  
counter[index] = counter[index] -1;
endtask


task update_data;
input [32:0] index;
Data_in[index] = $urandom ; 
//Data_in = {16{$urandom}} ; 
endtask

task update_all_data;
for(j = 0 ;j<16 ; j++)
    Data_in[j] = $urandom ; 
endtask

always #5 clk = ~clk;
initial begin   
    Data_in=0;
    clk=0;
    rst_n = 0;
    start = 0 ;
    //req=4'b0000;
    valid=4'b0000;
    set_counters(4) ; //set random burst lengths for each bank
    update_all_data();
    @ (negedge clk);
    start = 1 ; 
    rst_n = 1 ;
    valid = 4'b1111;
    //req=4'b1111;
    fork  //use fork for  parallel operations
        
        forever begin //updating start signal after done is set 1
            wait (done == 1'b1);
            $display("Hi iam done =1 ");
            @ (posedge clk);
            $display("Hi iam positive edge clock ");
            #3 start= 0; //wait 3 units as start signal is updated from moore master fsm
            #(($urandom%3 +1 )*CLK_PERIOD) // wait (1 to 3) clocks to respond
            start = 1'b1 ;
        end

        forever begin         
            @ (negedge clk);   
            for(i = 0 ;i<4 ; i=i+1)begin
                if(ready[i] == 1) begin       
                    update_valid(i); //reset valid = zero in case of full burst is transmitted
                    update_data(i);
                end
            end
        end

         forever begin    // reset counters after all bursts are empty     
            @ (negedge clk);
            if (valid == 4'b0000)
                set_counters(4); // insert new bursts lengths
        end



    join
end

Bank_Group_Fsm Bank( .clk(clk), .rst_n(rst_n), .start(start) , /*.Bank_Req(req) ,*/.Valid(valid) , .Ready_A(ready[0]), .Ready_B(ready[1]) , .Ready_C(ready[2]),
                .Ready_D(ready[3]) ,.sel(bank_sel) , .en(wr_en)  , .done(done) , .Req(Req) );
   
/*
Data_Path #(.INDEX_BITS(IDX), .RA_BITS(RA), .CA_BITS(CA), .DATA_BITS(DQ)) D_path
( 
    .data_i(dq_i),
    .idx_i(idx_i),
    .row_i(ra_i), 
    .col_i(ca_i),
    .t_i(t_i),
    .bank_sel({6'b0000,bank_sel[1:0]}),
    .group_sel(2'd0),
    .data_o(data_o),
    .idx_o(idx_o), 
    .row_o(row_o),
    .col_o(col_o),
    .t_o(t_o),
    .ba_o(ba_o) , 
    .bg_o(bg_o)
);*/

endmodule