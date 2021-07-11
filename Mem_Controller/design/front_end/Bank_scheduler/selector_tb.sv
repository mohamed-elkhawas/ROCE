`define READ  1'b1
`define WRITE 1'b0
//selector definintions
`define ADDR_BITS       8 
`define ADDR_FIRST_POS  8 
`define BUFFER_SIZE     4
`define NUM_OF_BUFFERS  4
`define INDEX_BITS      7
`define REQUEST_SIZE    `ADDR_BITS+`INDEX_BITS+1 // address  + bits of index + one bit for request type(least significant bit)

//fifo definitions
`define BUF_SIZE `BUFFER_SIZE
`define BUF_WIDTH `REQUEST_SIZE-1 // remove request type bit


module tb();

reg  Clock;
reg  reset;
reg  [`REQUEST_SIZE-1:0]   in;

wire  [`NUM_OF_BUFFERS-1:0] [$clog2(`BUFFER_SIZE):0] free_entries   ;
wire  [`NUM_OF_BUFFERS-1:0] full;
wire  [`NUM_OF_BUFFERS-1:0] empty;
wire  [`NUM_OF_BUFFERS-1:0] write_enable;
reg   [`NUM_OF_BUFFERS-1:0] read_enable;
wire  [`REQUEST_SIZE-1:1]   out; //output data from selector
wire  [`NUM_OF_BUFFERS-1:0] [`REQUEST_SIZE-1:1]   fifo_out ; //output data from selector
  
always #5 Clock = ~Clock;

initial begin
    /****************************************************************************************
        -scenario #1.
        -four read requests with same address (all have row hits).
        -expected output:
            all requests are pushed to first fifo.
    ****************************************************************************************
    Clock=0;
    reset = 0;
    #6
    reset=1;
    read_enable=0;
    #10
    in={8'hff,7'd2,`READ}; //new input READ request with index 2 and address oxff
    #10
    in={8'hff,7'd3,`READ}; //new input READ request with index 3 and address oxff 
    #10
    in={8'hff,7'd4,`READ}; //new input READ request with index 4 and address oxff
    #10
    in={8'hff,7'd5,`READ}; //new input READ request with index 5 and address oxff*/

    /****************************************************************************************
        -scenario #2.
        -five read requests with same address (all have row hits).
        -expected output:
            first four requests are pushed to first fifo.
            the last request is pushed to the next empty fifo.
    ****************************************************************************************
    Clock=0;
    reset = 0;
    #6
    reset=1;
    read_enable=0;
    #10
    in={8'hff,7'd2,`READ}; //new input READ request with index 2 and address oxff
    #10
    in={8'hff,7'd3,`READ}; //new input READ request with index 3 and address oxff 
    #10
    in={8'hff,7'd4,`READ}; //new input READ request with index 4 and address oxff
    #10
    in={8'hff,7'd5,`READ}; //new input READ request with index 5 and address oxff
    #10
    in={8'hff,7'd6,`READ}; //new input READ request with index 6 and address oxff*/



    /****************************************************************************************
        -scenario #3.
        -five read requests with all different addresses.
        -expected output:
            each request is pushed in order to all buffers, then it round over all again.
            ex: if there are 4 fifos, then 1 request to each buffer and the five one is pued to first fifo.
    ****************************************************************************************

    Clock=0;
    reset = 0;
    #6
    reset=1;
    read_enable=0;
    #10
    in={8'hff,7'd2,`READ}; //new input READ request with index 2 and address oxff
    #10
    in={8'hef,7'd3,`READ}; //new input READ request with index 3 and address oxef 
    #10
    in={8'hdf,7'd4,`READ}; //new input READ request with index 4 and address oxdf
    #10
    in={8'hcf,7'd5,`READ}; //new input READ request with index 5 and address oxcf
    #10
    in={8'hbf,7'd6,`READ}; //new input READ request with index 6 and address oxhf*/


    /****************************************************************************************
        -scenario #4.
        -six READ requests with addresses as following:
             1-> A address.
             2-> B address.
             3-> B address.
             4-> A address.
             5-> A address.
             6-> C address.
        -expected output:
            A addresses must be pushed into first fifo.
            B addressses must be pushed into second fifo.
            C address will be pushed into next fifo with most empty entries.
              ---> the third and fourth fifos are empty, so it will pushed into the third one.
    ****************************************************************************************

    Clock=0;
    reset = 0;
    #6
    reset=1;
    read_enable=0;
    #10
    in={8'hff,7'd2,`READ}; //new input READ request with index 2 and address oxff
    #10
    in={8'hef,7'd3,`READ}; //new input READ request with index 3 and address oxef 
    #10
    in={8'hef,7'd4,`READ}; //new input READ request with index 4 and address oxef
    #10
    in={8'hff,7'd5,`READ}; //new input READ request with index 5 and address oxff
    #10
    in={8'hff,7'd6,`READ}; //new input READ request with index 6 and address oxff
    #10
    in={8'haf,7'd7,`READ}; //new input READ request with index 7 and address oxaf*/


    /****************************************************************************************
        -scenario #5.
        -six requests with addresses as following:
             1-> A address - read.
             2-> B address - read.
             3-> B address - write.
             4-> A address - read.
             5-> A address - write.
             6-> C address - write.
        -expected output:
            read with A into first fifo.
            read with B into second fifo.
            write with B will not be processed.
            read with A into first fifo.
            write with A will not be processed.
            write with C will not be processed.
    ****************************************************************************************/

    Clock=0;
    reset = 0;
    #6
    reset=1;
    read_enable=0;
    #10
    in={8'hff,7'd2,`READ}; //new input read request with index 2 and address oxff
    #10
    in={8'hef,7'd3,`READ}; //new input READ request with index 3 and address oxef 
    #10
    in={8'hef,7'd4,`WRITE}; //new input write request with index 4 and address oxef
    #10
    in={8'hff,7'd5,`READ}; //new input READ request with index 5 and address oxff
    #10
    in={8'hff,7'd6,`WRITE}; //new input write request with index 6 and address oxff
    #10
    in={8'haf,7'd7,`WRITE}; //new input write request with index 7 and address oxaf


end




genvar i;
generate
   for (i=0; i < `NUM_OF_BUFFERS; i=i+1) 
   begin
     fifo#(.BUF_SIZE(`BUFFER_SIZE),.BUF_WIDTH(`BUF_WIDTH))
     ff( .clk(Clock), .rst(reset), .buf_in(out), .buf_out(fifo_out[i]),.wr_en(write_enable[i]),.rd_en(read_enable[i]),.buf_empty(empty[i]),.buf_full(full[i]), .fifo_counter(free_entries[i]) );

   end
endgenerate

selector#(.TYPE(`READ),.ADDR_BITS(`ADDR_BITS), .ADDR_FIRST_POS(`ADDR_FIRST_POS) ,.BUFFER_SIZE(`BUFFER_SIZE)  ,.NUM_OF_BUFFERS(`NUM_OF_BUFFERS), .REQUEST_SIZE(`REQUEST_SIZE) )
read_selector(.reset(reset),.clk(Clock),.data_in(in) ,.free_size(free_entries),.wr_en(write_enable),.data_out(out));

endmodule