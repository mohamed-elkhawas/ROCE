module Data_Path
#(parameter INDEX_BITS = 7 , parameter RA_BITS = 16 , parameter CA_BITS = 10 , parameter DATA_BITS = 16)
(   
    input  [(DATA_BITS*16)  -1 :0 ] data_i,
    input  [(INDEX_BITS*16) -1 :0 ] idx_i ,
    input  [(RA_BITS*16)    -1 :0 ] row_i ,
    input  [(CA_BITS*16)    -1 :0 ] col_i ,
    input  [(1*16)          -1 :0 ] t_i, //  type bit
    input  [7:0] bank_sel,
    input  [1:0] group_sel,

    output reg [DATA_BITS  -1 :0 ]  data_o ,
    output reg [INDEX_BITS -1 :0 ]  idx_o  ,
    output reg [RA_BITS    -1 :0 ]  row_o  ,
    output reg [CA_BITS    -1 :0 ]  col_o  ,
    output reg t_o,//  type bit
    output reg [1:0] ba_o , bg_o    //bank address , bank group
);

localparam REQ_SIZE = DATA_BITS+RA_BITS+CA_BITS+INDEX_BITS+1; //1 for type bit

// wires for slicing each bank input data
wire [DATA_BITS-1 :0 ] D_A3, D_A2, D_A1, D_A0;
wire [DATA_BITS-1 :0 ] D_B3, D_B2, D_B1, D_B0;
wire [DATA_BITS-1 :0 ] D_C3, D_C2, D_C1, D_C0;
wire [DATA_BITS-1 :0 ] D_D3, D_D2, D_D1, D_D0;

// wires for slicing each bank input index
wire [INDEX_BITS-1 :0 ] I_A3, I_A2, I_A1, I_A0;
wire [INDEX_BITS-1 :0 ] I_B3, I_B2, I_B1, I_B0;
wire [INDEX_BITS-1 :0 ] I_C3, I_C2, I_C1, I_C0;
wire [INDEX_BITS-1 :0 ] I_D3, I_D2, I_D1, I_D0;

// wires for slicing each bank input row address
wire [RA_BITS-1 :0 ] R_A3, R_A2, R_A1, R_A0;
wire [RA_BITS-1 :0 ] R_B3, R_B2, R_B1, R_B0;
wire [RA_BITS-1 :0 ] R_C3, R_C2, R_C1, R_C0;
wire [RA_BITS-1 :0 ] R_D3, R_D2, R_D1, R_D0;

// wires for slicing each bank input column address
wire [CA_BITS-1 :0 ] C_A3, C_A2, C_A1, C_A0;
wire [CA_BITS-1 :0 ] C_B3, C_B2, C_B1, C_B0;
wire [CA_BITS-1 :0 ] C_C3, C_C2, C_C1, C_C0;
wire [CA_BITS-1 :0 ] C_D3, C_D2, C_D1, C_D0;

// wires for slicing each bank input type bit
wire                 T_A3, T_A2, T_A1, T_A0;
wire                 T_B3, T_B2, T_B1, T_B0;
wire                 T_C3, T_C2, T_C1, T_C0;
wire                 T_D3, T_D2, T_D1, T_D0;


// wires for selected bank addresses from each group
reg [1:0] BA_A, BA_B, BA_C, BA_D ; 


wire [1:0] sel_D, sel_C, sel_B, sel_A ;
//wire [REQ_SIZE-1 :0 ] dont_care ; 



assign {D_A3, D_A2, D_A1, D_A0} = data_i[(0*DATA_BITS)  +: 4*DATA_BITS];
assign {D_B3, D_B2, D_B1, D_B0} = data_i[(4*DATA_BITS)  +: 4*DATA_BITS];
assign {D_C3, D_C2, D_C1, D_C0} = data_i[(8*DATA_BITS)  +: 4*DATA_BITS];
assign {D_D3, D_D2, D_D1, D_D0} = data_i[(12*DATA_BITS) +: 4*DATA_BITS];

assign {I_A3, I_A2, I_A1, I_A0} = idx_i[(0*INDEX_BITS)  +: 4*INDEX_BITS];
assign {I_B3, I_B2, I_B1, I_B0} = idx_i[(4*INDEX_BITS)  +: 4*INDEX_BITS];
assign {I_C3, I_C2, I_C1, I_C0} = idx_i[(8*INDEX_BITS)  +: 4*INDEX_BITS];
assign {I_D3, I_D2, I_D1, I_D0} = idx_i[(12*INDEX_BITS) +: 4*INDEX_BITS];

