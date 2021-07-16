
/*
	request format---> request type bit + index bits + address bits + data (if write request).
*/

 

`define READ  1'b0
`define WRITE 1'b1


// size of request
`define ROW_BITS        16
`define COL_BITS        10
`define ADDR_BITS       `ROW_BITS+`COL_BITS
`define INDEX_BITS      7
`define TYPE_BIT		1
`define DATA_BITS       16
`define REQUEST_SIZE	`ADDR_BITS+`INDEX_BITS+`TYPE_BIT+`DATA_BITS // address + index + request type+ data bits 
`define BURST_BITS		4 ///just to detect burst --> not an additional bits to request

//positions of bits
`define TYPE_POS    42
//`define ADDR_POS   1
`define BURST_POS  5
`define ROW_POS    10
`define COL_POS    0      





module front_end_tb import types_def::*;();

/***inputs***/
reg  clk;
reg  rst_n;
reg  grant_i;

request in_request;
logic [15:0] in_busy;

logic in_valid ;
logic wd,rd;

r_type the_type;
logic request_done_valid;
logic  [ 31 : 0 ] in_data;
logic  [ 5 : 0 ] index;
wire [15:0] valid ;


front_end #( .REQ_SIZE( `REQUEST_SIZE ) )fe
 (.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_request_type(in_request[data_width+address_width-1:0]),
  .in_request_data(in_request[data_width+address_width-1:address_width]),.in_request_address(in_request[address_width-1:0]),
  .out_busy(out_busy),.request_done_valid(request_done_valid),.the_type(the_type),.data_in(in_data),.index(index),
  .write_done(write_done),.read_done(read_done),.data_out(data_out),.out(out),.ready(grant_i), .valid_o(valid)

);



// Clock generator
  always
  begin
    #1 clk = 1;
    #1 clk = 0;
  end

initial begin   
    rst_n = 0;
	# 10 rst_n = 1;
	#11

	@(posedge clk)
	in_busy =0 ;
	request_done_valid = 0;
	index =0;
	grant_i =0;

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
	$stop;

end

endmodule
