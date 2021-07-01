module Arbiter
#(parameter REQ_SIZE = 32)
(   
    input  clk, rst_n  ,
    input  [15:0] Req  ,  // request bits ( equals 1 in case of bank wants the bus)
    input  [15:0] Valid, //valid bits
    input  [(16 * REQ_SIZE) -1 :0] Data_in ,
    output [REQ_SIZE-1 : 0]  Data_out,
    output wr_en , 
    output [15:0] Ack 
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
Groups_Fsm Bank_Groups(.clk(clk), .rst_n(rst_n), .Req(req), .Done(done), .Start_A(Start_A),
                       .Start_B(Start_B), .Start_C(Start_C), .Start_D(Start_D),.sel(group_sel) );


genvar i ; 
generate
    for(i = 0 ; i<4  ; i=i+1) begin
        Bank_Group_Fsm Bank( .clk(clk), .rst_n(rst_n), .start(start_signals[i]) , .Bank_Req(Req[i*4 +: 4]) ,
                        .Valid(Valid[i*4 +: 4]) , .Ack_A(Ack[(i*4)+0]), .Ack_B(Ack[(i*4)+1]) , .Ack_C(Ack[(i*4)+2]),
                        .Ack_D(Ack[(i*4)+3]) ,.sel(bank_sel[i*2 +: 2]) , .en(en[i])  , .done(done[i]) , .Req(req[i]) );
    end
endgenerate

Data_Path #(.REQ_SIZE(REQ_SIZE)) D_path
( .Data(Data_in), .bank_sel(bank_sel), .group_sel(group_sel), .out(Data_out));

endmodule