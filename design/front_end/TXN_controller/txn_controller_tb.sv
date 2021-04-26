module txn_controller_tb  import types_def::*; ();

request in_request;
logic [0:15] in_busy;

logic in_valid ;
logic clk,rst,wd,rd;

r_type the_type;
logic request_done_valid;
logic  [ 31 : 0 ] in_data;
logic  [ 5 : 0 ] index;

txn_controller t (clk,rst,in_valid,in_request,out_busy,valid_out,out_req,out_index,in_busy,bank_out_valid,

	request_done_valid,the_type,in_data,index,wd,rd,data);

// Clock generator
always  begin
    #1 clk = 1;
    #1 clk = 0;
  end


initial begin 

	rst = 0;
	# 10 rst = 1;
	#11

	@(posedge clk)
	in_busy =0 ;
	request_done_valid = 0;
	index =0;

	for (int i = 0; i < 64; i++) begin

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