assign {R_A3, R_A2, R_A1, R_A0} = row_i[(0*RA_BITS)  +: 4*RA_BITS];
assign {R_B3, R_B2, R_B1, R_B0} = row_i[(4*RA_BITS)  +: 4*RA_BITS];
assign {R_C3, R_C2, R_C1, R_C0} = row_i[(8*RA_BITS)  +: 4*RA_BITS];
assign {R_D3, R_D2, R_D1, R_D0} = row_i[(12*RA_BITS) +: 4*RA_BITS];

assign {C_A3, C_A2, C_A1, C_A0} = col_i[(0*CA_BITS)  +: 4*CA_BITS];
assign {C_B3, C_B2, C_B1, C_B0} = col_i[(4*CA_BITS)  +: 4*CA_BITS];
assign {C_C3, C_C2, C_C1, C_C0} = col_i[(8*CA_BITS)  +: 4*CA_BITS];
assign {C_D3, C_D2, C_D1, C_D0} = col_i[(12*CA_BITS) +: 4*CA_BITS];

assign {T_A3, T_A2, T_A1, T_A0} = t_i[(0)  +: 4];
assign {T_B3, T_B2, T_B1, T_B0} = t_i[(4)  +: 4];
assign {T_C3, T_C2, T_C1, T_C0} = t_i[(8)  +: 4];
assign {T_D3, T_D2, T_D1, T_D0} = t_i[(12) +: 4];



//assign dont_Care = {(REQ_SIZE){1'b0}};

assign {sel_D, sel_C, sel_B, sel_A} = bank_sel;

reg [REQ_SIZE-1 :0 ] A ,B ,C ,D;

always @(*) begin
    casex(sel_A) 
        2'd0   : {A,BA_A} = {T_A0,R_A0,C_A0,D_A0,I_A0,2'b00};
        2'd1   : {A,BA_A} = {T_A1,R_A1,C_A1,D_A1,I_A1,2'b01};
        2'd2   : {A,BA_A} = {T_A2,R_A2,C_A2,D_A2,I_A2,2'b10};
        2'd3   : {A,BA_A} = {T_A3,R_A3,C_A3,D_A3,I_A3,2'b11};
        default: {A,BA_A} = {{(REQ_SIZE){1'b0}},2'b00};
    endcase
end

always @(*) begin
    casex(sel_B) 
        2'd0   : {B,BA_B} = {T_B0,R_B0,C_B0,D_B0,I_B0,2'b00};
        2'd1   : {B,BA_B} = {T_B1,R_B1,C_B1,D_B1,I_B1,2'b01};
        2'd2   : {B,BA_B} = {T_B2,R_B2,C_B2,D_B2,I_B2,2'b10};
        2'd3   : {B,BA_B} = {T_B3,R_B3,C_B3,D_B3,I_B3,2'b11};
        default: {B,BA_B} = {{(REQ_SIZE){1'b0}},2'b00};
    endcase
end

always @(*) begin
    casex(sel_C) 
        2'd0   : {C,BA_C} = {T_C0,R_C0,C_C0,D_C0,I_C0,2'b00};
        2'd1   : {C,BA_C} = {T_C1,R_C1,C_C1,D_C1,I_C1,2'b01};
        2'd2   : {C,BA_C} = {T_C2,R_C2,C_C2,D_C2,I_C2,2'b10};
        2'd3   : {C,BA_C} = {T_C3,R_C3,C_C3,D_C3,I_C3,2'b11};
        default: {C,BA_C} = {{(REQ_SIZE){1'b0}},2'b00};
    endcase
end

always @(*) begin
    casex(sel_D) 
        2'd0   : {D,BA_D} = {T_D0,R_D0,C_D0,D_D0,I_D0,2'b00};
        2'd1   : {D,BA_D} = {T_D1,R_D1,C_D1,D_D1,I_D1,2'b01};
        2'd2   : {D,BA_D} = {T_D2,R_D2,C_D2,D_D2,I_D2,2'b10};
        2'd3   : {D,BA_D} = {T_D3,R_D3,C_D3,D_D3,I_D3,2'b11};
        default: {D,BA_D} = {{(REQ_SIZE){1'b0}},2'b00};
    endcase
end



always @(*) begin
    casex(group_sel) 
        2'd0   : {ba_o,bg_o,t_o,row_o,col_o,data_o,idx_o} = {BA_A,2'b00,A};
        2'd1   : {ba_o,bg_o,t_o,row_o,col_o,data_o,idx_o} = {BA_B,2'b01,B};
        2'd2   : {ba_o,bg_o,t_o,row_o,col_o,data_o,idx_o} = {BA_C,2'b10,C};
        2'd3   : {ba_o,bg_o,t_o,row_o,col_o,data_o,idx_o} = {BA_D,2'b11,D};
        default: {ba_o,bg_o,t_o,row_o,col_o,data_o,idx_o} = {2'b00,2'b00,{(REQ_SIZE){1'b0}}};
    endcase
end

endmodule
