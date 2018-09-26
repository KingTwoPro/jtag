/* This module transfer data between MII and RMII. */

module MII2RMII #(
	parameter SIM = 0,	//set 1 for simulation
	parameter CLKP = 8 	//system clock period
)
(
	//system signals
	input clk125_i, reset_i,
	//MII
	output          Rx_clk_o                  ,
	output		Tx_clk_o		  ,
	input           Tx_er_i                   ,
	input           Tx_en_i                   ,
	input   [7:0]   Txd_i                     ,
	output          Rx_er_o                   ,
	output          Rx_dv_o                   ,
	output	reg	Rx_crs_o=1'b0             ,
	output  [7:0]   Rxd_o                     ,
	//RMII
	input		rmii_ref_clk 		,
	input		rmii_rx_err_i		,
	input [1:0]	rmii_rxd_i		,
	input 		rmii_rxdv_i		,
	output[1:0]	rmii_txd_o		,
	output 		rmii_txdv_o		,
	//div clk
	output		Ref_clk_div_o
	,output [31:0] rmii_debug
);

wire RxIOClk, RxClk;
reg [1:0] rxd_rmii;
reg CvsDv_rmii, RxEr_rmii;
wire Ref_clk_div_a, Ref_clk_div_b;
reg RxdR0Vld='h0, RxdR1Vld='d0, RxdR2Vld='d0;
reg [1:0] RxdR0='d0, RxdR1='d0;
reg [1:0] RxCnt='d0; reg [2:0] RxCnt2='d0;
reg RxErR0='d0, RxErR1='d0, RxDvR0='d0, RxDvR1='d0;
reg RxErR2='d0, RxErR3='d0, RxDvR2='d0, RxDvR3='d0;
reg [7:0] RxDataR0='d0, RxDataR1='d0;
reg [7:0] RxDivDataR0='d0, RxDivDataR1='d0;
reg RxDivDvR0='d0,RxDivDvR1='d0, RxDivDvR2='h0 ;
reg RxDivErR0='d0,RxDivErR1='d0;
/* Generate clocking. */
reg [7:0] TxDivDataR0='d0, TxDivDataR1='d0, TxDivDataR2='d0;
reg TxDivDvR0='d0, TxDivDvR1='d0, TxDivDvR2='d0; 
reg TxDivErR0='d0, TxDivErR1='d0, TxDivErR2='d0; 
reg [1:0] TxDataR0='d0;
reg [1:0] TxCnt='d0;
reg [1:0] RxSt='h0;
reg [1:0] RxDec='h0;
BUFIO2 #(
	.DIVIDE(1), // DIVCLK divider (1,3-8)
	.DIVIDE_BYPASS("FALSE"), // Bypass the divider circuitry (TRUE/FALSE)
	.I_INVERT("FALSE"), // Invert clock (TRUE/FALSE)
	.USE_DOUBLER("FALSE") // Use doubler circuitry (TRUE/FALSE)
)
rx_div2_abufio (
	.DIVCLK(Ref_clk_div_a), // 1-bit output: Divided clock output
	.IOCLK(RxIOClk), // 1-bit output: I/O output clock
	.SERDESSTROBE(), // 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
	.I(rmii_ref_clk) // 1-bit input: Clock input (connect to IBUFG)
);
BUFIO2 #(
	.DIVIDE(4), // DIVCLK divider (1,3-8)
	.DIVIDE_BYPASS("FALSE"), // Bypass the divider circuitry (TRUE/FALSE)
	.I_INVERT("FALSE"), // Invert clock (TRUE/FALSE)
	.USE_DOUBLER("FALSE") // Use doubler circuitry (TRUE/FALSE)
)
rx_div2_bbufio (
	.DIVCLK(Ref_clk_div_b), // 1-bit output: Divided clock output
	.IOCLK(), // 1-bit output: I/O output clock
	.SERDESSTROBE(), // 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
	.I(rmii_ref_clk) // 1-bit input: Clock input (connect to IBUFG)
);
BUFG rxclkbufg (.I(Ref_clk_div_a), 	.O(RxClk));
BUFG rxdivbufg (.I(Ref_clk_div_b),	.O(Ref_clk_div_o));

