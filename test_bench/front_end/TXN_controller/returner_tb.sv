module returner_tb ();
 

logic clk,rst,wd,rd;

logic the_type;
logic valid;
logic  [ 31 : 0 ] in_data;
logic  [ 5 : 0 ] index;


logic  [ 31 : 0 ] out_data;


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
	#10
	
	valid =1;
	the_type =0;
	in_data =1;
	index =0; /////////0
	#2
	valid =0;


	#100 
	valid =1;
	the_type =0;
	in_data =2;
	index =1; /////////1
	#2
	valid =0;

	#100 
	valid =1;
	the_type =0;
	in_data =3;
	index =3; /////////3
	#2
	valid =0;

	#100 
	valid =1;
	the_type =0;
	in_data =4;
	index =2; /////////2
	#2
	valid =0;
	
	#100 

	valid =1;
	the_type =1;
	in_data =1;
	index =0; /////////0
	#2
	valid =0;


	#100 
	valid =1;
	the_type =1;
	in_data =1;
	index =1; /////////1
	#2
	valid =0;

	#100 
	valid =1;
	the_type =1;
	in_data =1;
	index =0; /////////4
	#2
	valid =0;

	#100 
	valid =1;
	the_type =1;
	in_data =1;
	index =3; /////////3
	#2
	valid =0;


	#100 
	valid =1;
	the_type =1;
	in_data =1;
	index =2; /////////2
	#2
	valid =0;

	#100
	$stop;

end

endmodule
