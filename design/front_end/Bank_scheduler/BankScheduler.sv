/********************************************************************************************************
-This block applies the scheme published on :
    Fang, Kun & Iliev, Nick & Noohi, Ehsan & Zhang, Suyu & Zhu, Zhichun. (2012). Thread Fair Memory Request Reordering - DRAM controller. 
-ROB requests are not considered it this block.
-when issue a request with no row hits, we select the next unempty one instead of selecting with(FCFS).

-The rules applied in order:
    1) Read is processed before writes (read first) unless the “write first” rule is triggered.
    2) When the write queue is about to be full (high watermark), process writes before reads until the
             write queue reach (low watermark).
    3) When at “read first”, issue next unempty buffer.
    4) When at “write first”, issue next unempty buffer.                      
********************************************************************************************************/
`include "BS_Definitions.svh"


module BankScheduler
#(parameter REQ_SIZE = 5 , parameter TYPE_POS = 5 ,parameter ROW_BITS = 4 , parameter ROW_POS=20 , parameter BURST_POS =20 ,parameter BURST_BITS =3, parameter VALID_POS = 5 , parameter ADDR_BITS=8)
(
   input   clk , rst_n , grant_i   ,
   input   [REQ_SIZE-1:0] in       ,// request size + valid bit
   output  reg pop                 ,//pop from (Mapper-schedular) FIFO      
   output  reg [REQ_SIZE-2:0] out       //request size - valid bit
);

/**********************************************Tunable parameters**********************************************/
localparam ARR_SIZE_RD =  4 ,//size of read array
           ARR_SIZE_WR =  2 ;//size of write array
           
localparam ARR_NUM_RD = 4,//number of read arrays
           ARR_NUM_WR = 3;//number of write arrays  

localparam LOW_WM  = 2,//(ARR_NUM_WR*ARR_SIZE_WR)*(10/100),//low water mark percentage of total write requests.
           HIGH_WM = 5;//(ARR_NUM_WR*ARR_SIZE_WR)*(70/100);//high water mark percentage of total write requests.

/*************************************************************************************************************/
localparam ALL_ARR = ARR_NUM_RD+ARR_NUM_WR; // total number of arrays

/************************************************array signals*****************************************************/
wire [((REQ_SIZE-1)*ALL_ARR)-1:0] array_out;
wire [(ALL_ARR*ROW_BITS)-1:0]     last_addr  ; //reg [ALL_ARR-1:0] [ROW_BITS-1:0]   last_addr
wire [(ALL_ARR*BURST_BITS)-1:0]   first_addr ; //reg [ALL_ARR-1:0] [BURST_BITS-1:0] first_addr
wire [ALL_ARR-1:0] full , empty ;
reg  [ALL_ARR-1:0] wr_en ;
wire [ARR_NUM_RD-1 : 0 ] empty_rd , full_rd;
wire [ARR_NUM_WR-1 : 0 ] empty_wr , full_wr; 
/******************************************************************************************************************/


/*********************************************Internal signals******************************************************/
reg [ALL_ARR-1:0] in_hits  ;//find row hits with input request
reg [ALL_ARR-1:0] out_hits ;//find burst hits with input request
reg [$clog2(ARR_NUM_WR*ARR_SIZE_WR):0] wr_cnt;//counter of total write requests currently available in the schedular.
reg [BURST_BITS+1 -1:0] burst_addr ; //burst address bits + valid
reg rst_burst; // active low
wire hwm , lwm , in_type , out_type , valid_in , valid_out; //valid out--> ==0 no row hits checked for last burst
/*******************************************************************************************************************/


/************************************************FSM signals*****************************************************/
localparam [1:0] // 3 states are required
    IDLE             = 2'b00,
    NEW_WRITE_BURST  = 2'b01,
    SAME_WRITE_BURST = 2'b10,
    READ_BURST       = 2'b11;

reg [1:0] CS, NS;
//************************************outputs
reg [ALL_ARR-1:0] rd_en ;//out
/*****************************************************************************************************************/


assign {hwm , lwm} = { wr_cnt>=HIGH_WM  , wr_cnt<=LOW_WM };
assign in_type  = in[TYPE_POS] ;
assign out_type = ( |rd_en ==1'b1 && |rd_en[ALL_ARR-1:ARR_NUM_RD] == 1'b1 )? `WRITE:`READ; //if there is read enable and its on a write array
assign {empty_rd , full_rd} = { empty[ARR_NUM_RD-1:0] , full[ARR_NUM_RD-1:0] }; 
assign {empty_wr , full_wr} = { empty[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] , full[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] }; 
assign valid_in =  in[VALID_POS];
assign valid_out = burst_addr[BURST_BITS] ; //valid bit is the last bit in burst address register
/******************************************functions**********************************************************/


function [$clog2(ALL_ARR)-1:0]  get_index;
    input [ALL_ARR-1:0] in ;
    input request_type ;
    get_index = (request_type == `READ)?
                    one_hot_to_index( { 3'b000, in[ARR_NUM_RD-1:0]}):
                    one_hot_to_index( { in[ALL_ARR-1:ARR_NUM_RD] , 4'b000});
endfunction


/*
    This function has input vector of bits with one hot style or with multiple ones, so it gets first one of them.
    It returns index of first one bit according to type of request.
*/
function [$clog2(ALL_ARR)-1:0]  one_hot_to_index;
    input [ALL_ARR-1:0] in ;
    casex (in)
            7'bxxxxxx1 : one_hot_to_index = 0 ;
            7'bxxxxx10 : one_hot_to_index = 1 ;
            7'bxxxx100 : one_hot_to_index = 2 ;
            7'bxxx1000 : one_hot_to_index = 3 ;
            7'bxx10000 : one_hot_to_index = 4 ;
            7'bx100000 : one_hot_to_index = 5 ;
            7'b1000000 : one_hot_to_index = 6 ;            
            default    : one_hot_to_index = 0 ;
    endcase
endfunction 


/*function [$clog2(ALL_ARR)-1:0]  get_index;
    input [ALL_ARR-1:0] in ;
    input request_type ; 
    reg [$clog2(ALL_ARR)-1:0] temp;

    casex ( {in , request_type}) 
            {7'bxxxxxx1,`READ}, {7'bxx1xxxx,`WRITE}: temp = 0 ;
            {7'bxxxxx10,`READ}, {7'bx10xxxx,`WRITE}: temp = 1 ;
            {7'bxxxx100,`READ}, {7'b100xxxx,`WRITE}: temp = 2 ;
            {7'bxxx1000,`READ}: temp = 3 ;
            default :  temp = 0 ;
    endcase
endfunction */
/*************************************************************************************************************/

integer i;

genvar g;
generate
    for (g=0; g < ARR_NUM_RD; g=g+1)  begin     ////////////////////////(g=0; g < ARR_NUM_RD; g++)  
        new_array #(.SIZE(ARR_SIZE_RD), .ENTRY_SIZE(REQ_SIZE-1),.ROW_BITS(ROW_BITS),.ROW_POS(ROW_POS),.BURST_POS (BURST_POS) ,.BURST_BITS(BURST_BITS) ) arr_rd
        (.rst_n(rst_n),.clk(clk),.wr_en(wr_en[g]),.rd_en(rd_en[g]),.in(in[REQ_SIZE-2:0]), .full(full[g]), .empty(empty[g]),.last_addr(last_addr[g*ROW_BITS +: ROW_BITS]),.first_addr(first_addr[(g*BURST_BITS)+:BURST_BITS]),.out(array_out[g*(REQ_SIZE-1)+:REQ_SIZE-1]));
    end
    for (g=ARR_NUM_RD; g < ALL_ARR; g=g+1)  begin     
        new_array #(.SIZE(ARR_SIZE_WR), .ENTRY_SIZE(REQ_SIZE-1),.ROW_BITS(ROW_BITS),.ROW_POS(ROW_POS),.BURST_POS (BURST_POS) ,.BURST_BITS(BURST_BITS)) arr_wr
        (.rst_n(rst_n),.clk(clk),.wr_en(wr_en[g]),.rd_en(rd_en[g]),.in(in[REQ_SIZE-2:0]), .full(full[g]), .empty(empty[g]),.last_addr(last_addr[g*ROW_BITS +: ROW_BITS]),.first_addr(first_addr[(g*BURST_BITS)+:BURST_BITS]),.out(array_out[g*(REQ_SIZE-1)+:REQ_SIZE-1]));
    end
endgenerate

always @(*) begin //find rowHits signals
    for(i=0 ; i<ARR_NUM_WR+ARR_NUM_RD ; i=i+1)begin 
        in_hits[i]  = (valid_in==1'b1 && full[i]==1'b0) ?  last_addr[i*ROW_BITS +: ROW_BITS]      ==  in[ROW_POS +:ROW_BITS]     : 1'b0;//  input row hits
        out_hits[i] = (valid_out==1'b1 && empty[i]==1'b0)? first_addr[i*BURST_BITS +: BURST_BITS] ==  burst_addr[BURST_BITS-1:0] :1'b0 ;// output burst hits
    end
end


always @(*) begin // calculate write enable signals
    wr_en=7'd0;
    casex({in_hits & ~full , in_type})  
        {7'bxxx0000,`READ}, {7'b000xxxx,`WRITE}: begin // no hits available
            if( (in_type == `READ && empty_rd != 0 )|| (in_type == `WRITE && empty_wr != 0 )) //an empty array found
                wr_en[get_index(empty , in_type)]=1'b1;
            else  //no empty array found, select first unfull array
                wr_en[get_index(~full , in_type)]=1'b1;                
        end
        // hits found, select first available hit
        default : wr_en[get_index(in_hits & ~full , in_type)]=1'b1;
    endcase
    wr_en = (in_type == `READ)? wr_en : { wr_en[ARR_NUM_WR-1:0] , 4'b0000 };
    if(valid_in==1'b0) wr_en = 0 ;        
end

always@(posedge clk) begin //update write requests counter
    if(!rst_n) begin
        wr_cnt <= 0;
    end
    else begin
        case ({in_type && valid_in ,  out_type  }) 
            {`WRITE , `READ } : wr_cnt <= wr_cnt+1;
            {`READ , `WRITE } : wr_cnt <= wr_cnt-1;
            default : wr_cnt <= wr_cnt;
        endcase 
    end
end


always@(posedge clk) begin //update pop signal register
    if(!rst_n) 
        pop<=1; //while reset, the schedular become in empty state.
    else 
        pop <= |full_rd  || |full_wr ;   
end

always @ (posedge clk) begin //update burst address register
    if(!rst_n || !rst_burst) begin 
        burst_addr <= 0; 
    end
    else
        burst_addr <= { 1'b1 , array_out[BURST_POS+BURST_BITS-1:BURST_POS]};
end



always @ (posedge clk) begin //update output
    if(!rst_n ) 
        out <= 0; 
    else if( rd_en !=0) //a new request will be drained from scheduler
        out <= array_out[one_hot_to_index(rd_en)*(REQ_SIZE-1) +: REQ_SIZE-1 ];
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
            if( &empty == 1'b1  || grant_i==1'b0) begin// all empty || no grant given to drain requests                    
                NS=IDLE;    
            end
            else if (hwm==1'b1) begin //////////////(hwm ||( lwm && !empty_rd==0) )
                NS=NEW_WRITE_BURST;
            end
            else if( &empty_rd == 1'b0 ) begin//hwm == 1'b0 && &empty_rd == 1'b0
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
                else begin //low water mark is set and no hits found
                    NS=IDLE;
                end 
            end      
        end 
    endcase
end

//compute output
always @(*)begin
    rd_en=7'd0 ;
    rst_burst=1'b1;
    case(CS) 
        IDLE:begin
            if( &empty == 1'b1  || grant_i==1'b0) begin// all empty || no grant given to drain requests            
                rd_en=7'd0;
                rst_burst=0;
            end
            else if (hwm==1'b1) begin // get first unempty array, no hits required
                rd_en[get_index(~empty,`WRITE)]=1'b1;
                rd_en = {  rd_en[ARR_NUM_WR-1:0] , {ARR_NUM_RD{1'b0}}   };
            end
            else begin  // get first unempty array, no hits required
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
            rd_en = {  rd_en[ARR_NUM_WR-1:0] , {ARR_NUM_RD{1'b0}}   };
        end 
    endcase
    
end


endmodule







