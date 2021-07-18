/*module sch_arbiter_tb();

parameter READ     = 1'b1;
parameter WRITE    = 1'b0;
parameter RA_POS   = 10;
parameter BA       = 2;
parameter BG       = 2;
parameter CA       = 10;
parameter RA       = 16;
parameter DQ       = 16;
parameter IDX      = 6;
parameter WR_FIFO_SIZE = 2;
parameter WR_FIFO_NUM  = 3;


//inputs
reg  clk;
reg  rst_n;
reg  valid_i ; 
wire [DQ  -1 :0] dq_i;
wire [IDX -1 :0] idx_i;
wire [RA  -1 :0] ra_i;
wire [CA  -1 :0] ca_i;
wire [BA  -1 :0] ba_i;
wire [BG  -1 :0] bg_i;
wire             t_i;


//outputs
wire             valid_o;
wire [DQ  -1 :0] dq_o;
wire [IDX -1 :0] idx_o;
wire [RA  -1 :0] ra_o;
wire [CA  -1 :0] ca_o;
wire [BA  -1 :0] ba_o;
wire [BG  -1 :0] bg_o;
wire             t_o;



always #5 clk = ~clk;

initial begin 
    clk = 0 ;  
    rst_n = 1'b0;
    valid_i = 1'b1;
	#8 
	rst_n = 1'b1;

	repeat(30) begin //insert new input data
        @ (posedge clk);
		// new address / data /  type input
        in_request.address = $urandom() ;
		in_request.data= $urandom();
		t = $urandom()%2; //in_request.req_type
    end


generic_fifo #( .DATA_WIDTH(RA+CA+IDX+DQ),.DATA_DEPTH(15),.RA_POS(RA_POS),.RA_BITS(RA) ) mapper_fifo
(
    .clk(clk),
    .rst_n(rst_n),
    .data_i({idx_i,ra_i,ca_i}),
    .valid_i(push[g]),
    .grant_o(grant_o[g]),
    .last_addr(last_ra[g*RA +: RA]),
    .mid(mid[g]),
    .data_o({f_idx_o[g],f_ra_o[g],f_ca_o[g]}),
    .valid_o(valid_o[g]),
    .grant_i(pop[g])
);    
       


front_end #( .READ(READ),.WRITE(WRITE),.RA_POS(RA_POS),.CA(CA),.RA(RA),.DQ(DQ),.IDX(IDX),.WR_FIFO_SIZE(WR_FIFO_SIZE),.WR_FIFO_NUM(WR_FIFO_NUM) )fe
 (
	
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_request_type(t),
  	.in_request_data(in_request.data),
  	.in_request_address(in_request.address),
	.out_busy(out_busy),
	.request_done_valid(request_done_valid),
	.the_type(the_type),
	.data_in(in_data),
	.index(index),
	.write_done(write_done),
	.read_done(read_done),
	.data_out(data_out),
    .ready(ready),
	.valid_o(valid_o),
	.dq_o(dq_o),
	.idx_o(idx_o),
	.ra_o(ra_o),
	.ca_o(ca_o),
	.t_o(t_o)
);



endmodule*/