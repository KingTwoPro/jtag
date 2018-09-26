/* This module transfer data between GMII and RGMII. */

module GMII2RGMII #(
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
);
//localparam ODELAYVALUE = (SIM == 0)? 20 : 26;
localparam ODELAYVALUE = (SIM == 1)? 20 : 52;

wire rgmii_clk_delay;
wire RxEr, RxDv;
wire [7:0] Rxd;
reg RxErR, RxDvR;
reg [7:0] RxdR;
//TX from GMII to GRMII
/*	IODELAY2 #(
	      .COUNTER_WRAPAROUND("STAY_AT_LIMIT"), // "STAY_AT_LIMIT" or "WRAPAROUND" 
	      .DATA_RATE("SDR"),                 // "SDR" or "DDR" 
	      .DELAY_SRC("ODATAIN"),                  // "IO", "ODATAIN" or "IDATAIN" 
	      .IDELAY2_VALUE(0),                 // Delay value when IDELAY_MODE="PCI" (0-255)
	      .IDELAY_MODE("NORMAL"),            // "NORMAL" or "PCI" 
	      .IDELAY_TYPE("FIXED"),           // "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
	                                         // or "DIFF_PHASE_DETECTOR" 
	      .IDELAY_VALUE(0),                  // Amount of taps for fixed input delay (0-255)
	      .ODELAY_VALUE(ODELAYVALUE),                  // Amount of taps fixed output delay (0-255)
	      .SERDES_MODE("NONE"),              // "NONE", "MASTER" or "SLAVE" 
	      .SIM_TAPDELAY_VALUE(75)            // Per tap delay used for simulation in ps
	   )
	   TXclk_IODELAY2 (
	      .BUSY(),         // 1-bit output: Busy output after CAL
	      .DATAOUT(),   // 1-bit output: Delayed data output to ISERDES/input register
	      .DATAOUT2(), // 1-bit output: Delayed data output to general FPGA fabric
	      .DOUT(rgmii_txclk_o),         // 1-bit output: Delayed data output
	      .TOUT(),         // 1-bit output: Delayed 3-state output
	      .CAL(1'b0),           // 1-bit input: Initiate calibration input
	      .CE(1'b0),             // 1-bit input: Enable INC input
	      .CLK(1'b0),           // 1-bit input: Clock input
	      .IDATAIN(1'b0),   // 1-bit input: Data input (connect to top-level port or I/O buffer)
	      .INC(1'b0),           // 1-bit input: Increment / decrement input
	      .IOCLK0(1'b0),     // 1-bit input: Input from the I/O clock network
	      .IOCLK1(1'b0),     // 1-bit input: Input from the I/O clock network
	      .ODATAIN(Gtx_clk_i),   // 1-bit input: Output data input from output register or OSERDES2.
	      .RST(1'b0),           // 1-bit input: Reset to zero or 1/2 of total delay period
	      .T(1'b0)                // 1-bit input: 3-state input signal
	   );	
 */
  wire clkfb;
  wire clk0;
  wire clk90;
  wire clk270;
