/********************************************************************************************************
    -An array module with:
        1- read pointer
        2- write pointer
        3- last address register
        4- empty signal
        5- full signal   


     - Note: this module assume read/write enable signals is ready with no empty/full violations.
********************************************************************************************************/
`include "BS_Definitions.svh"

module new_array
#(parameter SIZE = 4, parameter ENTRY_SIZE = 32, parameter ROW_BITS = 4 , parameter ROW_POS = 20, parameter BURST_POS =20 ,parameter BURST_BITS =3)
(
   input   rst_n                   ,
   input   clk                     ,
   input   rd_en                   ,
   input   wr_en                   ,
   input   [ENTRY_SIZE-1:0] in     , // input 
   output  full , empty            ,
   output  reg [ROW_BITS-1:0]   last_addr ,
   output  reg [BURST_BITS-1:0] first_addr,
   output  reg [ENTRY_SIZE-1:0] out
);




/**internal signals**/ 
reg [($clog2(SIZE))-1:0] rd_ptr , wr_ptr;
reg [($clog2(SIZE)):0] counter;  
reg [(SIZE*ENTRY_SIZE)-1:0]  arr ;////reg [SIZE-1:0] [ENTRY_SIZE-1:0]  arr ;



always @(*) begin
   if( counter ==0 )
      last_addr =0;      
   else begin
   //current write pointer value is the next empty place to write not the last address written we add 1 to make it one based instead of zero based value
      if(wr_ptr == 0)
         last_addr=arr[BURST_POS+ ENTRY_SIZE*(SIZE-1) +: BURST_BITS]; //avoid (0-1) case
      else
         last_addr=arr[BURST_POS+ ENTRY_SIZE*(wr_ptr-1) +: BURST_BITS];
   end
end


always @(*) begin
   if( counter ==0 )
      first_addr =0;     
   else 
      first_addr=arr[ROW_POS + ENTRY_SIZE*(rd_ptr) +: ROW_BITS];      
end


always @(*) begin
   if( counter == 0 )
      out = 0;        
   else 
      out=arr[ENTRY_SIZE*(rd_ptr)+:ENTRY_SIZE];
end



assign { empty ,full } = { counter==0  , counter==SIZE };

always @(posedge clk )begin
   if( !rst_n )
       counter <= 0;
   else if( rd_en && wr_en )
       counter <= counter;
   else if( wr_en )
       counter <= counter + 1;
   else if( rd_en )
       counter <= counter - 1;
   else
      counter <= counter;
end

always @(posedge clk)begin
   if(!rst_n)
      arr <= 0 ;
   else
      if( wr_en )
         arr[ENTRY_SIZE*wr_ptr+:ENTRY_SIZE] <= in;    ////arr[ wr_ptr ] <= in;   
end


always@(posedge clk )begin
   if( !rst_n )
   begin
      wr_ptr <= 0;
      rd_ptr <= 0;
   end
   else
   begin
      if( wr_en )
         wr_ptr <= wr_ptr + 1;
      else  
         wr_ptr <= wr_ptr;
      if( rd_en )   
         rd_ptr <= rd_ptr + 1;
      else 
         rd_ptr <= rd_ptr;
   end

end


endmodule