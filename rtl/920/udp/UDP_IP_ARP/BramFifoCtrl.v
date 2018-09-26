/* This module get Mac data and buffer it. Then sent to the other mac if
	* necessary.*/

module BramFifoCtrl (
	input		clk_i			,
	input		reset_i			,
			//Mac input
	input	[31:0]	rx_mac_data_i		,
	input	[1:0]	rx_mac_data_be_i	,//00,01,10,11  4,1,2,3  1111 1110 1100 1000
	input		rx_mac_data_pa_i	,
	input		rx_mac_data_sop_i	,
	input		rx_mac_data_eop_i	,
			//Arb output
	output reg	TxReq_o			,
	input		TxGnt_i			,
	output reg	TxDataVld_o		,
	output [31:0] 	TxData_o		,
	output     [3:0]	TxDataTkeep_o		,
	output     	TxDataTlast_o		,
	input		TxDataRdy_i		,
			//Control interface
	input		SwitchVld_i			//1 to send data to the other mac
);
//Bram interface 36x1k
reg BramWr, BramRd;
reg [9:0] BramWAddr='h0, BramRAddr='h0;
reg [35:0] BramWData;
wire [35:0] BramRData;
//Fifo interface
reg FifoWr, FifoRd;
reg [9:0] FifoWData;
wire [9:0] FifoRData;
wire FifoEmpty, FifoFull;

reg [9:0] StartAddr, EndAddr;
reg [9:0] TargetAddr;

reg [3:0] st1, st2;

assign TxDataTlast_o=BramRData[32] & TxDataVld_o;
assign TxDataTkeep_o=BramRData[35:33];
assign TxData_o = BramRData[31:0];

//write data to bram without stop
always @(posedge clk_i)  begin
	if(reset_i) begin
		BramWr<=1'b0; FifoWr<=1'b0; st1<='h0;
	end
	else begin
		FifoWr<=1'b0; BramWr<=1'b0;
		if(rx_mac_data_pa_i) begin
			BramWr<=1'b1; BramWData<={rx_mac_data_be_i, rx_mac_data_sop_i, rx_mac_data_eop_i,rx_mac_data_i}; BramWAddr<=BramWAddr+'h1;
		end
		StartAddr<=(rx_mac_data_sop_i && rx_mac_data_pa_i)? BramWAddr+'h1 : StartAddr;
		EndAddr<=(rx_mac_data_eop_i && rx_mac_data_pa_i)? BramWAddr+'h1 : StartAddr;
		case(st1) 
			'h0: begin
				if(rx_mac_data_eop_i && rx_mac_data_pa_i && SwitchVld_i) begin
					st1<='h1; FifoWr<=1'b1; FifoWData<=StartAddr;
				end
			end
			'h1: begin
				st1<='h2; FifoWr<=1'b1; FifoWData<=EndAddr;
			end
			'h2: begin
				st1<='h0;
			end
			default: st1<='h0;
		endcase
	end
end
//read bram and fifo
always @(posedge clk_i)  begin
	if(reset_i) begin
		TxReq_o<=1'b0; TxDataVld_o<=1'b0; st2<='h0; BramRd<=1'b0; FifoRd<=1'b0;
	end
	else begin
		TxDataVld_o<=BramRd && TxDataRdy_i;
		case(st2)
			'h0: begin	//check fifo
				if(!FifoEmpty) begin
					TxReq_o<=1'b1; st2<='h1;
				end
			end
			'h1: begin
				if(TxGnt_i) begin
					TxReq_o<=1'b0;st2<='h2;
				end
			end
			'h2: begin	//read fifo and bram
				FifoRd<=1'b1; st2<='h3;
			end
			'h3: begin
				FifoRd<=1'b1; st2<='h4; BramRAddr<=FifoRData;
			end
			'h4: begin
				FifoRd<=1'b0; TargetAddr<=FifoRData; st2<='h5;
				BramRd<=1'b1;
			end
			'h5: begin
				if(BramRd && TxDataRdy_i) begin
					if(BramRAddr!=TargetAddr) begin
						BramRAddr<=BramRAddr+'h1;
					end
					else begin
						BramRd<=1'b0; st2<='h6;
					end
				end
			end
			'h6: begin
				st2<='h7; 
			end
			'h7: begin
				st2<='h0;
			end
			default: st2<='h0;
		endcase
	end
end

bram_36x1k SwitchBram(
	.clka	(clk_i),
	.wea	(BramWr),
	.addra	(BramWAddr),
	.dina	(BramWData),
	.clkb	(clk_i),
	.enb	(BramRd & TxDataRdy_i),
	.addrb	(BramRAddr),
	.doutb	(BramRData) 
);

fifo_10x64 SwitchFifo(
	.clk	(clk_i),
	.rst	(reset_i),
	.din	(FifoWData),
	.wr_en	(FifoWr),
	.rd_en	(FifoRd),
	.dout	(FifoRData),
	.full	(FifoFull),
	.empty	(FifoEmpty) 
);

endmodule
