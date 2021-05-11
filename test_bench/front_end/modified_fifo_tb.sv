module modified_fifo_tb import types_def::*; ();


logic clk,rst;

//request request_in ;


logic [data_width + address_width :0]request_in; //////////// concatenated input works

logic [read_entries_log -1:0]            index_i;
logic valid_in , grant_in;

request request_o ;
logic [read_entries_log -1:0]            index_o;


modified_fifo m (clk,rst,request_in,index_i,valid_in,grant_o ,request_o,index_o,valid_o, grant_in);


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

	grant_in =0;



	@(posedge clk)
	valid_in =1;

	request_in[data_width + address_width] = 1; // write
	request_in[address_width -1:0] = 19; // address
	index_i = 5;

	request_in[data_width + address_width -1:address_width] = 2; //data

	@(posedge clk)
	valid_in =0;

/*
	@(posedge clk)
	valid_in =1;

	request_in.req_type = read;
	request_in.address = 2;
	index_i = 5;

	request_in.data = 2;

	@(posedge clk)
	valid_in =0;


	#100 
	@(posedge clk)
	valid_in =1;
	
	request_in.req_type = write;
	request_in.address = 1;
	index_i = 7;

	request_in.data = 4;
	
	@(posedge clk)
	valid_in =0;


	#100 
	@(posedge clk) // pop read
	grant_in =1;
	@(posedge clk)
	grant_in =0;
	
	#100
	@(posedge clk) // pop write
	grant_in =1;
	@(posedge clk)
	grant_in =0;


	for (int i = 0; i < 5; i++) begin
	#100 
	@(posedge clk)
	valid_in =1;
	
	request_in.req_type = write;
	request_in.address = 1;
	index_i = 7;

	request_in.data = 4;
	
	@(posedge clk)
	valid_in =0;
	end
*/	
	#100
	$stop;

end

endmodule
