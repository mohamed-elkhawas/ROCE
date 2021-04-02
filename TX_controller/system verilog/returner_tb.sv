module returner_tb ();
 
/*
//		valid + address
logic [0:63][ 1 + 31 : 0]	read_return_array;

//		valid + address + data
logic [0:63]						write_return_array;

*/
logic clk,rst,wd,rd;

logic  [ 31 : 0 ] data;

returner r (clk,rst,wd,rd,data);


task reset();
	# 10 rst <= 0;
	# 10 rst <= 1;
endtask 

// Clock generator
  always
  begin
    #1 clk = 1;
    #1 clk = 0;
  end


initial begin 

	reset();

	#100 r.write_return_array[0] =1;
	#100 r.write_return_array[1] =1;

	#100 r.write_return_array[4] =1;
	#100 r.write_return_array[3] =1;

end

endmodule