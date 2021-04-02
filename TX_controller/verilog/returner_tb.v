module returner_tb ();
 

//		valid + address
//reg [0:63][ 1 + 31 : 0]	read_return_array;

//		valid + address + data
//reg [0:63]						write_return_array;


reg clk,rst;
wire  [ 31 : 0 ] data;

returner r (clk,rst,wd,rd,data);




// Clock generator
  always
  begin
    #1 clk = 1;
    #1 clk = 0;
  end


initial begin 

	# 10 rst <= 0;
	# 10 rst <= 1;

	#10 r.write_return_array[0] =1;
	#10 r.write_return_array[1] =1;

	#10 r.write_return_array[4] =1;
	#10 r.write_return_array[3] =1;

end

endmodule