module txn_controller_tb  import types_def::*; ();

// pragma attribute txn_controller_tb partition_module_xrt
request in_request;
logic [0:15] grant_o;

logic in_valid ;
logic clk,rst,wd,rd;

r_type the_type;
logic request_done_valid;
logic  [ 31 : 0 ] in_data;
logic  [ 5 : 0 ] index;

txn_controller t (clk,rst,in_valid,in_request,out_busy,out_req,out_index,grant_o,bank_out_valid,

	request_done_valid,the_type,in_data,index,wd,rd,data);

// Clock generator
// tbx clkgen inactive_negedge
initial  begin
    clk = 0;
    #1;
    forever 
    #1 clk = ~clk;
end

XlResetGenerator #(10) resetGenerator ( clk, rst);

task delay(cycle);
	repeat (cycle) begin
		@(posedge clk);
	end
endtask 


initial begin 

	//rst = 0;
	in_valid =0;
	grant_o =16'hffff ;
	request_done_valid = 0;
	index =0;

	delay(20);
	//rst = 1;
	//#11	

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

	//#100
	//$stop;

end

endmodule