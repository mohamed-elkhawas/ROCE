module burst_handler_tb  import types_def::*; ();


parameter no_of_bursts  = 4;

logic clk,rst_n;
command in_burst_cmd;
logic [1:0] in_cmd_index;


logic arbiter_valid;
address_type in_req_address;
logic  [data_width -1:0] arbiter_data;
logic [read_entries_log -1:0] arbiter_index;
r_type arbiter_type;

logic test;

burst_handler m (clk,rst_n,out_burst_state,out_burst_type,
	out_burst_address,in_burst_cmd,in_cmd_index,start_new_burst,arbiter_valid,in_req_address,
	arbiter_data,arbiter_index,arbiter_type,returner_valid,returner_type,returner_data,returner_index);//,test);




// Clock generator
  always
  begin
    #1 clk = 1;
    #1 clk = 0;
  end

initial begin 

	rst_n = 0;
	#10 
	@(posedge clk) 
	test=0;
	rst_n = 1;
	arbiter_valid=0;
	arbiter_type = read;
	in_req_address =0;
	arbiter_index =0;

	#11
	
	@(posedge clk)///////////////////read one burst two reqs
	arbiter_valid=1;
	in_req_address.column[3:0] =0;
	arbiter_index =0;
	@(posedge clk)
	in_req_address.column[3:0] =5;
	arbiter_index =2;
	@(posedge clk)
	arbiter_valid=0;

	@(posedge clk)///////////////////read
	arbiter_valid=1;
	@(posedge clk)
	arbiter_valid=0;

	@(posedge clk)///////////////////read
	arbiter_valid=1;
	@(posedge clk)///////////////////write
	arbiter_type = write;
	@(posedge clk)
	arbiter_valid=0;

	#100
	@(posedge clk)
	test=1;
	@(posedge clk)
	test=0;


	#100
	$stop;

end


endmodule
