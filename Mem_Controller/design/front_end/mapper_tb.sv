module mapper_tb import types_def::*; ();
 

logic clk,rst;

request in_request;
logic [0:15] in_busy;

logic in_valid , stop_reading ,stop_writing ;

mapper m (clk,rst,in_valid,in_request,out_busy,stop_reading ,stop_writing,array_enable,the_req,out_index,in_busy,bank_out_valid);


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
	in_busy =0 ;
	stop_reading =0;
	stop_writing =0;
	
	////////////////////////////// single read
	in_valid =1;

	in_request.req_type =read;
	in_request.address = 0;
	in_request.data = 10;

	@(posedge clk)
	in_valid =0;

	////////////////////////////// two reads
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =read;
	in_request.address = 0;
	in_request.data = 11;

	@(posedge clk)

	in_request.req_type =read;
	in_request.address = 15;
	in_request.data = 12;

	@(posedge clk)
	in_valid =0;

	////////////////////////////// normal write
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 10;

	@(posedge clk)
	in_valid =0;

	////////////////////////////// normal write
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 15;

	@(posedge clk)
	in_valid =0;

	////////////////////////////// write with diffrent bank busy
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 15;

	in_busy = 2;

	@(posedge clk)
	in_valid =0;

	////////////////////////////// write with same bank busy    /////////////////////////////////////////////
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 15;

	in_busy = 1;

	@(posedge clk)
	in_valid =0;
	
	@(posedge clk)
	@(posedge clk)
	in_busy = 0;

	////////////////////////////// write with stop reading once
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 15;

	stop_reading = 1;
	@(posedge clk)
	in_valid =0;
	stop_reading = 0;


	////////////////////////////// write with stop writing once
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 15;

	stop_writing=1;
	@(posedge clk)
	in_valid =0;
	stop_writing=0;

	////////////////////////////// write with stop writing twice 
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 15;

	stop_writing=1;
	@(posedge clk)
	in_valid =0;
	@(posedge clk)
	stop_writing=0;

	////////////////////////////// write with stop writing twice with new request comming after the first one // data will bo lost
	#100 
	@(posedge clk)
	in_valid =1;

	in_request.req_type =write;
	in_request.address = 0;
	in_request.data = 15;

	stop_writing=1;
	@(posedge clk)
	in_request.data = 16;
	

	@(posedge clk)
	stop_writing=0;
	in_valid =0;

	#100
	$stop;

end

endmodule

