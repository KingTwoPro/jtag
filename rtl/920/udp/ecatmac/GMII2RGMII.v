/* This module transfer data between GMII and RGMII. */

module GMII2RGMII #(
	parameter DEMOCLOCK = 1, 
	parameter SIM = 0,	//set 1 for simulation
	parameter CLKP = 8 	//system clock period
)
(
	//system signals
	input clk125_i, reset_i,
	//GMII
	input           Gtx_clk_i                 ,//used only in GMII mode
	output          Rx_clk_o                  ,
	input           Tx_er_i                   ,
	input           Tx_en_i                   ,
	input   [7:0]   Txd_i                     ,
	output          Rx_er_o                   ,
	output          Rx_dv_o                   ,
	output  [7:0]   Rxd_o                     ,
	//RGMII
	input 		rgmii_rxclk_i		,
	input [3:0]	rgmii_rxd_i		,
	input 		rgmii_rxdv_i		,
	output[3:0]	rgmii_txd_o		,
	output 		rgmii_txdv_o		,
	output 		rgmii_txclk_o
	, input clk125_90
	, output Clk150M
	, output Clk37M
	, output Clk125M
	, input Clk50M_i
	, input RgmiiPllReset_i
);
//localparam ODELAYVALUE = (SIM == 0)? 20 : 26;
localparam ODELAYVALUE = (SIM == 1)? 20 : 52;

wire rgmii_clk_delay;
wire RxEr, RxDv;
wire [7:0] Rxd;
reg RxErR, RxDvR;
reg [7:0] RxdR;
(* mark_debug = "true" *) wire Lock;
wire clk150, clk37;
//TX from GMII to GRMII
  wire clkfb;
  wire clk0;
  wire clk90;
  wire clk270;
  wire clk180;
