

module bram_tx
// #(
	// parameter SOURCEPOT=aabb
// )
(

//global signals
	input	wire		sclk,
	input	wire		reset,
	
//rx
	input	wire	[63:0]		axi_rx_tuser_i,
	
//register signals
	input	wire			tx_valid_i,
	input	wire	[31:0]	tx_data_i,
	input	wire	[16:0]	SDLEN_reg_i,
	input	wire			tx_int_enable_i,	
	output	reg				INT_tx_o=1'b0,
	output	reg				tx_error=1'b0,
	
	input	wire			int_tx_clear_i,
	input	wire			tx_error_clear_i,
	
//axi
	input	wire			axi_tx_tready_i,
	output	reg				axi_tx_tvalid_o=1'b0 ,
	output	reg		[31:0]	axi_tx_tdata_o,
	output	reg		[63:0]	axi_tx_tuser_o,
	output	reg		[3:0]	axi_tx_tkeep_o,
	output	reg				axi_tx_tlast_o=1'b0



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
reg	[11:0] databyte_cnt='d0;


//save data from cpu
always@(posedge sclk)
	if(tx_valid_i&&~fifo_full) begin
		fifo_wren<=1'b1;
		fifo_din<=tx_data_i;
	end
	else begin
		fifo_wren<=1'b0;
	end


//monitor flag of sending start
always@(posedge sclk)
	if(INT_tx_o)
		axi_tx_tvalid_o<=1'b0;
	else if(databyte_cnt==(SDLEN_reg_i[15:2]+1'b1)&&SDLEN_reg_i[1:0]!='d0&&axi_tx_tvalid_o&&axi_tx_tready_i)
		axi_tx_tvalid_o<=1'b0;	
	else if(databyte_cnt==SDLEN_reg_i[15:2]&&SDLEN_reg_i[1:0]=='d0&&axi_tx_tvalid_o&&axi_tx_tready_i)
		axi_tx_tvalid_o<=1'b0;
	else if(SDLEN_reg_i[16]) 
		axi_tx_tvalid_o<=1'b1;
	
//count the send data
always@(posedge sclk)
	if(axi_tx_tvalid_o&&axi_tx_tready_i)
	begin
		if(databyte_cnt==(SDLEN_reg_i[15:2]+1'b1)&&SDLEN_reg_i[1:0]!='d0)
			databyte_cnt<='d0;
		else if(databyte_cnt==SDLEN_reg_i[15:2]&&SDLEN_reg_i[1:0]=='d0)
			databyte_cnt<='d0;
		else
			databyte_cnt<=databyte_cnt+1'b1;
	end

	


	
//axi
always@(*)
	if(axi_tx_tvalid_o&&axi_tx_tready_i)
		fifo_rden<=1'b1;
	else
		fifo_rden<=1'b0;
	
always@(*)
	axi_tx_tdata_o<=fifo_dout;
	
always@(posedge sclk)
	if(databyte_cnt==(SDLEN_reg_i[15:2])&&SDLEN_reg_i[1:0]!='d0)
		axi_tx_tlast_o<=1'b1;
	else if(databyte_cnt==(SDLEN_reg_i[15:2]-1'b1)&&SDLEN_reg_i[1:0]=='d0)
		axi_tx_tlast_o<=1'b1;
	else if(axi_tx_tvalid_o&&axi_tx_tready_i)
		axi_tx_tlast_o<=1'b0;
	
always@(posedge sclk)
	axi_tx_tuser_o<={SDLEN_reg_i[15:0],16'd0,axi_rx_tuser_i[15:0],axi_rx_tuser_i[31:16]};

always@(posedge sclk)
	axi_tx_tkeep_o<=SDLEN_reg_i[1:0];


//interrupt
always@(posedge sclk)
	if(axi_tx_tvalid_o&&axi_tx_tready_i&&axi_tx_tlast_o&&tx_int_enable_i)
	begin
		INT_tx_o<=1'b1;
	end
	else if(int_tx_clear_i)begin
		INT_tx_o<=1'b0;
	end

	
always@(posedge sclk)
	if(int_tx_clear_i&&INT_tx_o)
		fifo_reset<=1'b1;
	else
		fifo_reset<=1'b0;
	
//error
always@(posedge sclk)
	if(axi_tx_tvalid_o&&axi_tx_tready_i&&axi_tx_tlast_o&&~fifo_empty)
		tx_error<=1'b1;
	else if(tx_error_clear_i)
		tx_error<=1'b0;
		
		
		
		
fifo_32x512 tx_fifo (
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