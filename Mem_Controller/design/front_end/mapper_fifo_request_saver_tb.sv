module mapper_fifo_request_saver_tb import types_def::*; ();


logic clk, rst_n;


logic  grant_in = 0;

opt_request request_o ,out_req,out_req2 ;
logic [read_entries_log -1:0] out_index,out_index2, index_o;

request in_request;
logic [15:0] in_busy = 0 ,bank_out_valid ,bank_out_valid2, grant_o =16'b 1111111111111111;

logic in_valid  ;


mapper ma (clk,rst_n,in_valid,in_request,out_busy,~grant_o2 , ~grant_o2 ,array_enable,out_req,out_index,~grant_o,bank_out_valid);

old_modified_fifo mf (clk,rst_n,out_req2,out_index2,bank_out_valid2[0],grant_o[0] ,request_o,index_o,valid_o, grant_in);


request_saver r (clk,rst_n,out_req,bank_out_valid,out_index,grant_o2,grant_o,out_req2,bank_out_valid2,out_index2);



always  begin
    #1 clk = 1;
    #1 clk = 0;
  end


initial begin 

	rst_n = 0;
	in_valid = 0;
	in_request = 0;
	in_request.req_type = write;

	#10 rst_n = 1;
	#11

	@(posedge clk)
	in_valid = 1;

	@(posedge clk)
	in_request.data = 1;

	@(posedge clk)
	in_request.data = 2;

	@(posedge clk)
	in_request.data = 3;

	@(posedge clk)
	in_request.data = 4;
	
	@(posedge clk)
	in_request.data = 5;

	@(posedge clk)
	in_request.data = 6;

	@(posedge clk)
	in_valid = 0;
	grant_in =1;


	#100
	$stop;
end





endmodule
