/********************************************************************************************************
    -This block inserts the request to the suitable reading/writing fifo according to the following criteria:
        1- If there are row hits in many buffers, insert into fifo with most empty entries.
        2- If there is one fifo with row hit, select it.
        3- If there is no row hit in any of the available buffers, insert into  with most empty entries.
        4- If there are many fifos with same number of empty entries, select the first one.

    Warning:
    -This block assumes that there is always at least one unfull buffer.
     if a new request arrived, while no empty buffer available, unexpected behaviour may happen.                              
********************************************************************************************************/



module selector
#(parameter TYPE =1,parameter ADDR_BITS = 8, parameter ADDR_FIRST_POS =0 ,parameter BUFFER_SIZE = 4  ,parameter NUM_OF_BUFFERS = 4, parameter REQUEST_SIZE = 32 )
(
   input   clk , reset ,
   input   [REQUEST_SIZE-1:0] data_in   ,
   input   [NUM_OF_BUFFERS-1:0] [$clog2(BUFFER_SIZE):0] free_size ,/* number of empty entries in each buffer */
   output  [NUM_OF_BUFFERS-1:0] wr_en   ,  /* write enable signal to add new request in a buffer*/
   output  [REQUEST_SIZE-1:1] data_out
);


/***************************************internal components and signals***************************************/

reg [NUM_OF_BUFFERS-1:0] [ADDR_BITS-1:0] last_addr ; //array of last adrresses inserted in buffers
reg [NUM_OF_BUFFERS-1:0] row_hits  ;
integer j,i ;


/***************************************needed functions***************************************/

//This function returns output of write enables. 
function [NUM_OF_BUFFERS-1:0]set_out;
    input [NUM_OF_BUFFERS-1:0] hits ;   
    input [NUM_OF_BUFFERS-1:0] [$clog2(BUFFER_SIZE):0] empty_entries ;

    reg [NUM_OF_BUFFERS-1:0] [$clog2(BUFFER_SIZE):0] masked_empty_entries ;
    reg [$clog2(NUM_OF_BUFFERS):0] counter , tempindex;
    reg [$clog2(BUFFER_SIZE):0] temp ;    
    
    begin
        tempindex=0;
        for(counter= 0 ; counter<NUM_OF_BUFFERS ; counter++)begin 
           if (hits[counter]==1)begin
               masked_empty_entries[counter]=empty_entries[counter];
           end
           else begin
               masked_empty_entries[counter]=0;
           end
                   
        end           
        if(masked_empty_entries==0)begin //no row hits or there are row hits but with non empty buffers.        
            masked_empty_entries=empty_entries;
        end
        temp= masked_empty_entries[0];
        //find the buffer index with maximum empty entries.
        for(counter= 0 ; counter<NUM_OF_BUFFERS ; counter++)begin
            if(temp<masked_empty_entries[counter]  ) begin 
                temp=masked_empty_entries[counter];
                tempindex=counter;                 
            end            
        end    
    end    
    set_out=1<<tempindex;
endfunction



/***************************************update main registers***************************************/
always @(posedge clk) begin
    if(!reset) begin
       last_addr<=0;                                      
    end             
    else begin
        for(j = 0 ; j< NUM_OF_BUFFERS ; j++)begin
            if(data_in[0]==TYPE && set_out(row_hits,free_size)[j]==1'b1)begin 
                last_addr[j]<=data_in[ADDR_FIRST_POS+ADDR_BITS-1:ADDR_FIRST_POS];
            end
        end           
    end
end


/***************************************calculate row hits***************************************/ 
//if last address in buffer is equal to new request and the buffer is not empty, then there is a row hit.
// ex : last addr = 4'b1110 , data_in_addr = 4'b1110, then row hit of this buffer = 1'b1
// ex : last addr = 4'b1110 , data_in_addr = 4'b1010, then row hit of this buffer = 1'b0
always @(data_in) begin
    for(i = 0 ; i< NUM_OF_BUFFERS ; i++)begin 
        row_hits[i]= ( free_size[i]!=BUFFER_SIZE && last_addr[i] == data_in[ADDR_FIRST_POS+ADDR_BITS-1:ADDR_FIRST_POS]) ;            
    end
end


/***************************************output signals ***************************************/ 
assign data_out=data_in[REQUEST_SIZE-1:1];
assign wr_en=(data_in[0]==TYPE)?set_out(row_hits,free_size):0;

endmodule
