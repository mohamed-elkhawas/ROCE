module over_flow_stopper_tb ();
 

logic clk,rst,the_req_type,mapper_valid,write_done,read_done;


over_flow_stopper o (clk,rst, mapper_valid, the_req_type, read_done,  write_done,stop_reading, stop_writing);


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
	read_done =0;
	write_done =0;

	mapper_valid =1;
	the_req_type = 0;

	for (int i = 0; i < 64; i++) begin
		@(posedge clk)
		the_req_type = 0;
		
	end
	read_done = 1; 

	@(posedge clk)
	read_done = 0;
	mapper_valid =0;

	@(posedge clk)
	read_done = 1;


	#10
	@(posedge clk)



	for (int i = 0; i < 10; i++) begin
		@(posedge clk)
		read_done = 1;
		
	end

	@(posedge clk)
	read_done = 0;
	

	#100
	$stop;

end

endmodule
