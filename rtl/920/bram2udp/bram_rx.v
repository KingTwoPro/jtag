

module bram_rx(

//global signals
	input wire	sclk,
	input wire 	reset,
	

	
//register siganls
	input	wire			rx_valid_i,
	output	reg		[31:0]	rx_data_o='d0,
	output	reg		[15:0]	RDLEN_reg_o='d0,
	input	wire			rx_int_enable_i,
	output	reg				INT_rx_o=1'b0,
	output	reg				rx_error=1'b0,
	
	input	wire			int_rx_clear_i,
	input	wire			rx_error_clear_i,
	
//axi
	output	reg				axi_rx_tready_o=1'b1,
	input	wire			axi_rx_tvalid_i,
	input	wire 	[31:0]	axi_rx_tdata_i,
	input	wire 	[63:0]	axi_rx_tuser_i,
	input	wire 	[3:0]	axi_rx_tkeep_i,
	input	wire 			axi_rx_tlast_i
	
	

);

//fifo signals
reg		fifo_wren=1'b0;
reg		fifo_rden=1'b0;
reg	[31:0]	fifo_din='d0;
reg		fifo_reset=1'b0;

wire	fifo_empty;
wire	fifo_full;
wire [31:0]	fifo_dout;




	
//count
reg	[9:0]	databyte_cnt='d0;
reg	[11:0]	databyte_reg='d0;

//axi
always@(posedge sclk)
	if(axi_rx_tready_o&&axi_rx_tvalid_i)
	begin
		fifo_wren<=1'b1;
		fifo_din<=axi_rx_tdata_i;
	end
	else
		fifo_wren<=1'b0;
	

	
//count
always@(posedge sclk)
	if(axi_rx_tready_o&&axi_rx_tvalid_i&&axi_rx_tlast_i)
		databyte_cnt<='d0;
	
	else if(axi_rx_tready_o&&axi_rx_tvalid_i)
		databyte_cnt<=databyte_cnt+1'b1;
	
always@(posedge sclk)
	if(int_rx_clear_i)
		databyte_reg<='d0;
	
	else if(axi_rx_tready_o&&axi_rx_tvalid_i&&axi_rx_tlast_i)
		databyte_reg<=databyte_cnt+1'b1;;
	
always@(posedge sclk)
	if(int_rx_clear_i)
		RDLEN_reg_o<='d0;
	else if(INT_rx_o)
		RDLEN_reg_o<={databyte_reg,axi_rx_tkeep_i};
	

//interrupt		
always@(posedge sclk)
	if(axi_rx_tready_o&&axi_rx_tvalid_i&&axi_rx_tlast_i&&rx_int_enable_i)
		INT_rx_o<=1'b1;
	else if(int_rx_clear_i) 
		INT_rx_o<=1'b0;

	
always@(posedge sclk)
	if(INT_rx_o&&int_rx_clear_i)
		fifo_reset<=1'b1;
	else
		fifo_reset<=1'b0;
	
//error
always@(posedge sclk)
	if(int_rx_clear_i&&~fifo_empty)
		rx_error<=1'b1;
	else if(rx_error_clear_i)
		rx_error<=1'b0;
		

//to cpu
always@(posedge sclk)
	if(rx_valid_i)
	begin
		fifo_rden<=1'b1;
		rx_data_o<=fifo_dout;
		
	end
	else
		fifo_rden<=1'b0;

fifo_32x512 rx_fifo (
  .clk(sclk), // input clk
  .rst(fifo_reset), // input rst
  .din(fifo_din), // input [31 : 0] din
  .wr_en(fifo_wren), // input wr_en
  .rd_en(fifo_rden), // input rd_en
  .dout(fifo_dout), // output [31 : 0] dout
  .full(fifo_full), // output full
  .empty(fifo_empty) // output empty
);		



endmodule