genvar i;
generate
	for(i=0; i<4; i=i+1) begin : loop_txdata
		ODDR2 #(
      			.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
      			.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      			.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
   		) Txdata_ODDR2 (
      			.Q(rgmii_txd_o[i]),   // 1-bit DDR output data
      			.C0(Gtx_clk_i),   // 1-bit clock input
      			.C1(~Gtx_clk_i),   // 1-bit clock input
      			.CE(1'b1), // 1-bit clock enable input
      			.D0(Txd_i[i]), // 1-bit data input (associated with C0)
      			.D1(Txd_i[i+4]), // 1-bit data input (associated with C1)
      			.R(1'b0),   // 1-bit reset input
      			.S(1'b0)    // 1-bit set input
   		);
	end
endgenerate
ODDR2 #(
      	.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
      	.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      	.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
      ) TxDv_ODDR2 (
      	.Q(rgmii_txclk_o),   // 1-bit DDR output data
      	.C0(Gtx_clk_i),   // 1-bit clock input
      	.C1(~Gtx_clk_i),   // 1-bit clock input
      	.CE(1'b1), // 1-bit clock enable input
      	.D0(1'b1), // 1-bit data input (associated with C0)
      	//.D1(Tx_er_i), // 1-bit data input (associated with C1)
      	.D1(1'b0), // 1-bit data input (associated with C1)
      	.R(1'b0),   // 1-bit reset input
      	.S(1'b0)    // 1-bit set input
      );
//assign rgmii_txclk_o = clk125_90;
ODDR2 #(
      	.DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
      	.INIT(1'b0),    // Sets initial state of the Q output to 1'b0 or 1'b1
      	.SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
      ) TxClk_ODDR2 (
      	.Q(rgmii_txdv_o),   // 1-bit DDR output data
      	.C0(Gtx_clk_i),   // 1-bit clock input
      	.C1(~Gtx_clk_i),   // 1-bit clock input
      	.CE(1'b1), // 1-bit clock enable input
      	.D0(Tx_en_i), // 1-bit data input (associated with C0)
      	//.D1(Tx_er_i), // 1-bit data input (associated with C1)
      	.D1(Tx_en_i), // 1-bit data input (associated with C1)
      	.R(1'b0),   // 1-bit reset input
      	.S(1'b0)    // 1-bit set input
      );
//RX from GMII to RGMII
//Use DCM to generate 90C clock


  DCM_SP
  #(.CLKDV_DIVIDE          (2.000),
    .CLKFX_DIVIDE          (1),
    .CLKFX_MULTIPLY        (4),
    .CLKIN_DIVIDE_BY_2     ("FALSE"),
    .CLKIN_PERIOD          (8.0),
    .CLKOUT_PHASE_SHIFT    ("NONE"),
    .CLK_FEEDBACK          ("1X"),
    .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
    .PHASE_SHIFT           (0),
    .STARTUP_WAIT          ("FALSE"))
  rxclkDcm
    // Input clock
   (.CLKIN                 (rgmii_rxclk_i),
    .CLKFB                 (clkfb),
    // Output clocks
    .CLK0                  (clk0),
    .CLK90                 (CLK_OUT1),
    .CLK180                (CLK_OUT3),
    .CLK270                (CLK_OUT2),
    .CLK2X                 (),
    .CLK2X180              (),
    .CLKFX                 (),
    .CLKFX180              (),
    .CLKDV                 (),
    // Ports for dynamic phase shift
    .PSCLK                 (1'b0),
    .PSEN                  (1'b0),
    .PSINCDEC              (1'b0),
    .PSDONE                (),
    // Other control and status signals
    .LOCKED                (),
    .STATUS                (),
    .RST                   (1'b0),
    // Unused pin- tie low
    .DSSEN                 (1'b0));


  // Output buffering
  //-----------------------------------
  BUFG clkf_buf
   (.O (clkfb),
    .I (clk0));

  BUFG clkout1_buf
   (.O   (clk90),
    .I   (CLK_OUT1));


  BUFG clkout2_buf
   (.O   (clk270),
    .I   (CLK_OUT2));
	 
generate
	for(i=0; i<4; i=i+1) begin : gen_rx_data
		IDDR2 #(
		      .DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
		      .INIT_Q0(1'b0), // Sets initial state of the Q0 output to 1'b0 or 1'b1
		      .INIT_Q1(1'b0), // Sets initial state of the Q1 output to 1'b0 or 1'b1
		      .SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
		) rxIddr (
		      .Q0(Rxd[i]), // 1-bit output captured with C0 clock
		      .Q1(Rxd[i+4]), // 1-bit output captured with C1 clock
		      .C0(clk90), // 1-bit clock input
		      .C1(clk270), // 1-bit clock input
		      .CE(1'b1), // 1-bit clock enable input
		      .D(rgmii_rxd_i[i]),   // 1-bit DDR data input
		      .R(1'b0),   // 1-bit reset input
		      .S(1'b0)    // 1-bit set input
		);
	end
endgenerate

IDDR2 #(
      .DDR_ALIGNMENT("C0"), // Sets output alignment to "NONE", "C0" or "C1" 
      .INIT_Q0(1'b0), // Sets initial state of the Q0 output to 1'b0 or 1'b1
      .INIT_Q1(1'b0), // Sets initial state of the Q1 output to 1'b0 or 1'b1
      .SRTYPE("ASYNC") // Specifies "SYNC" or "ASYNC" set/reset
) rxdv (
      .Q0(RxDv), // 1-bit output captured with C0 clock
      .Q1(RxEr), // 1-bit output captured with C1 clock
      .C0(clk90), // 1-bit clock input
      .C1(clk270), // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(rgmii_rxdv_i),   // 1-bit DDR data input
      .R(1'b0),   // 1-bit reset input
      .S(1'b0)    // 1-bit set input
);
always @(posedge clk90) begin
	RxdR<=Rxd; RxDvR<=RxDv; RxErR<=RxEr;
end
assign Rxd_o = {Rxd[4+:4], RxdR[0+:4]};
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
