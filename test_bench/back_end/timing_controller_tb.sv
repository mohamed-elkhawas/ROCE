module timing_controller_tb import types_def::*; ();

parameter no_of_bursts = 4;

logic clk,rst_n;

burst_states_type [no_of_bursts:0] in_burst_state;
r_type [no_of_bursts:0] in_burst_type;
address_type [no_of_bursts:0] in_burst_address;

command [no_of_bursts:0] burst_start_next_cmd;

timing_controller t (clk,rst_n,in_burst_state,in_burst_type,in_burst_address,burst_start_next_cmd);


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

	#7
	@(posedge clk)
	in_burst_state[0] = almost_done;

	#8
	@(posedge clk)
	in_burst_state[0] = full;


	#100 
	@(posedge clk)
	


	
	#100
	$stop;

end

endmodule
