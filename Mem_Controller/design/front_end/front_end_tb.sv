
module front_end_tb import types_def::*;();

parameter READ     = 1'b1;
parameter WRITE    = 1'b0;
parameter RA_POS   = 10;
parameter CA       = 10;
parameter RA       = 16;
parameter DQ       = 16;
parameter IDX      = 7;
parameter WR_FIFO_SIZE = 2;
parameter WR_FIFO_NUM =3;


/***inputs***/
reg  clk;
reg  rst_n;
reg  [15:0] ready;
request in_request;
logic [15 : 0] in_busy;

logic in_valid ;
logic wd,rd;
logic t ; 
r_type the_type;
logic request_done_valid;
logic  [ 31 : 0 ] in_data;
logic  [ 5 : 0 ] index;

//outputs
wire [15:0]            valid_o;
wire [15:0][DQ  -1 :0] dq_o;
wire [15:0][IDX -1 :0] idx_o;
wire [15:0][RA  -1 :0] ra_o;
wire [15:0][CA  -1 :0] ca_o;
wire [15:0]            t_o;

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

// Clock generator
  always
  begin
    #5 clk = 1;
    #5 clk = 0;
  end



initial begin   
    rst_n = 1'b0;
	ready = 1'b0;
	request_done_valid = 1'b0;
	#8 
	rst_n = 1'b1;
	in_valid = 1'b1;

	repeat(30) begin //insert new input data
        @ (posedge clk);
		// new address / data /  type input
        in_request.address = $urandom() ;
		in_request.data= $urandom();
		t = $urandom()%2; //in_request.req_type
    end


	/*@(posedge clk)
	in_busy =0 ;
	request_done_valid = 0;
	index =0;
	grant_i =0;

	.in_valid(in_valid),
	.in_request_type(in_request[data_width+address_width-1:0]),
  	.in_request_data(in_request[data_width+address_width-1:address_width]),
  	.in_request_address(in_request[address_width-1:0]),

	  
	repeat(30) begin //insert new random data
        @ (posedge clk);
        {idx_i,dq_i,ra_i,ca_i,type_i}  = {$urandom(),$urandom()};
        if(type_i == READ )  begin push = 7'b1<<rd_arr[$urandom%4];  end
        if(type_i == WRITE ) begin push = 7'b1<<wr_arr[$urandom%3];  end
    end

	for (int i = 0; i < 64; i++) begin
		////////////////////////////// single read
	@(posedge clk)
	in_valid =1;

	in_request.req_type =read;
	in_request.address = 0;
	in_request.data = 10;
	
	end
	@(posedge clk)
	in_valid = 0 ;

	@(posedge clk)
	in_valid = 1 ;
	in_request.req_type =write;

	@(posedge clk)
	in_valid = 0 ;

	@(posedge clk)
	request_done_valid = 1;
	the_type = read;

	for (int i = 0; i < 64; i++) begin
		////////////////////////////// single write
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 10;
	
	end
	@(posedge clk)
	in_valid = 0 ;

	#100
	$stop;*/

end

endmodule
