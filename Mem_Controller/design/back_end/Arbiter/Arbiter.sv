module Arbiter
#(parameter REQ_SIZE = 32 , parameter NUM_OF_BURSTS = 1)
(   
    input  clk, rst_n, ReqA, ReqB, ReqC, ReqD, //En_TimeOutTime,
    //input  [REQ_SIZE-1:0] DataBus_A, DataBus_B, DatBus_C, DatBus_D
    //output [REQ_SIZE-1:0] DataBus_out ,
    output reg Drain_A, Drain_B, Drain_C, Drain_D //TimeStart;  
);

reg [NUM_OF_BURSTS-1:0] TimeOutClockPeriods;
reg RunTimer, TimesUp;
reg [$clog2(TIME_OUT_PERIOD)-1:0] Count;


always @(posedge clk) begin //TIMEOUT_COUNT1
    if (!rst_n )
        TimeOutClockPeriods = NUM_OF_BURSTS ; //maximum number of bursts to drain from each group bank
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
// groups arbiter (Master FSM)
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    START_A     = 3'b001,
    START_B     = 3'b010,
    START_C     = 3'b011,
    START_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;



// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    START_A     = 3'b001,
    START_B     = 3'b010,
    START_C     = 3'b011,
    START_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;

// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    START_A     = 3'b001,
    START_B     = 3'b010,
    START_C     = 3'b011,
    START_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;

// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    START_A     = 3'b001,
    START_B     = 3'b010,
    START_C     = 3'b011,
    START_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;

// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    START_A     = 3'b001,
    START_B     = 3'b010,
    START_C     = 3'b011,
    START_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;

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
    Drain_A = 0 ;
    Drain_B = 0 ;
    Drain_C = 0 ;
    Drain_D = 0 ;
    //TimeStart = 0;
    RunTimer  = 0;

    case (CS)
        IDLE: begin
            if (ReqA == 1'b1)begin
                Drain_A = 1;
                NS=GRANT_A;
            end
            else if (ReqB == 1'b1)begin
                Drain_B = 1;
                NS=GRANT_B;
            end
            else if (ReqC == 1'b1)begin
                Drain_C = 1;
                NS=GRANT_C;
            end
            else if (ReqD == 1'b1)begin
                Drain_D = 1;
                NS=GRANT_D;
            end
        end
        GRANT_A: begin
            if (ReqA == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                Drain_A = 1;
                NS=GRANT_A;
            end 
            else begin
                if (ReqB == 1'b1)
                    NS=GRANT_B;
                else if (ReqC == 1'b1)
                    NS=GRANT_C;
                else if (ReqD == 1'b1)
                    NS=GRANT_D;
                else 
                    NS=IDLE;
            end
        end
        GRANT_B: begin
            if (ReqB == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                Drain_B = 1;
                NS=GRANT_B;
            end
            else begin
                if (ReqC == 1'b1)
                    NS=GRANT_C;
                else if (ReqD == 1'b1)
                    NS=GRANT_D;
                else if (ReqA == 1'b1)
                    NS=GRANT_A;
                else 
                    NS=IDLE;
            end
        end
        GRANT_C: begin
            if (ReqC == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                Drain_C = 1;
                NS=GRANT_C;
            end 
            else begin
                if (ReqD == 1'b1)
                    NS=GRANT_D;
                else if (ReqA == 1'b1)
                    NS=GRANT_A;
                else if (ReqB == 1'b1)
                    NS=GRANT_B;
                else 
                    NS=IDLE;
            end
        end
        GRANT_D: begin
            if (ReqD == 1'b1 && TimesUp == 0 )begin
                RunTimer = 1'b1;
                Drain_D = 1;
                NS=GRANT_D;
            end 
            else begin
                if (ReqA == 1'b1)
                    NS=GRANT_B;
                else if (ReqB == 1'b1)
                    NS=GRANT_C;
                else if (ReqC == 1'b1)
                    NS=GRANT_D;
                else 
                    NS=IDLE;
            end
        end
    endcase
end

endmodule

/*always @(posedge Reset or posedge Clock)
begin: 
if (Reset)
begin
EnA

0; EnA2

begin

Enc
case (NextState)
GRANT_A: begin EnAl = 1;EnA2 = 0; end

Gront_B: begin EnB1 = 1; €nB2
GRANT_C: begin EnC] = 1:EnC2 = 0; end
default:
begin
EnAl
   
endcase
end
end*/


/*

assign AddBus_RAM = EnAl ? AddBus_ProcA : 12’;
assign AddBus_RAM = EnBl ? AddBus_ProcB : 12'b Z;
assign AddBus_RAM = EnCl ? AddBus_ProcC : 12'bZ;


assign DataWriteBus_RAM = EnA2 ? DataWriteBus ProcA,
rez:
‘assign DataWriteBus_RAM = EnB2 ? DataWriteBus_Proc8
:ebZ:
‘assign DataWriteBus_RAM = EnC2 ? DataWriteBus_ProcC
rebZ;

assign R_Wb_RAM = EnA2? R_Wb_ProcA : I'bZ;
assign R_Wb_RAM = EnB2 ?R_Wb Proc : I'bZ:
assign R_Wb_RAM = EnC2 ? R_Wb_ProcC : 1'b Z;*/