genvar i;
generate
	for(i=0; i<4; i=i+1) begin : loop_txdata
		ODDR #(
      			.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      			.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      			.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
   		) Txdata_ODDR2 (
      			.Q(rgmii_txd_o[i]),   // 1-bit DDR output data
      			.C(Gtx_clk_i),   // 1-bit clock input
      			.CE(1'b1), // 1-bit clock enable input
      			.D1(Txd_i[i]), // 1-bit data input (associated with C0)
      			.D2(Txd_i[i+4]), // 1-bit data input (associated with C1)
      			.R(1'b0),   // 1-bit reset input
      			.S(1'b0)    // 1-bit set input
   		);
	end
endgenerate
ODDR #(
      	.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      	.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
      ) TxDv_ODDR2 (
      	.Q(rgmii_txclk_o),   // 1-bit DDR output data
      	//.C(Gtx_clk_i),   // 1-bit clock input
      	.C(clk270),   // 1-bit clock input
      	.CE(1'b1), // 1-bit clock enable input
      	.D1(1'b1), // 1-bit data input (associated with C0)
      	//.D1(Tx_er_i), // 1-bit data input (associated with C1)
      	.D2(1'b0), // 1-bit data input (associated with C1)
      	.R(1'b0),   // 1-bit reset input
      	.S(1'b0)    // 1-bit set input
      );
//assign rgmii_txclk_o = clk125_90;
ODDR #(
      	.DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      	.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
      ) TxClk_ODDR2 (
      	.Q(rgmii_txdv_o),   // 1-bit DDR output data
      	.C(Gtx_clk_i),   // 1-bit clock input
      	.CE(1'b1), // 1-bit clock enable input
      	.D1(Tx_en_i), // 1-bit data input (associated with C0)
      	//.D1(Tx_er_i), // 1-bit data input (associated with C1)
      	.D2(Tx_en_i), // 1-bit data input (associated with C1)
      	.R(1'b0),   // 1-bit reset input
      	.S(1'b0)    // 1-bit set input
      );
//RX from GMII to RGMII
//Use DCM to generate 90C clock



      PLLE2_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
      .CLKFBOUT_MULT(8.0),        // Multiply value for all CLKOUT, (2-64)
      .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
      .CLKIN1_PERIOD(8.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT0_DIVIDE(6),
      .CLKOUT1_DIVIDE(8),
      .CLKOUT2_DIVIDE(8),
      .CLKOUT3_DIVIDE(27),
      .CLKOUT4_DIVIDE(8),
      .CLKOUT5_DIVIDE(1),
      // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(90.0),
      .CLKOUT2_PHASE(270.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(180.0),
      .CLKOUT5_PHASE(0.0),
      .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
      .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
      .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   rxpll (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(),   // 1-bit output: CLKOUT0
      .CLKOUT1(CLK_OUT1),   // 1-bit output: CLKOUT1
      .CLKOUT2(),   // 1-bit output: CLKOUT2
      .CLKOUT3(),   // 1-bit output: CLKOUT3
      .CLKOUT4(),   // 1-bit output: CLKOUT4
      .CLKOUT5(),   // 1-bit output: CLKOUT5
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clkfb), // 1-bit output: Feedback clock
      .LOCKED(Lock),     // 1-bit output: LOCK
      .CLKIN1(rgmii_rxclk_i),     // 1-bit input: Input clock
      // Control Ports: 1-bit (each) input: PLL control ports
      .PWRDWN(1'b0),     // 1-bit input: Power-down
      .RST(RgmiiPllReset_i),           // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clk0)    // 1-bit input: Feedback clock
   );
/*
PLLE2_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
      .CLKFBOUT_MULT(((DEMOCLOCK==1)? 8:40)),        // Multiply value for all CLKOUT, (2-64)
      .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
      .CLKIN1_PERIOD(((DEMOCLOCK==1)?(8.0) : (40))),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT0_DIVIDE(6),
      .CLKOUT1_DIVIDE(8),
      .CLKOUT2_DIVIDE(8),
      .CLKOUT3_DIVIDE(27),
      .CLKOUT4_DIVIDE(8),
      .CLKOUT5_DIVIDE(1),
      // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(90.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
      .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
      .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   txpll (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk150),   // 1-bit output: CLKOUT0
      .CLKOUT1(),   // 1-bit output: CLKOUT1
      .CLKOUT2(CLK_OUT2),   // 1-bit output: CLKOUT2
      .CLKOUT3(clk37),   // 1-bit output: CLKOUT3
      .CLKOUT4(CLK_OUT4),   // 1-bit output: CLKOUT4
      .CLKOUT5(),   // 1-bit output: CLKOUT5
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clkfb1), // 1-bit output: Feedback clock
      .LOCKED(Lock1),     // 1-bit output: LOCK
      .CLKIN1(Clk50M_i),     // 1-bit input: Input clock
      // Control Ports: 1-bit (each) input: PLL control ports
      .PWRDWN(1'b0),     // 1-bit input: Power-down
      .RST(1'b0),           // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clkfb1)    // 1-bit input: Feedback clock
   );
   */
  MMCME2_BASE #(
      .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F(40.0),     // Multiply value for all CLKOUT (2.000-64.000).
      .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD(40.0),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT1_DIVIDE(8),
      .CLKOUT2_DIVIDE(8),
      .CLKOUT3_DIVIDE(27),
      .CLKOUT4_DIVIDE(8),
      .CLKOUT5_DIVIDE(1),
      .CLKOUT6_DIVIDE(1),
      .CLKOUT0_DIVIDE_F(6.0),    // Divide amount for CLKOUT0 (1.000-128.000).
      // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT6_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(90.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .CLKOUT6_PHASE(0.0),
      .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .DIVCLK_DIVIDE(1),         // Master division value (1-106)
      .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   txpll (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk150),     // 1-bit output: CLKOUT0
      .CLKOUT0B(),   // 1-bit output: Inverted CLKOUT0
      .CLKOUT1(),     // 1-bit output: CLKOUT1
      .CLKOUT1B(),   // 1-bit output: Inverted CLKOUT1
      .CLKOUT2(CLK_OUT2),     // 1-bit output: CLKOUT2
      .CLKOUT2B(),   // 1-bit output: Inverted CLKOUT2
      .CLKOUT3(clk37),     // 1-bit output: CLKOUT3
      .CLKOUT3B(),   // 1-bit output: Inverted CLKOUT3
      .CLKOUT4(CLK_OUT4),     // 1-bit output: CLKOUT4
      .CLKOUT5(),     // 1-bit output: CLKOUT5
      .CLKOUT6(),     // 1-bit output: CLKOUT6
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clkfb1),   // 1-bit output: Feedback clock
      .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
      // Status Ports: 1-bit (each) output: MMCM status ports
      .LOCKED(Lock1),       // 1-bit output: LOCK
      // Clock Inputs: 1-bit (each) input: Clock input
      .CLKIN1(Clk50M_i),       // 1-bit input: Clock
      // Control Ports: 1-bit (each) input: MMCM control ports
      .PWRDWN(1'b0),       // 1-bit input: Power-down
      .RST(1'b0),             // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clkfb1)      // 1-bit input: Feedback clock
   );

  // Output buffering
  //-----------------------------------
  BUFG clkf_buf
   (.O (clk0),
    .I (clkfb));

  BUFG clkout1_buf
   (.O   (clk90),
    .I   (CLK_OUT1));	//rxpll


  BUFG clkout2_buf
   (.O   (clk270),
    .I   (CLK_OUT2));	//txpll clk50_90C, txclk


  BUFG clk150buf
   (.O   (Clk150M),
    .I   (clk150));
	 
  BUFG clk37buf
   (.O   (Clk37M),
    .I   (clk37));

  BUFG clk125m180p
   (.O   (clk180),
    .I   (CLK_OUT4));	//txpll clk50_0C, tx data

assign Clk125M = clk180;

generate
	for(i=0; i<4; i=i+1) begin : gen_rx_data
		IDDR #(
      		      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
		      .INIT_Q1(1'b0), // Sets initial state of the Q0 output to 1'b0 or 1'b1
		      .INIT_Q2(1'b0), // Sets initial state of the Q1 output to 1'b0 or 1'b1
		      .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
		) rxIddr (
		      .Q1(Rxd[i]), // 1-bit output captured with C0 clock
		      .Q2(Rxd[i+4]), // 1-bit output captured with C1 clock
		      .C(clk90), // 1-bit clock input
		      .CE(1'b1), // 1-bit clock enable input
		      .D(rgmii_rxd_i[i]),   // 1-bit DDR data input
		      .R(1'b0),   // 1-bit reset input
		      .S(1'b0)    // 1-bit set input
		);
     
	end
endgenerate

IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
      .INIT_Q1(1'b0), // Sets initial state of the Q0 output to 1'b0 or 1'b1
      .INIT_Q2(1'b0), // Sets initial state of the Q1 output to 1'b0 or 1'b1
      .SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
) rxdv (
      .Q1(RxDv), // 1-bit output captured with C0 clock
      .Q2(RxEr), // 1-bit output captured with C1 clock
      .C(clk90), // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(rgmii_rxdv_i),   // 1-bit DDR data input
      .R(1'b0),   // 1-bit reset input
      .S(1'b0)    // 1-bit set input
);
reg Lockr;
always @(posedge clk90) begin
	Lockr<=~Lock;
	if(Lockr) begin
		RxdR<='h0; RxDvR<='h0; RxErR<='h0;
	end
	else begin
		RxdR<=Rxd; RxDvR<=RxDv; RxErR<=RxEr;
	end
end
//assign Rxd_o = {Rxd[4+:4], RxdR[0+:4]};
assign Rxd_o = RxdR;
assign Rx_dv_o = RxDvR;
assign Rx_er_o = 1'b0; //RxEr;
assign Rx_clk_o = clk90;
/* Sync circuit for RX to GT_clk (125M) clock domain */
/* this sync circuit is not necessary due to FIFO exist in RX_FF. 
reg rd_en, wr_en; 
reg [2:0] fiforst;
wire empty, full, prog_full;
wire [10:0] dout;
reg [7:0] RxdfifoR;
reg RxdfifoEr, RxdfifoDv;
reg [9:0] RxdfifoRd;
always @(posedge clk90) begin
	RxdfifoR<={Rxd[4+:4], RxdR[0+:4]}; RxdfifoEr<=RxErR; RxdfifoDv<=RxDvR;
end


dram_16x8 RxSyncFifo(
  .rst          (fiforst[2]),
  .wr_clk	(clk90)	,
  .rd_clk	(Gtx_clk_i)	,
  .din		({RxdfifoEr, RxdfifoDv, RxdfifoR})	,
  .wr_en	(wr_en)	,
  .rd_en	(rd_en)	,
  .dout		(dout	)	,
  .full		(full	)	,
  .empty	(empty	)	,
  .prog_full	(prog_full)	
);
always @(posedge Gtx_clk_i) begin
	if(reset_i || fiforst[2]) begin
		rd_en<=1'b0; 
	end
	else begin
		if(prog_full)
			rd_en<=1'b1;
	end
end
always @(posedge clk90) begin
	if(reset_i || fiforst[2]) begin
		wr_en<=1'b0;
	end
	else begin
		if(RxDvR && !RxdfifoDv)
			wr_en<=1'b1;
	end
end
always @(posedge Gtx_clk_i) begin
	if(reset_i) begin
		fiforst<=3'b111;
	end
	else begin
		fiforst<={fiforst[1:0], 1'b0};
		if(!dout[8] && RxdfifoRd[8])
			fiforst<=3'b111;
	end
end

always @(posedge Gtx_clk_i) begin
	RxdfifoRd<=dout;
end

assign Rxd_o = RxdfifoRd[7:0];//dout[7:0];
assign Rx_dv_o = RxdfifoRd[8];//dout[8]; 
assign Rx_er_o = 1'b0; 
*/
endmodule
