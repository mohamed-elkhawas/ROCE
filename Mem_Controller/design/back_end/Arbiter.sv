/*module Arbiter
#(  
    parameter IDX = 6 ,
    parameter RA = 16 ,
    parameter CA = 10 ,
    parameter DQ = 16
)
(   input  clk   ,
    input  rst_n  ,
    input  [15:0] valid,
    input  flag, 
    input  [(16 * DQ) -1 :0] data_i ,
    input  [(IDX*16) -1 :0 ] idx_i ,
    input  [(RA*16)    -1 :0 ] row_i ,
    input  [(CA*16)    -1 :0 ] col_i ,
    input  [(1*16)          -1 :0 ] t_i, //  type bit

    output [DQ  -1 :0 ]  data_o ,
    output [IDX -1 :0 ]  idx_o  ,
    output [RA    -1 :0 ]  row_o  ,
    output [CA    -1 :0 ]  col_o  ,
    output   t_o,//  type bit
    output [1:0] ba_o , bg_o           ,
    output wr_en , 
    output [15:0] ready 
);

    

wire Start_A, Start_B, Start_C, Start_D ; 
wire [3:0] done ;
wire [1:0] group_sel  ;
wire [3:0] req  ;
wire [7:0] bank_sel  ;
wire [3:0] start_signals ;

assign start_signals = { Start_D, Start_C, Start_B,Start_A};
Groups_Fsm Bank_Groups(
    .clk(clk),
    .rst_n(rst_n),
    .flag(flag),
    .valid(valid),
    .sel(bank_sel),
    .ready_A(ready[3:0]),
    .ready_B(ready[7:4]),
    .ready_C(ready[11:8]),
    .ready_D(ready[15:12]), 
    .wr_en(wr_en) , 
    .group_sel(group_sel)
);

    
genvar i ; 
generate
    for(i = 0 ; i<4  ; i=i+1) begin
        Bank_Group_Fsm Bank( 
            .clk(clk), 
            .rst_n(rst_n),
            .valid(valid[i*4 +: 4]) ,
            .sel(bank_sel[i*2 +: 2]) 
        );
    end
endgenerate

Data_Path #(.INDEX_BITS(IDX), .RA_BITS(RA), .CA_BITS(CA), .DATA_BITS(DQ)) D_path
( .data_i(data_i), .idx_i(idx_i), .row_i(row_i), .col_i(col_i), .bank_sel(bank_sel), .group_sel(group_sel),.t_i(t_i),.t_o(t_o),
   .data_o(data_o), .idx_o(idx_o), .row_o(row_o), .col_o(col_o),.ba_o(ba_o) , .bg_o(bg_o)) ;

endmodule*/





module Arbiter
#(  
    parameter IDX = 6 ,
    parameter RA = 16 ,
    parameter CA = 10 ,
    parameter DQ = 16
)
(   input  clk   ,
    input  rst_n  ,
    input  [15:0] valid,
    input  flag, 
    input  [(16 * DQ) -1 :0] data_i ,
    input  [(IDX*16) -1 :0 ] idx_i ,
    input  [(RA*16)    -1 :0 ] row_i ,
    input  [(CA*16)    -1 :0 ] col_i ,
    input  [(1*16)          -1 :0 ] t_i, //  type bit

    output [DQ  -1 :0 ]  data_o ,
    output [IDX -1 :0 ]  idx_o  ,
    output [RA    -1 :0 ]  row_o  ,
    output [CA    -1 :0 ]  col_o  ,
    output   t_o,//  type bit
    output [1:0] ba_o , bg_o           ,
    output wor wr_en , 
    output [15:0] ready 
);

    

wire Start_A, Start_B, Start_C, Start_D ; 
wire [3:0] done ;
wire [1:0] group_sel  ;
wire [3:0] en   ;
wire [3:0] req  ;
wire [7:0] bank_sel  ;
wire [3:0] start_signals ;

assign start_signals = { Start_D, Start_C, Start_B,Start_A};
assign wr_en = |en ; 
Groups_Fsm Bank_Groups(.clk(clk), .rst_n(rst_n), .flag(flag),.Req(req), .Done(done), .Start_A(Start_A),
                       .Start_B(Start_B), .Start_C(Start_C), .Start_D(Start_D),.sel(group_sel) );

genvar i ; 
generate
    for(i = 0 ; i<4  ; i=i+1) begin
        Bank_Group_Fsm Bank( 
            .clk(clk), 
            .rst_n(rst_n),
             .start(start_signals[i]) ,
              /*.Bank_Req(Req[i*4 +: 4]) ,*/
            .Valid(valid[i*4 +: 4]) ,
                .Ready_A(ready[(i*4)+0]),
                .Ready_B(ready[(i*4)+1]) ,
                .Ready_C(ready[(i*4)+2]),
            .Ready_D(ready[(i*4)+3]) ,
            .sel(bank_sel[i*2 +: 2]) ,
                .en(en[i])  , 
                .done(done[i]) , 
                .Req(req[i]) 
        );
    end
endgenerate

Data_Path #(.INDEX_BITS(IDX), .RA_BITS(RA), .CA_BITS(CA), .DATA_BITS(DQ)) D_path
( .data_i(data_i), .idx_i(idx_i), .row_i(row_i), .col_i(col_i), .bank_sel(bank_sel), .group_sel(group_sel),.t_i(t_i),.t_o(t_o),
   .data_o(data_o), .idx_o(idx_o), .row_o(row_o), .col_o(col_o),.ba_o(ba_o) , .bg_o(bg_o)) ;

endmodule