/********************************************************************************************************
-This block applies the scheme published on :
    Fang, Kun & Iliev, Nick & Noohi, Ehsan & Zhang, Suyu & Zhu, Zhichun. (2012). Thread Fair Memory Request Reordering - DRAM controller. 
-ROB requests are not considered it this block.
-when issue a new Burst, we select the next array index based one last index we drained requests from; in a
    round robin style, not in a FCFS way.

-The rules applied for draining new requests:
    1) Read is processed before writes (read first) unless the “write first” rule is triggered (with high water mark).
    2) When the write queue is about to be full (high watermark), process writes before reads until the
             write queue reach (low watermark).
    3) When at “read burst”, issue next arrays after last array index accessed last time.
    4) When at “write first”, issue next arrays after last array index accessed last time.


-Regarding receiving new requests to store: (Heuristic critera depends on my opinion, may not be the optimum way)
    1- First, check for hits in all arrays.
    2- If multiple hits are available, select first one.
    3- In case of no hits exists, check for empty arrays first.
    4- If multiple empty arrays are available, select first one.
    5- In case of no empty arrays, select first one.


-Regarding any modifications in the module, any change is ok except number of each array parameter.
-Changing number of arrays requires editing only both functions to fit the new quantity of arrays,
    as all signals communcating with arrays are one hot encoded with each bit represents a single array.
********************************************************************************************************/
`include "BS_Definitions.svh"


module BankScheduler
#(parameter REQ_SIZE = 5 , parameter TYPE_POS = 5 ,parameter ROW_BITS = 4 , parameter ROW_POS=20 , parameter BURST_POS =20 ,parameter BURST_BITS =3,parameter ADDR_BITS=8)
(
   input   clk , rst_n , grant_i , valid_i,
   input   [REQ_SIZE-1:0] data_in         ,// input data 
   output  grant_o                        ,// pop from (Mapper-schedular) FIFO      
   output  reg [REQ_SIZE-1:0] data_out    ,// output data
   output  req                             // apply request to Arbiter to control the bus 
);

/**********************************************Tunable parameters**********************************************/
localparam ARR_SIZE_RD =  4 ,//size of read array
           ARR_SIZE_WR =  2 ;//size of write array
           
localparam ARR_NUM_RD = 4,//number of read arrays
           ARR_NUM_WR = 3;//number of write arrays 

localparam ALL_ARR = ARR_NUM_RD+ARR_NUM_WR; // total number of arrays

localparam LOW_WM  = 2,//(ARR_NUM_WR*ARR_SIZE_WR)*(10/100),//low water mark percentage of total write requests.
           HIGH_WM = 5;//(ARR_NUM_WR*ARR_SIZE_WR)*(70/100);//high water mark percentage of total write requests.

/*************************************************************************************************************/

/************************************************array signals*****************************************************/
wire [ (REQ_SIZE*ALL_ARR )-1:0] array_out  ; // heads of all arrays
wire [(ALL_ARR*ROW_BITS)-1:0]     last_addr  ; //reg [ALL_ARR-1:0] [ROW_BITS-1:0]   last_addr
wire [(ALL_ARR*BURST_BITS)-1:0]   first_addr ; //reg [ALL_ARR-1:0] [BURST_BITS-1:0] first_addr
wire [ALL_ARR-1:0] full , empty ;
wire [ARR_NUM_RD-1 : 0 ] empty_rd , full_rd;
wire [ARR_NUM_WR-1 : 0 ] empty_wr , full_wr; 

reg  [ALL_ARR-1:0] wr_en ;
/******************************************************************************************************************/


/*********************************************Internal signals******************************************************/
reg [ALL_ARR-1:0] in_hits  ;//find row hits with input request
reg [ALL_ARR-1:0] out_hits ;//find burst hits with current burst address stored in burst address register

reg [$clog2(ARR_NUM_WR*ARR_SIZE_WR):0] wr_cnt;//counter of total write requests currently available in the schedular.

reg [BURST_BITS+1 -1:0] burst_addr ; //burst address bits + valid
reg rst_burst; // active low
wire hwm , lwm , in_type , out_type , valid_burst; //valid burst--> indicats whether the last burst address stored is currently used burst.
/*******************************************************************************************************************/


/************************************************FSM signals*****************************************************/
localparam [1:0] // 3 states are required
    IDLE             = 2'b00,
    NEW_WRITE_BURST  = 2'b01,
    SAME_WRITE_BURST = 2'b10,
    READ_BURST       = 2'b11;

reg [1:0] CS, NS;
reg [ALL_ARR-1:0] rd_en ; 
/*****************************************************************************************************************/
assign {hwm , lwm} = { wr_cnt>=HIGH_WM  , wr_cnt<=LOW_WM };

assign {empty_rd , full_rd} = { empty[ARR_NUM_RD-1:0] , full[ARR_NUM_RD-1:0] }; 
assign {empty_wr , full_wr} = { empty[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] , full[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] }; 


assign valid_burst = burst_addr[BURST_BITS] ; //valid bit is the last bit in burst address register.

assign in_type  = data_in[TYPE_POS] ;
assign out_type = ( |rd_en ==1'b1 && |rd_en[ALL_ARR-1:ARR_NUM_RD] == 1'b1 )? `WRITE:`READ; //if there is read enable and its on a write array. 



assign grant_o = |wr_en ; // whenever new request is processed, then it will be stored in arrays successfully
assign req = ! (&empty) ; // if at least one array is not full, issue request for arbiter to control the bus
/******************************************functions**********************************************************/

// return index of set bit in an input with one hot encoding style based on type of given request type
function [$clog2(ALL_ARR)-1:0]  get_index;
    input [ALL_ARR-1:0] in ;
    input request_type ;
    get_index = (request_type == `READ)?
                    hot2idx( { 3'b000, in[ARR_NUM_RD-1:0]}):
                    hot2idx( { in[ALL_ARR-1:ARR_NUM_RD] , 4'b0000});
endfunction


// It returns index of first one bit with one hot style.
// we use casex to call function for non-hot encoded input.

function [$clog2(ALL_ARR)-1:0]  hot2idx;
    input [ALL_ARR-1:0] in ;
    casex (in)
            7'bxxxxxx1 : hot2idx = 0 ;
            7'bxxxxx10 : hot2idx = 1 ;
            7'bxxxx100 : hot2idx = 2 ;
            7'bxxx1000 : hot2idx = 3 ;
            7'bxx10000 : hot2idx = 4 ;
            7'bx100000 : hot2idx = 5 ;
            7'b1000000 : hot2idx = 6 ;            
            default    : hot2idx = 0 ;
    endcase
endfunction 
/*************************************************************************************************************/


integer i;

genvar g;
generate
    for (g=0; g < ARR_NUM_RD; g=g+1)  begin       
        array #(.SIZE(ARR_SIZE_RD), .ENTRY_SIZE(REQ_SIZE),.ROW_BITS(ROW_BITS),.ROW_POS(ROW_POS),.BURST_POS (BURST_POS) ,.BURST_BITS(BURST_BITS) ) arr_rd
        (.rst_n(rst_n),.clk(clk),.wr_en(wr_en[g]),.rd_en(rd_en[g]),.data_in(data_in), .full(full[g]), .empty(empty[g]),.last_addr(last_addr[g*ROW_BITS +: ROW_BITS]),.first_addr(first_addr[(g*BURST_BITS)+:BURST_BITS]),.out(array_out[(g*REQ_SIZE)  +:REQ_SIZE]));
    end
    for (g=ARR_NUM_RD; g < ALL_ARR; g=g+1)  begin     
        array #(.SIZE(ARR_SIZE_WR), .ENTRY_SIZE(REQ_SIZE),.ROW_BITS(ROW_BITS),.ROW_POS(ROW_POS),.BURST_POS (BURST_POS) ,.BURST_BITS(BURST_BITS)) arr_wr
        (.rst_n(rst_n),.clk(clk),.wr_en(wr_en[g]),.rd_en(rd_en[g]),.data_in(data_in), .full(full[g]), .empty(empty[g]),.last_addr(last_addr[g*ROW_BITS +: ROW_BITS]),.first_addr(first_addr[(g*BURST_BITS)+:BURST_BITS]),.out(array_out[(g*REQ_SIZE) +:REQ_SIZE]));
    end
endgenerate

always @(*) begin //find row Hits / burst hits signals
    for(i=0 ; i<ARR_NUM_WR+ARR_NUM_RD ; i=i+1)begin 
        in_hits[i]  = (valid_i==1'b1 && full[i]==1'b0) ?     last_addr[i*ROW_BITS +: ROW_BITS]      ==  data_in[ROW_POS +:ROW_BITS]     :1'b0;//  input row hits
        out_hits[i] = (valid_burst==1'b1 && empty[i]==1'b0)? first_addr[i*BURST_BITS +: BURST_BITS] ==  burst_addr[BURST_BITS-1:0]      :1'b0;// output burst hits
    end
end


always @(*) begin // calculate write enable signals
    wr_en=7'd0;
    casex({in_hits, in_type})  
        {7'bxxx0000,`READ}, {7'b000xxxx,`WRITE}: begin // no hits available
            if( (in_type == `READ && |empty_rd == 1'b1 )|| (in_type == `WRITE && |empty_wr == 1'b1 )) //an empty array found
                wr_en[get_index(empty , in_type)]=1'b1;
            else if( (in_type == `READ && &full_rd == 1'b0 )|| (in_type == `WRITE && &full_wr == 1'b0 ))//unfull array found, select first unfull array
                wr_en[get_index(~full , in_type)]=1'b1;                
        end
        // hits found, select first available hit
        default : wr_en[get_index(in_hits, in_type)]=1'b1;
    endcase
    if(valid_i==1'b0) wr_en = 0 ;        
end

always@(posedge clk) begin //update write requests counter
    if(!rst_n) begin
        wr_cnt <= 0;
    end
    else begin
        casex ({ {in_type , grant_o } , out_type  }) 
            { {`WRITE , 1'b1 } , `READ  } : wr_cnt <= wr_cnt+1;
            { {1'bx , 1'b0 }   , `WRITE } : wr_cnt <= wr_cnt-1;
            { {`READ  , 1'b1 } , `WRITE } : wr_cnt <= wr_cnt-1;
            default : wr_cnt <= wr_cnt;
        endcase 
    end
end

always @ (posedge clk) begin //update burst address register
    if(!rst_n || !rst_burst)  
        burst_addr <= 0; 
    else
        burst_addr <= { 1'b1 , array_out[BURST_POS + hot2idx(rd_en)*(REQ_SIZE-1)   +: BURST_BITS]};
end



always @ (posedge clk) begin //update output
    if(!rst_n ) 
        data_out <= 0; 
    else if( rd_en !=0) //a new request will be drained from scheduler
        data_out <= array_out[hot2idx(rd_en)*(REQ_SIZE) +: REQ_SIZE ];
end


/************************************************fsm template****************************************************/

// UPDATE FSM 
always @(posedge clk)begin
    if(!rst_n)begin
        CS  <= IDLE;
    end
    else begin
        CS  <= NS;
    end
end


// Compute Next State
always @(*) begin
    NS=CS;
    case(CS) 
        IDLE:begin
            if( &empty == 1'b1  || grant_i==1'b0) // all empty || no grant given to drain requests                    
                NS=IDLE;    
            else if (grant_i ==1'b1)begin
                if ( hwm==1'b1 ||( lwm && &empty_rd==1'b1) ) //hight watermark or low water mark with empty reads  
                    NS=NEW_WRITE_BURST;
                else if( &empty_rd == 1'b0 ) //hwm == 1'b0 && &empty_rd == 1'b0
                    NS=READ_BURST;
            end       
        end
        READ_BURST : begin
            if ( |out_hits[ARR_NUM_RD-1:0] == 1'b1 ) begin // burst hit exists
                NS=READ_BURST;
            end
            else begin // burst hit does not exist 
                NS=IDLE;
            end                             
        end
        NEW_WRITE_BURST ,SAME_WRITE_BURST :begin
            if ( |out_hits[ALL_ARR- 1:ARR_NUM_RD] == 1'b1  ) begin // burst hit exists
                NS=SAME_WRITE_BURST;
            end
            else begin  // no burst hits
                if (lwm == 1'b0) begin // continue drain write till low watermark
                    NS=NEW_WRITE_BURST;
                end
                else if(lwm ==1'b1) begin //low water mark is set and no hits found
                    NS=IDLE;
                end 
            end      
        end 
    endcase
end

//compute output
always @(*)begin
    rd_en=7'd0 ;
    rst_burst=1'b1;//active low
    case(CS) 
        IDLE:begin
            if( &empty == 1'b1 || grant_i==1'b0 ) begin// all empty || no grant given to drain requests            
                rd_en=7'd0;
                rst_burst=0;
            end
            else if (grant_i ==1'b1)begin
                if ( hwm==1'b1 ||( lwm && &empty_rd==1'b1) )   // get first unempty array, no hits required
                    rd_en[get_index(~empty,`WRITE)]=1'b1;
                else if( &empty_rd == 1'b0 ) // get first unempty array, no hits required
                    rd_en[get_index(~empty,`READ)]=1'b1;
            end    

        end    
        READ_BURST:begin
            if ( |out_hits[ARR_NUM_RD-1:0] == 1'b1 ) begin // burst hit exists
                rd_en[get_index(out_hits,`READ)]=1'b1;
            end
            else begin // burst hit does not exist 
                rd_en=0;
                rst_burst=0;
            end        
        end
        NEW_WRITE_BURST , SAME_WRITE_BURST :begin
            if ( |out_hits[ALL_ARR- 1:ARR_NUM_RD] == 1'b1  ) begin // burst hit exists
                rd_en[get_index(out_hits,`WRITE)]=1'b1;
            end
            else begin  // continue drain write bursts till low water mark
                if (lwm == 1'b0) 
                    rd_en[get_index(~empty,`WRITE)]=1'b1;
                else begin
                    rd_en=0;
                    rst_burst=0;
                end
            end 
        end 
    endcase
    
end


endmodule







