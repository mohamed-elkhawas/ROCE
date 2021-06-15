module Data_Path
#(parameter REQ_SIZE = 32 )
(   
    input  [(REQ_SIZE*16) -1 :0 ] Data,      
    input  [7:0] bank_sel,
    input  [1:0] group_sel,
    output reg [REQ_SIZE-1 :0 ] out 
);

wire D_A3, D_A2, D_A1, D_A0;
wire D_B3, D_B2, D_B1, D_B0;
wire D_C3, D_C2, D_C1, D_C0;
wire D_D3, D_D2, D_D1, D_D0;


wire sel_D, sel_C, sel_B, sel_A ;



assign {D_A3, D_A2, D_A1, D_A0} = Data[(0*Req_SIZE) +: Req_SIZE]
assign {D_B3, D_B2, D_B1, D_B0} = Data[(1*Req_SIZE) +: Req_SIZE]
assign {D_C3, D_C2, D_C1, D_C0} = Data[(2*Req_SIZE) +: Req_SIZE]
assign {D_D3, D_D2, D_D1, D_D0} = Data[(3*Req_SIZE) +: Req_SIZE]


assign {sel_D, sel_C, sel_B, sel_A} = bank_sel;

reg [REQ_SIZE-1 :0 ] A ,B ,C ,D;

always (*) begin
    casex(sel_A) 
        2'd0: A = D_A0;
        2'd1: A = D_A1;
        2'd2: A = D_A2;
        2'd3: A = D_A3;
        default: A = x;
    endcase
end

always (*) begin
    casex(sel_B) 
        2'd0: B = D_B0;
        2'd1: B = D_B1;
        2'd2: B = D_B2;
        2'd3: B = D_B3;
        default: B = x;
    endcase
end

always (*) begin
    casex(sel_C) 
        2'd0: C = D_C0;
        2'd1: C = D_C1;
        2'd2: C = D_C2;
        2'd3: C = D_C3;
        default: C = x;
    endcase
end

always (*) begin
    casex(sel_D) 
        2'd0: D = D_D0;
        2'd1: D = D_D1;
        2'd2: D = D_D2;
        2'd3: D = D_D3;
        default: D = x;
    endcase
end



always (*) begin
    casex(group_sel) 
        2'd0: out = A;
        2'd1: out = B;
        2'd2: out = C;
        2'd3: out = D;
        default: out = x;
    endcase
end

endmodule