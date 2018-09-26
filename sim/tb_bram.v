

module tb_bram();

reg		sclk=1'b0;
reg		reset=1'b0;

reg			axi_tx_tready_i=1'b0;
wire			axi_tx_tvalid_o;
wire	[31:0]	axi_tx_tdata_o;
wire	[63:0]	axi_tx_tuser_o;
wire	[3:0]	axi_tx_tkeep_o;
wire			axi_tx_tlast_o;

wire			axi_rx_tready_o;
reg			axi_rx_tvalid_i=1'b0;
reg 	[31:0]	axi_rx_tdata_i='d0;
reg 	[63:0]	axi_rx_tuser_i='d0;
reg 	[3:0]	axi_rx_tkeep_i='d0;
reg 			axi_rx_tlast_i=1'b0;






wire	[31:0]	bram_axi_awaddr_i;
wire			bram_axi_awvalid_i;
wire			bram_axi_awready_o;

wire	[31:0]	bram_axi_wdata_i;
wire			bram_axi_wvalid_i;
wire	[3:0]	bram_axi_wstrb_i;
wire			bram_axi_wready_o;

wire	[1:0]	bram_axi_bresp_o;
wire			bram_axi_bvalid_o;
wire			bram_axi_bready_i;

wire	[31:0]	bram_axi_araddr_i;
wire			bram_axi_arvalid_i;
wire			bram_axi_arready_o;

wire	[31:0]	bram_axi_rdata_o;
wire			bram_axi_rvalid_o;
wire			bram_axi_rready_i;
wire	[1:0]	bram_axi_rresp_o;









initial begin
	forever begin
		#5 sclk=~sclk;
	end
	
end

initial begin
forever begin
	@(posedge sclk);
	axi_tx_tready_i<={$random};
	end
end

initial begin
repeat(280)begin
	@(posedge sclk);
end
	udp2ram();
	
end

task udp2ram();
begin
repeat (20)
	begin
	@(posedge sclk);	
	axi_rx_tvalid_i<={$random};
	axi_rx_tdata_i<={$random};
end
	@(posedge sclk);
		axi_rx_tvalid_i<=1'b1;
		axi_rx_tlast_i<=1'b1;
		
	@(posedge sclk);
		axi_rx_tvalid_i<=	1'b0;
		axi_rx_tlast_i<=	1'b0;	
		
	
end
endtask






cpu_top
  CPU(
 .RESET												(reset),
 .CLK_P				                              	            (sclk),
.axilite2axilite_0_m_axi_rresp_pin 					(bram_axi_rresp_o),
.axilite2axilite_0_m_axi_rvalid_pin 				      (bram_axi_rvalid_o),
.axilite2axilite_0_m_axi_rready_pin 				      (bram_axi_rready_i),
.axilite2axilite_0_m_axi_arvalid_pin 				      (bram_axi_arvalid_i),
.axilite2axilite_0_m_axi_arready_pin 				      (bram_axi_arready_o),
.axilite2axilite_0_m_axi_rdata_pin 					(bram_axi_rdata_o),
.axilite2axilite_0_m_axi_bvalid_pin 				      (bram_axi_bvalid_o),
.axilite2axilite_0_m_axi_araddr_pin 					(bram_axi_araddr_i),
.axilite2axilite_0_m_axi_arprot_pin 					(),
.axilite2axilite_0_m_axi_wready_pin 				      (bram_axi_wready_o),
.axilite2axilite_0_m_axi_bresp_pin 					(bram_axi_bresp_o),
.axilite2axilite_0_m_axi_bready_pin 				      (bram_axi_bready_i),
.axilite2axilite_0_m_axi_wvalid_pin 				      (bram_axi_wvalid_i),
.axilite2axilite_0_m_axi_wdata_pin 					(bram_axi_wdata_i),
.axilite2axilite_0_m_axi_awprot_pin 					(),
.axilite2axilite_0_m_axi_awvalid_pin 				      (bram_axi_awvalid_i),
.axilite2axilite_0_m_axi_wstrb_pin 					(bram_axi_wstrb_i),
.axilite2axilite_0_m_axi_awaddr_pin 					(bram_axi_awaddr_i),
.axilite2axilite_0_m_axi_awready_pin 				      (bram_axi_awready_o)
  );
  
  
  
  bram_top BRAM(
//global signals
	.sclk(sclk),
	.reset(reset),
//to udp
.axi_tx_tready_i 				(axi_tx_tready_i 	)	,
.axi_tx_tvalid_o 			      (axi_tx_tvalid_o 	)     ,
.axi_tx_tdata_o 			      (axi_tx_tdata_o 	)     ,
.axi_tx_tuser_o 			      (axi_tx_tuser_o 	)     ,
.axi_tx_tkeep_o 			      (axi_tx_tkeep_o 	)     ,
.axi_tx_tlast_o 			      (axi_tx_tlast_o 	)     ,
//.			                        (/.			      )     ,
.axi_rx_tready_o 			(axi_rx_tready_o )     ,
.axi_rx_tvalid_i 			      (axi_rx_tvalid_i 	)     ,
.axi_rx_tdata_i 			      (axi_rx_tdata_i 	)     ,
.axi_rx_tuser_i 			      (axi_rx_tuser_i 	)     ,
.axi_rx_tkeep_i 			      (axi_rx_tkeep_i 	)     ,
.axi_rx_tlast_i 			      (axi_rx_tlast_i 	)     ,
	           
//axilite       wire
	.bram_axi_awaddr_i 		(bram_axi_awaddr_i 	)      ,
	.bram_axi_awvalid_i 		(bram_axi_awvalid_i 	)      ,
	.bram_axi_awready_o	(bram_axi_awready_o)      ,
	//.		                        (/.		                  )      ,
	.bram_axi_wdata_i 		(bram_axi_wdata_i 	)      ,
	.bram_axi_wvalid_i 		(bram_axi_wvalid_i 	)      ,
	.bram_axi_wstrb_i 		(bram_axi_wstrb_i 	)      ,
	.bram_axi_wready_o 		(bram_axi_wready_o 	)      ,
	//.		                        (/.		                  )      ,
	.bram_axi_bresp_o 		(bram_axi_bresp_o 	)      ,
	.bram_axi_bvalid_o 		(bram_axi_bvalid_o 	)      ,
	.bram_axi_bready_i 		(bram_axi_bready_i 	)      ,
	//.		                        (/.		                  )      ,
	.bram_axi_araddr_i 		(bram_axi_araddr_i 	)      ,
	.bram_axi_arvalid_i 		(bram_axi_arvalid_i 	)      ,
	.bram_axi_arready_o 	(bram_axi_arready_o )      ,
	//.		                        (/.		                  )      ,
	.bram_axi_rdata_o 		(bram_axi_rdata_o 	)      ,
	.bram_axi_rvalid_o 		(bram_axi_rvalid_o 	)      ,
	.bram_axi_rready_i 		(bram_axi_rready_i 	)      ,
	.bram_axi_rresp_o 		(bram_axi_rresp_o 	)      ,
	
//other 
	.device_lock		(1'b0),
	.link_success	(1'b0),
	.ack_out		(1'b0)

	



);
endmodule 