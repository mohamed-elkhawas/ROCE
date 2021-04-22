module global_array_tb import types_def::*; ();
 

logic clk,rst;

request in_request;
logic [read_entries_log:0] in_request_index , out_request_index;
logic mapper_valid ,scheduler_valid;
r_type the_scheduler_req_type;

global_array g (clk,rst, in_request,in_request_index,mapper_valid,scheduler_valid,out_request_index,
 the_scheduler_req_type,out_request,sending);



// Clock generator
  always
  begin
    #1 clk = 1;
    #1 clk = 0;
  end


initial begin 

	rst = 0;
	# 10 rst = 1;
	#11
	@(posedge clk)

	scheduler_valid=0;
	the_scheduler_req_type = read;
/////////////////////////////////////////// save read req index 0 adress 0
	mapper_valid =1;
	in_request_index =0;
	in_request.req_type =read;
	in_request.address = 0;
	in_request.data = 10;

	@(posedge clk)
	mapper_valid =0;

/////////////////////////////////////////// save read req index 1 adress 1
	#100 
	@(posedge clk)
	mapper_valid =1;
	in_request_index =1;
	in_request.req_type =read;
	in_request.address = 1;
	in_request.data = 10;
	@(posedge clk)
	mapper_valid =0;

/////////////////////////////////////////// save write req index 0 adress 1 data 10
	#100 
	@(posedge clk)
	mapper_valid =1;
	in_request_index =0;
	in_request.req_type =write;
	in_request.address = 1;
	in_request.data = 10;
	@(posedge clk)
	mapper_valid =0;

	#100 
	@(posedge clk)
	mapper_valid =1;
	in_request_index =1;
	in_request.req_type =write;
	in_request.address = 1;
	in_request.data = 11;
	@(posedge clk)
	mapper_valid =0;

	#100 
	@(posedge clk)
	mapper_valid =1;
	in_request_index =1;
	in_request.req_type =write;
	in_request.address = 1;
	in_request.data = 11;
	@(posedge clk)
	mapper_valid =0;

/////////////////////////////////////////// save and load together
	#100 
	@(posedge clk)
	mapper_valid =1;
	in_request_index =3;
	in_request.req_type =write;
	in_request.address = 1;
	in_request.data = 11;

	scheduler_valid = 1;
	the_scheduler_req_type = write;
	out_request_index = 1;


	@(posedge clk)
	mapper_valid =0;
	scheduler_valid = 0;

/////////////////////////////////////////// just load 
	#100 
	@(posedge clk)
	scheduler_valid = 1;
	the_scheduler_req_type = write;
	out_request_index = 1;
	@(posedge clk)
	scheduler_valid = 0;


	#100
	$stop;

end

endmodule
