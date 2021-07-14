module Arbiter_tb();

//velcoce request format
localparam  CID_POS         =0,
            CA_POS          =4,
            RA_POS          =14,
            BA_POS          =30,
            BG_POS          =32,
            DATA_POS        =33,
            TYPE_POS        =49,
            INDEX_POS       =50,
            CID_BITS        =4,
            CA_BITS         =10,
            RA_BITS         =16,
            BA_BITS         =2,
            BG_BITS         =2,
            DATA_BITS       =16,
            TYPE_BITS       =1,
            INDEX_BITS      =7,
            REQ_SIZE        =CA_BITS+RA_BITS+BA_BITS+BG_BITS+DATA_BITS+TYPE_BITS+INDEX_BITS ; // +CID_BITS -->removed as we deal with one chip 

/***inputs***/
reg clk;
reg rst_n;
reg [15:0] valid ;
reg [15:0] [REQ_SIZE-1 : 0 ] data_in ; 


//wires for slicing data_in
reg  [15:0] [DATA_BITS-1  : 0 ] data_i ;
reg  [15:0] [INDEX_BITS-1 : 0 ] idx_i ;
reg  [15:0] [RA_BITS-1    : 0 ] row_i ;
reg  [15:0] [CA_BITS-1    : 0 ] col_i ;


/***outputs***/
wire [15:0] ready;
wire wr_en ; 

wire   [DATA_BITS-1  : 0 ] data_o ;
wire   [INDEX_BITS-1 : 0 ] idx_o ;
wire   [RA_BITS-1    : 0 ] row_o ;
wire   [CA_BITS-1    : 0 ] col_o ;





reg [15:0] [3:0]counter ;
integer index,i,j;

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
{data_i[index],idx_i[index],col_i[index],row_i[index]} = {$urandom,$urandom} ; 
endtask


task update_all_data;
integer k;
for(k = 0 ;k<16 ; k=k+1) //get random data
    update_single_bank_data(k);
    //data_in[j] =$urandom : data_in[j] ; 
endtask


always #5 clk = ~clk;
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

Arbiter #(.INDEX_BITS(INDEX_BITS), .RA_BITS(RA_BITS), .CA_BITS(CA_BITS), .DATA_BITS(DATA_BITS)) arbiter
(.clk(clk),.rst_n(rst_n), .valid(valid), .data_i(data_i) ,.idx_i(idx_i) ,.row_i(row_i) ,
    .col_i(col_i) ,  .data_o(data_o) ,.idx_o(idx_o)  ,.row_o(row_o)  , .col_o(col_o)  ,
    .ba_o(ba_o) ,.bg_o(bg_o), .wr_en(wr_en),.Ready(ready));

    

    
    
endmodule