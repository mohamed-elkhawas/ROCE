module Groups_Fsm
(   
    input  clk, rst_n,
    input  flag ,    // if flag is 1 from burst hanndler, then we can drain  more bursts
    input  [3:0] Req , //request from bank groups to enable each bank group fsm
    input  [3:0] Done, // acknowledge from each bank group fsm after Starting a burst from scheduler is finished
    output reg Start_A, Start_B, Start_C, Start_D,
    output reg [1:0] sel
);


wire ReqD, ReqC, ReqB, ReqA ;
wire Done_D, Done_C, Done_B, Done_A ;


assign {ReqD, ReqC, ReqB, ReqA} = Req ;
assign {Done_D, Done_C, Done_B, Done_A} = Done ;

/*reg [NUM_OF_BURSTS-1:0] TimeOutClockPeriods;
reg RunTimer, TimesUp;
reg [$clog2(TIME_OUT_PERIOD)-1:0] Count;
always @(posedge clk) begin //TIMEOUT_COUNT1
    if (!rst_n )
        TimeOutClockPeriods = NUM_OF_BURSTS ; //maximum number of bursts to Start from each group bank
    //else if (En_TimeOutTime == 1'b1)
       // TimeOutClockPeriods <= DataWriteBus_ProcA;
end
always @(posedge clk) begin //increment counter
    if (!rst_n || RunTimer==1'b0)
        Count <= 0;
    else
        Count <= Count +1;
end
always @(*)begin //TIMEOUT_COUNT2
    if (Count == TimeOutClockPeriods)
        TimesUp = 1;
    else
        TimesUp = 0;
end*/


always @(*) begin
    casex ({Start_D,Start_C,Start_B,Start_A})
        4'b0001 : sel = 2'd0 ; 
        4'b0010 : sel = 2'd1 ;
        4'b0100 : sel = 2'd2 ;
        4'b1000 : sel = 2'd3 ;
        default : sel = 2'd0 ; //dont care 
    endcase
end
/************************************************FSM signals*****************************************************/
enum reg [2:0] { IDLE, GROUP_A, GROUP_B, GROUP_C, GROUP_D } CS, NS;
/*****************************************************************************************************************/
 
