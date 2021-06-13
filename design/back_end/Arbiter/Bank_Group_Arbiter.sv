module Bank_Group_Arbiter
#(parameter MAX_bursts = 4 )
(   
    input clk, rst_n, start,
    input [$clog2(MAX_BURSTS):0] numOfBursts,   //maximium bursts that can be drained from each bank group
    input ReqA, ReqB, ReqC, ReqD, 
    //input  [REQ_SIZE-1:0] DataBus_A, DataBus_B, DatBus_C, DatBus_D
    //output [REQ_SIZE-1:0] DataBus_out ,
    output reg Grant_A, Grant_B, Grant_C, Grant_D //TimeStart;  
);



reg [NUM_OF_BURSTS-1:0] numOfBursts;


localparam [2:0]
    IDLE   = 3'b000,
    BANK_A = 3'b001,
    BANK_B = 3'b010,
    BANK_C = 3'b011,
    BANK_D = 3'b100;

reg [1:0] CS, NS ;
reg en_A, en_B, en_C, en_D ; 


always @(posedge clk) begin //TIMEOUT_COUNT1
    TimeOutClockPeriods <= NUM_OF_BURSTS *16; //maximum time for each burst
    else if (En_TimeOutTime == 1'b1)
        TimeOutClockPeriods <= DataWriteBus_ProcA;
end

/*always @(posedge clk) begin 
    if (!rst_n )
        Count <= 0;
    else
        Count <= Count +1;
end*/


/*always @(*)begin //TIMEOUT_COUNT2
    if (Count == TimeOutClockPeriods)
        TimesUp = 1;
    else
        TimesUp = 0;
end*/

//update fsm
always @ (posedge clk)begin
    if (!rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end



// Compute Next State and mealy outputs
always @ (*)begin
    en_A = 0 ;
    en_B = 0 ;
    en_C = 0 ; 
    en_D = 0 ;

    //TimeStart = 0;
    //RunTimer  = 0;

    case (CS)
        IDLE: begin
            if (ReqA == 1'b1)begin
                en_A = 1;
                NS=BANK_A;
            end
            else if (ReqB == 1'b1)begin
                en_B = 1;
                NS=BANK_B;
            end
            else if (ReqC == 1'b1)begin
                en_C = 1;
                NS=BANK_C;
            end
            else if (ReqD == 1'b1)begin
                en_D = 1;
                NS=BANK_D;
            end
        end
        BANK_A: begin
            if (ReqA == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                en_A = 1;
                NS=BANK_A;
            end 
            else begin
                if (ReqB == 1'b1)
                    NS=BANK_B;
                else if (ReqC == 1'b1)
                    NS=BANK_C;
                else if (ReqD == 1'b1)
                    NS=BANK_D;
                else 
                    NS=IDLE;
            end
        end
        BANK_B: begin
            if (ReqB == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                en_B = 1;
                NS=BANK_B;
            end
            else begin
                if (ReqC == 1'b1)
                    NS=BANK_C;
                else if (ReqD == 1'b1)
                    NS=BANK_D;
                else if (ReqA == 1'b1)
                    NS=BANK_A;
                else 
                    NS=IDLE;
            end
        end
        BANK_C: begin
            if (ReqC == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                en_C = 1;
                NS=BANK_C;
            end 
            else begin
                if (ReqD == 1'b1)
                    NS=BANK_D;
                else if (ReqA == 1'b1)
                    NS=BANK_A;
                else if (ReqB == 1'b1)
                    NS=BANK_B;
                else 
                    NS=IDLE;
            end
        end
        BANK_D: begin
            if (ReqD == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                en_D = 1;
                NS=BANK_D;
            end 
            else begin
                if (ReqA == 1'b1)
                    NS=BANK_B;
                else if (ReqB == 1'b1)
                    NS=BANK_C;
                else if (ReqC == 1'b1)
                    NS=BANK_D;
                else 
                    NS=IDLE;
            end
        end
    endcase
end


endmodule