module returner_tb ();
 

reg clk,rst;
wire  [ 31 : 0 ] data;
wire wd,rd;
returner r (clk,rst,wd,rd,data);
  
  
// Clock generator
  always
  begin
    #1 clk = 1;
    #1 clk = 0;
  end
  


initial begin 
  $dumpfile("dump.vcd"); $dumpvars;

	# 10 rst <= 0;
	# 10 rst <= 1;

	#11 r.write_return_array[0] =1;
	#10 r.write_return_array[1] =1;

	#10 r.write_return_array[4] =1;
	#10 r.write_return_array[3] =1;

  #100 $finish;
end

endmodule