//update fsm
always @ (posedge clk)begin
    if (!rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end



// Compute Next State and mealy outputs
always @ (*)begin
    Start_A = 0 ;
    Start_B = 0 ;
    Start_C = 0 ;
    Start_D = 0 ;
    NS = CS ;
    case (CS)
        IDLE: begin
            if(flag ==1'b1) begin
                if (ReqA == 1'b1)begin
                    //Start_A = 1'b1;
                    NS=GROUP_A;
                end
                else if (ReqB == 1'b1)begin
                    //Start_B = 1'b1;
                    NS=GROUP_B;
                end
                else if (ReqC == 1'b1)begin
                    //Start_C = 1'b1;
                    NS=GROUP_C;
                end
                else if (ReqD == 1'b1)begin
                    //Start_D = 1'b1;
                    NS=GROUP_D;
                end
            end
        end
        GROUP_A: begin
            Start_A = 1'b1;
            if (ReqA == 1'b1 &&  Done_A == 1'b0 )begin
               // Start_A = 1'b1;
                NS=GROUP_A;
            end 
            else begin
                if(flag ==1'b1) begin
                    if (ReqB == 1'b1)
                        NS=GROUP_B;
                    else if (ReqC == 1'b1)
                        NS=GROUP_C;
                    else if (ReqD == 1'b1)
                        NS=GROUP_D;
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_B: begin
            Start_B = 1'b1;
            if (ReqB == 1'b1 && Done_B == 1'b0 )begin
                //Start_B = 1'b1;
                NS=GROUP_B;
            end
            else begin
                if(flag ==1'b1) begin
                    if (ReqC == 1'b1)
                        NS=GROUP_C;
                    else if (ReqD == 1'b1)
                        NS=GROUP_D;
                    else if (ReqA == 1'b1)
                        NS=GROUP_A;
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_C: begin
            Start_C = 1'b1;
            if (ReqC == 1'b1 && Done_C == 1'b0 )begin
                //Start_C = 1'b1;
                NS=GROUP_C;
            end 
            else begin
                if(flag ==1'b1) begin
                    if (ReqD == 1'b1)
                        NS=GROUP_D;
                    else if (ReqA == 1'b1)
                        NS=GROUP_A;
                    else if (ReqB == 1'b1)
                        NS=GROUP_B;
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_D: begin
            Start_D = 1'b1;
            if (ReqD == 1'b1 && Done_D == 1'b0 )begin
                //Start_D = 1'b1;
                NS=GROUP_D;
            end 
            else begin
                if(flag ==1'b1) begin
                    if (ReqA == 1'b1)
                        NS=GROUP_B;
                    else if (ReqB == 1'b1)
                        NS=GROUP_C;
                    else if (ReqC == 1'b1)
                        NS=GROUP_D;
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
    endcase
end


endmodule
/*module Groups_Fsm
(   
    input  clk, rst_n,
    input  flag ,    // if flag is 1 from burst hanndler, then we can drain  more bursts
    input  [15:0] valid,
    input  [7:0] sel ,
    output reg [3:0] ready_D, ready_C, ready_B, ready_A,
    output reg wr_en , 
    output reg [1:0] group_sel
);


wire ReqD, ReqC, ReqB, ReqA ;
wire Done_D, Done_C, Done_B, Done_A ;
wire [3:0] v_A , v_B , v_C, v_D;
wire [3:0] s_A , s_B , s_C, s_D;

assign {sel_D , sel_C, sel_B, sel_A} = sel;
assign {v_D , v_C, v_B, v_A} = valid;


reg [NUM_OF_BURSTS-1:0] TimeOutClockPeriods;
reg RunTimer, TimesUp;
reg [$clog2(TIME_OUT_PERIOD)-1:0] Count;


always @(posedge clk) begin //TIMEOUT_COUNT1
    if (!rst_n )
        TimeOutClockPeriods = NUM_OF_BURSTS ; //maximum number of bursts to Start from each group bank
    //else if (En_TimeOutTime == 1'b1)
       // TimeOutClockPeriods <= DataWriteBus_ProcA;
end

always @(posedge clk) begin //increment counter
    if (!rst_n || RunTimer==1'b0)
        Count <= 0;
    else
        Count <= Count +1;
end


always @(*)begin //TIMEOUT_COUNT2
    if (Count == TimeOutClockPeriods)
        TimesUp = 1;
    else
        TimesUp = 0;
end


/************************************************FSM signals*****************************************************/
//enum reg [2:0] { IDLE, GROUP_A, GROUP_B, GROUP_C, GROUP_D } CS, NS;
/*****************************************************************************************************************
 
//update fsm
always @ (posedge clk)begin
    if (!rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end



// Compute Next State and mealy outputs
always @ (*)begin
    wr_en = 1'b0;
    ready_A = 4'd0;
    ready_B = 4'd0;
    ready_C = 4'd0;
    ready_D = 4'd0;
    group_sel = 2'd0;
    NS = CS ;
    case (CS)
        IDLE: begin
            if(flag ==1'b1) begin
                if (|v_A == 1'b1)begin
                    NS=GROUP_A;
                    wr_en = v_A[sel_A];
            ready_A[sel_A] = 1'b1;
            group_sel = 2'd0;
                end
                else if (|v_B == 1'b1)begin
                    NS=GROUP_B;
                    wr_en = v_B[sel_B] ;
            ready_B[sel_B] = 1'b1;
            group_sel = 2'd0;
                end
                else if (|v_C == 1'b1)begin
                    NS=GROUP_C;
                    wr_en = v_C[sel_C] ;
            ready_C[sel_C] = 1'b1;
            group_sel = 2'd1;
                end
                else if (|v_D == 1'b1)begin
                    NS=GROUP_D;
                    wr_en = v_D[sel_D];
            ready_D[sel_D] = 1'b1;
            group_sel = 2'd3;
                end
            end
        end
        GROUP_A: begin
            wr_en = v_A[sel_A];
            ready_A[sel_A] = 1'b1;
            group_sel = 2'd0;
            if (|v_A == 1'b1 )begin         
                NS=GROUP_A;                
            end 
            else begin
                if(flag ==1'b1) begin
                    if (|v_B == 1'b1)begin
                        NS=GROUP_B;
                        wr_en = v_B[sel_B] ;
            ready_B[sel_B] = 1'b1;
            group_sel = 2'd0;
                    end                        
                    else if (|v_C == 1'b1) begin
                        NS=GROUP_C;
                        wr_en = v_C[sel_C] ;
            ready_C[sel_C] = 1'b1;
            group_sel = 2'd1;
                    end
                    else if (|v_D == 1'b1)begin
                        NS=GROUP_D;
                        wr_en = v_D[sel_D];
            ready_D[sel_D] = 1'b1;
            group_sel = 2'd3;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_B: begin
            wr_en = v_B[sel_B] ;
            ready_B[sel_B] = 1'b1;
            group_sel = 2'd0;
            if (|v_B == 1'b1 )begin
                NS=GROUP_B;
            end
            else begin
                if(flag ==1'b1) begin
                    if (|v_C == 1'b1)begin
                        NS=GROUP_C;
                        wr_en = v_C[sel_C] ;
            ready_C[sel_C] = 1'b1;
            group_sel = 2'd1;
                    end
                    else if (|v_D == 1'b1)begin
                        NS=GROUP_D;
                        wr_en = v_D[sel_D];
            ready_D[sel_D] = 1'b1;
            group_sel = 2'd3;
                    end
                    else if (|v_A == 1'b1)begin
                        NS=GROUP_A;
                        wr_en = v_A[sel_A];
            ready_A[sel_A] = 1'b1;
            group_sel = 2'd0;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_C: begin
            wr_en = v_C[sel_C] ;
            ready_C[sel_C] = 1'b1;
            group_sel = 2'd1;
            if (|v_C == 1'b1 )begin
                NS=GROUP_C;               
            end 
            else begin
                if(flag ==1'b1) begin
                    if (|v_D == 1'b1)begin
                        NS=GROUP_D;
                        wr_en = v_D[sel_D];
            ready_D[sel_D] = 1'b1;
            group_sel = 2'd3;
                    end
                    else if (|v_A == 1'b1)begin
                        NS=GROUP_A;
                        wr_en = v_A[sel_A];
            ready_A[sel_A] = 1'b1;
            group_sel = 2'd0;
                    end
                    else if (|v_B == 1'b1)begin
                        NS=GROUP_B;
                        wr_en = v_B[sel_B] ;
            ready_B[sel_B] = 1'b1;
            group_sel = 2'd0;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_D: begin           
            wr_en = v_D[sel_D];
            ready_D[sel_D] = 1'b1;
            group_sel = 2'd3;
            if (|v_D == 1'b1 )begin
                NS=GROUP_D;            
            end 
            else begin
                if(flag ==1'b1) begin
                    if (|v_A == 1'b1)begin
                        NS=GROUP_A;
                        wr_en = v_A[sel_A];
            ready_A[sel_A] = 1'b1;
            group_sel = 2'd0;
                    end
                    else if (|v_B == 1'b1)begin
                        NS=GROUP_B;
                         wr_en = v_B[sel_B] ;
            ready_B[sel_B] = 1'b1;
            group_sel = 2'd0;
                    end
                    else if (|v_C == 1'b1)begin
                        NS=GROUP_C;
                        wr_en = v_C[sel_C] ;
            ready_C[sel_C] = 1'b1;
            group_sel = 2'd1;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
    endcase
end


/*always @ (*)begin
    wr_en = 1'b0;
    ready_A = 4'd0;
    ready_B = 4'd0;
    ready_C = 4'd0;
    ready_D = 4'd0;
    group_sel = 2'd0;
    NS = CS ;
    case (CS)
        IDLE: begin
            if(flag ==1'b1) begin
                if (|v_A == 1'b1)begin
                    NS=GROUP_A;
                end
                else if (|v_B == 1'b1)begin
                    NS=GROUP_B;
                end
                else if (|v_C == 1'b1)begin
                    NS=GROUP_C;
                end
                else if (|v_D == 1'b1)begin
                    NS=GROUP_D;
                end
            end
        end
        GROUP_A: begin
            wr_en = v_A[sel_A];
            ready_A[sel_A] = 1'b1;
            group_sel = 2'd0;
            if (|v_A == 1'b1 )begin         
                NS=GROUP_A;                
            end 
            else begin
                if(flag ==1'b1) begin
                    if (|v_B == 1'b1)begin
                        NS=GROUP_B;
                    end                        
                    else if (|v_C == 1'b1) begin
                        NS=GROUP_C;
                    end
                    else if (|v_D == 1'b1)begin
                        NS=GROUP_D;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_B: begin
            wr_en = v_B[sel_B] ;
            ready_B[sel_B] = 1'b1;
            group_sel = 2'd0;
            if (|v_B == 1'b1 )begin
                NS=GROUP_B;
            end
            else begin
                if(flag ==1'b1) begin
                    if (|v_C == 1'b1)begin
                        NS=GROUP_C;
                    end
                    else if (|v_D == 1'b1)begin
                        NS=GROUP_D;
                    end
                    else if (|v_A == 1'b1)begin
                        NS=GROUP_A;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_C: begin
            wr_en = v_C[sel_C] ;
            ready_C[sel_C] = 1'b1;
            group_sel = 2'd1;
            if (|v_C == 1'b1 )begin
                NS=GROUP_C;               
            end 
            else begin
                if(flag ==1'b1) begin
                    if (|v_D == 1'b1)begin
                        NS=GROUP_D;
                    end
                    else if (|v_A == 1'b1)begin
                        NS=GROUP_A;
                    end
                    else if (|v_B == 1'b1)begin
                        NS=GROUP_B;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
        GROUP_D: begin           
            wr_en = v_D[sel_D];
            ready_D[sel_D] = 1'b1;
            group_sel = 2'd3;
            if (|v_D == 1'b1 )begin
                NS=GROUP_D;            
            end 
            else begin
                if(flag ==1'b1) begin
                    if (|v_A == 1'b1)begin
                        NS=GROUP_A;
                    end
                    else if (|v_B == 1'b1)begin
                        NS=GROUP_C;
                    end
                    else if (|v_C == 1'b1)begin
                        NS=GROUP_D;
                    end
                end
                else if(flag  == 1'b0 )
                    NS=IDLE;
            end
        end
    endcase
end


endmodule*/