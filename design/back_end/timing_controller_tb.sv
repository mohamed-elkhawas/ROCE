module timing_controller_tb import types_def::*; ();

parameter no_of_bursts = 4;

logic clk,rst_n;

burst_states_type [no_of_bursts:0] in_burst_state;
r_type [no_of_bursts:0] in_burst_type;
address_type [no_of_bursts:0] in_burst_address;

command burst_start_next_cmd;

timing_controller t (clk,rst_n,in_burst_state,in_burst_type,in_burst_address,burst_start_next_cmd,cmd_i);


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
	rst_n = 1;
	in_burst_state[0] =empty;
	in_burst_state[1] =empty;
	in_burst_state[2] =empty;
	in_burst_state[3] =empty;
	in_burst_type =0;
	in_burst_address = 0;

	#11
	

	#100
	@(posedge clk) 
	in_burst_state[0] = started_filling;
	in_burst_address = 0;

	@(posedge clk)
	in_burst_state[0] = full;

	@(posedge clk) 
	in_burst_state[1] = started_filling;
	in_burst_address[1].bank = 0;
	in_burst_address[1].bank_group = 0;

	@(posedge clk)
	in_burst_state[1] = full;

	@(posedge clk) 
	in_burst_state[2] = started_filling;
	in_burst_address[2].bank = 1;
	in_burst_address[2].bank_group = 0;

	@(posedge clk)
	in_burst_state[2] = full;

	@(posedge clk) 
	in_burst_state[3] = started_filling;
	in_burst_address[3].bank = 2;
	in_burst_address[3].bank_group = 1;
	
	in_burst_type[3] = write;

	@(posedge clk)
	in_burst_state[3] = full;



	#100 
	@(posedge clk)
	
	
	@(posedge clk)



	
	#100
	$stop;

end

endmodule
