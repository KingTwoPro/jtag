

module bram_reg
#(
	BASEADDR=32'h4000_0000
)

(

//global signals
	input wire	 sclk,
	input wire	reset,
	
//axilite
	input	wire	[31:0]	bram_axi_awaddr_i,
	input	wire			bram_axi_awvalid_i,
	output	reg				bram_axi_awready_o=1'b1,
	
	input	wire	[31:0]	bram_axi_wdata_i,
	input	wire			bram_axi_wvalid_i,
	input	wire	[3:0]	bram_axi_wstrb_i,
	output	reg				bram_axi_wready_o=1'b0,
	
	output	reg		[1:0]	bram_axi_bresp_o=2'd0,
	output	reg				bram_axi_bvalid_o=1'b0,
	input	wire			bram_axi_bready_i,
	
	input	wire	[31:0]	bram_axi_araddr_i,
	input	wire			bram_axi_arvalid_i,
	output	reg				bram_axi_arready_o=1'b1,
	
	output	reg		[31:0]	bram_axi_rdata_o='d0,
	output	reg				bram_axi_rvalid_o=1'b0,
	input	wire			bram_axi_rready_i,
	output	reg		[1:0]	bram_axi_rresp_o=2'd0,
	
//reg
	output	reg				tx_valid_o=1'b0,
	output	reg	[31:0]		tx_data_o='d0,
	output	reg	[16:0]		SDLEN_reg_o='d0,
	output	reg				tx_int_enable_o=1'b0,	
	input	wire			INT_tx_i,
	input	wire			tx_error_i,
	
	output	reg				int_tx_clear_o=1'b0,
	output	reg				tx_error_clear_o=1'b0,

	
	output	reg				rx_valid_o=1'b0,
	input	wire	[31:0]	rx_data_i,
	input	wire	[15:0]	RDLEN_reg_i,
	output	reg				rx_int_enable_o=1'b0,
	input	wire			INT_rx_i,
	input	wire			rx_error_i,
	
	output	reg				int_rx_clear_o=1'b0,
	output	reg				rx_error_clear_o=1'b0,
	
	input	wire			device_lock,
	input	wire			link_success,
	input	wire			ack_out



);

localparam
	INT_ENABLE	=	16'h0000,
	INT_STATUS=	16'h0004,
	SDLEN		=	16'h0008,
	RDLEN	=		16'h000c,
	STATUS	=		16'h0010,
	BRAM_SENDSTART = 	16'h0800,
	BRAM_SENDEND =		16'h0fff,
	BRAM_REVSTART =	16'h1000,
	BRAM_REVEND= 		16'h17ff;
	



reg  [3:0] state='d0;
reg	 [15:0]	addr='d0;


always@(posedge sclk)
	if(reset) begin
		state<='h0;
		
	end
	else case(state)
		'h0:begin
			int_rx_clear_o<=1'b0;
			int_tx_clear_o<=1'b0;
		
		
			bram_axi_awready_o<=1'b1;
			bram_axi_arready_o<=1'b1;
			
			if(bram_axi_awvalid_i&&bram_axi_awready_o)
			begin
				bram_axi_awready_o<=1'b0;
				bram_axi_arready_o<=1'b0;
				addr<=bram_axi_awaddr_i[0+:16];
				
				state<='h1;
			end
			
			else if(bram_axi_awvalid_i&&bram_axi_awready_o)
			begin
				bram_axi_awready_o<=1'b0;
				bram_axi_arready_o<=1'b0;
				addr<=bram_axi_araddr_i[0+:16];
				rx_valid_o<=1'b1;
				state<='h2;
			end
		end	
		
		'h1:begin
			bram_axi_wready_o<=1'b1;
			
			if(bram_axi_wvalid_i&&bram_axi_wready_o)
			begin
				bram_axi_wready_o<=1'b0;
			
				state<='h2;
				
			
					if(addr==INT_ENABLE)	begin tx_int_enable_o<=bram_axi_wdata_i[1]; rx_int_enable_o<=bram_axi_wdata_i[0]; end
					
					else if(addr==SDLEN)begin SDLEN_reg_o<={bram_axi_wdata_i[31],bram_axi_wdata_i[15:0]}; end
					
					else if(addr==STATUS) begin rx_error_clear_o<=bram_axi_wdata_i[4]; tx_error_clear_o<=bram_axi_wdata_i[3]; end
					
					else if(addr>=16'h800&&addr<=16'hfff) begin tx_data_o<=bram_axi_wdata_i;	tx_valid_o<=1'b1;end
				
				
			end
			
			
		end
		
		'h2:begin
			tx_valid_o<=1'b0;
			bram_axi_bvalid_o<=1'b1;
			if(bram_axi_bvalid_o&&bram_axi_bready_i)
			begin
				bram_axi_bvalid_o<=1'b0;
				state<='h0;
			end
		end	
		
		
		'h3:begin
			rx_valid_o<=1'b0;
			bram_axi_rvalid_o<=1'b1;
				
				if(addr==INT_ENABLE)	 bram_axi_rdata_o<={tx_int_enable_o,rx_int_enable_o}; 
				
				else if(addr==INT_STATUS) begin bram_axi_rdata_o<={INT_tx_i,INT_rx_i}; int_tx_clear_o<=1'b1; int_rx_clear_o<=1'b1; end
					
				else if(addr==SDLEN)		bram_axi_rdata_o<=SDLEN_reg_o;
				
				else if(addr==RDLEN)	bram_axi_rdata_o<=RDLEN_reg_i;
				
				else if(addr==STATUS)	bram_axi_rdata_o<={rx_error_i,tx_error_i,ack_out,link_success,device_lock};
				
				else if(addr>=16'h1000&&addr<=16'h17ff)bram_axi_rdata_o<=rx_data_i;
				
				
				
			if(bram_axi_rvalid_o&&bram_axi_rready_i)
			begin
				bram_axi_rvalid_o<=1'b0;
				state<='h0;
			end
			
		end
		

		
		
	
	
	endcase








endmodule