assign rmii_debug = {RxClk, TxCnt, TxDivDvR2, TxDataR0};
always @(negedge RxIOClk) begin
	rxd_rmii<=rmii_rxd_i;
	CvsDv_rmii<=rmii_rxdv_i;
	RxEr_rmii<=rmii_rx_err_i;
end

always @(posedge RxClk) begin
	if(reset_i) begin
		RxSt<='h0;
	end
	else begin
		RxdR0 <= rxd_rmii; RxdR0Vld<=CvsDv_rmii; RxdR2Vld<=RxdR0Vld;
		case(RxSt)
			'h0: begin	//must get 0 on valid to go to valid state
				if(!RxdR0Vld)
					RxSt<='h3;
			end
			'h3: begin	//check 00 for rxd
				if(RxdR0Vld && RxdR0==2'b00)
					RxSt<='h1;
			end
			'h1: begin	//check 01 for rxd
				if(RxdR0Vld && RxdR0==2'b01) begin
					RxSt<='h2; RxdR1Vld<=1'b1; RxdR1<=RxdR0;
				end
			end
			'h2: begin
				RxdR1<=RxdR0;
				if(!RxdR0Vld && !RxdR2Vld) begin
					RxSt<='h0; RxdR1Vld<=1'b0; 
				end
			end
			default: RxSt<='h0;
		endcase
	end
end

always @(posedge RxClk) begin
	if(reset_i) begin
		RxCnt<='h0; RxDivDvR0<=1'b0; RxCnt2<='h0; RxDec<='h0;
	end
	else begin
		if(RxdR1Vld) begin
			RxCnt<=RxCnt+'h1; RxCnt2<='h0;
			case(RxCnt)
				'h0: RxDataR0[0+:2]<=RxdR1;
				'h1: RxDataR0[2+:2]<=RxdR1;
				'h2: RxDataR0[4+:2]<=RxdR1;
				'h3: begin RxDivDataR0<={RxdR1, RxDataR0[0+:6]}; RxDivDvR0<=1'b1; end
			endcase
		end
		else begin
			RxCnt<='h0;
			if(RxCnt2!='h4)
				RxCnt2<=RxCnt2+'h1;
			if(RxCnt2==4)
				RxDivDvR0<=1'b0;
		end
	end
end

always @(negedge Ref_clk_div_o) begin
	RxDataR1<=RxDivDataR0; RxDivDvR1<=RxDivDvR0;
end
always @(posedge Ref_clk_div_o) begin
	RxDivDataR1<=RxDataR1; RxDivDvR2<=RxDivDvR0;
end
assign Rxd_o = RxDivDataR1;
assign Rx_dv_o = RxDivDvR2;
assign Rx_er_o = 1'b0;
assign Rx_clk_o = Ref_clk_div_o;
/* Generate TX. */
always @(negedge RxClk) begin
	TxDivDataR0<=Txd_i; TxDivDataR1<=TxDivDataR0; TxDivDataR2<=TxDivDataR1;
	TxDivDvR0<=Tx_en_i; TxDivDvR1<=TxDivDvR0; TxDivDvR2<=TxDivDvR1;
	TxDivErR0<=Tx_er_i; TxDivErR1<=TxDivErR0; TxDivErR2<=TxDivErR1;
	if(TxDivDvR1) begin
		TxCnt<=TxCnt+'d1;
	end
	else begin
		TxCnt<='d0;
	end
	if(TxDivDvR1) begin
		case(TxCnt)
			'd0: TxDataR0<=TxDivDataR1[0+:2];
			'd1: TxDataR0<=TxDivDataR1[2+:2];
			'd2: TxDataR0<=TxDivDataR1[4+:2];
			'd3: TxDataR0<=TxDivDataR1[6+:2];
		endcase
	end
	else begin
		TxDataR0<='d0;
	end
end
assign rmii_txd_o = TxDataR0;
assign rmii_txdv_o = TxDivDvR2;
assign Tx_clk_o = Ref_clk_div_o;

endmodule
