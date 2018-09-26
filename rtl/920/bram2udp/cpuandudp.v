


module cpuandudp(
	input	sclk,
	input	reset,
	
	input 		rgmii_rxclk_i		,
	input [3:0]		rgmii_rxd_i		,
	input 		rgmii_rxdv_i		,
	output[3:0]		rgmii_txd_o		,
	output 		rgmii_txdv_o		,
	output 		rgmii_txclk_o           ,
	
	input	wire			device_lock,
	input	wire			link_success,
	input	wire			ack_out	

);




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


udp_ram_top
#(
	.OURMAC		(OURMAC		),
	.OURIP		(OURIP		),
	.OURPORT		(OURPORT		)
)
UDPRAM(
	
	.sclk					(sclk),
	.reset				(reset),
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
	
	.rgmii_rxclk_i			(rgmii_rxclk_i	),
	.rgmii_rxd_i			(rgmii_rxd_i	),
	.rgmii_rxdv_i			(rgmii_rxdv_i	),
	.rgmii_txd_o			(rgmii_txd_o	),
	.rgmii_txdv_o			(rgmii_txdv_o	),
	.rgmii_txclk_o          	(rgmii_txclk_o    ) ,
	//	                        (	            )
	.device_lock			(device_lock	),
	.link_success			(link_success	),
	.ack_out		            (ack_out		)

	
	
);



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
  
  
  
endmodule