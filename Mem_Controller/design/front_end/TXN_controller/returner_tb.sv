module returner_tb ();
 

logic clk,rst,wd,rd;

logic the_type;
logic valid;
logic  [ 31 : 0 ] in_data;
logic  [ 5 : 0 ] index;


returner r (clk,rst,valid,the_type,in_data,index,wd,rd,data);


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
	valid =1;
	the_type =0;
	in_data =1;
	index =0; /////////read with index 0
	@(posedge clk)
	valid =0;
	in_data =10;


	#100 
	@(posedge clk)
	valid =1;
	the_type =0;
	in_data =2;
	index =1; /////////read with index 1
	@(posedge clk)
	valid =0;

	#100 
	@(posedge clk)
	valid =1;
	the_type =0;
	in_data =3;
	index =3; /////////read with index 3
	@(posedge clk)
	valid =0;

	#100 
	@(posedge clk)
	valid =1;
	the_type =0;
	in_data =4;
	index =2; /////////read with index 2
	@(posedge clk)
	valid =0;
	
	#100 
	@(posedge clk)

	valid =1;
	the_type =1;
	in_data =1;
	index =0; /////////write with index 0
	@(posedge clk)
	valid =0;


	#100 
	@(posedge clk)
	valid =1;
	the_type =1;
	in_data =1;
	index =1; /////////write with index 1
	@(posedge clk)
	valid =0;

	#100 
	@(posedge clk)
	valid =1;
	the_type =1;
	in_data =1;
	index =0; /////////write with index 4
	@(posedge clk)
	valid =0;

	#100 
	@(posedge clk)
	valid =1;
	the_type =1;
	in_data =1;
	index =3; /////////write with index 3
	@(posedge clk)
	valid =0;


	#100 
	@(posedge clk)
	valid =1;
	the_type =1;
	in_data =1;
	index =2; /////////write with index 2
	@(posedge clk)
	valid =0;

	#100
	$stop;

end

endmodule
