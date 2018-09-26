

module udp_ram_top
#(
	parameter OURMAC=48'd0,
	parameter	OURIP=32'd0,
	parameter	OURPORT=16'd0
)
(
	
	input	wire		sclk,
	input	wire		reset,


	input	wire	[31:0]	bram_axi_awaddr_i,
	input	wire			bram_axi_awvalid_i,
	output	wire			bram_axi_awready_o,
	          
	input	wire	[31:0]	bram_axi_wdata_i,
	input	wire			bram_axi_wvalid_i,
	input	wire	[3:0]	bram_axi_wstrb_i,
	output	wire			bram_axi_wready_o,
	           
	output	wire	[1:0]	bram_axi_bresp_o,
	output	wire			bram_axi_bvalid_o,
	input	wire			bram_axi_bready_i,
	            
	input	wire	[31:0]	bram_axi_araddr_i,
	input	wire			bram_axi_arvalid_i,
	output	wire			bram_axi_arready_o,
	            
	output	wire	[31:0]	bram_axi_rdata_o,
	output	wire			bram_axi_rvalid_o,
	input	wire			bram_axi_rready_i,
	output	wire	[1:0]	bram_axi_rresp_o,
	
	input 		rgmii_rxclk_i		,
	input [3:0]	rgmii_rxd_i		,
	input 		rgmii_rxdv_i		,
	output[3:0]	rgmii_txd_o		,
	output 		rgmii_txdv_o		,
	output 		rgmii_txclk_o           ,
	
	input	wire			device_lock,
	input	wire			link_success,
	input	wire			ack_out	

	
	
);



wire				rx_usr_data_vld_o	;
wire	[31:0]		rx_usr_data_o		;
wire	[31:0]		rx_user_o			;
wire	[3:0]		rx_usr_be_o			;
wire				rx_usr_tlast_o		;
wire				rx_usr_ready_i		;
                                                            
wire				tx_usr_data_vld_i	;
wire[31:0]			tx_usr_data_i		;	
wire[63:0]			tx_user_i			;
wire[3:0]			tx_usr_be_i			;
wire				tx_usr_tlast_i		;
wire				tx_usr_ready_o		;









bram_top BRAM(
//global signals
	.sclk					(sclk),
	.reset                            (reset),
//to udp
	.axi_tx_tready_i			(tx_usr_ready_o),			
	.axi_tx_tvalid_o			(tx_usr_data_vld_i),			
	.axi_tx_tdata_o			(tx_usr_data_i),				
	.axi_tx_tuser_o			(tx_user_i),					
	.axi_tx_tkeep_o			(tx_usr_be_i),				
	.axi_tx_tlast_o			(tx_usr_tlast_i),				
	                                                                              
	.axi_rx_tready_o		(rx_usr_ready_i),  	
	.axi_rx_tvalid_i		      (rx_usr_data_vld_o),  	
	.axi_rx_tdata_i		      (rx_usr_data_o),  		
	.axi_rx_tuser_i		      (rx_user_o),   			
	.axi_rx_tkeep_i		      (rx_usr_be_o),  	 		
	.axi_rx_tlast_i		      (rx_usr_tlast_o),   		
	           
//axilite       wire
.bram_axi_awaddr_i			(bram_axi_awaddr_i	)	 ,
.bram_axi_awvalid_i		      (bram_axi_awvalid_i	)      ,
.bram_axi_awready_o		(bram_axi_awready_o)      ,
//		                              (/		                  )      ,
.bram_axi_wdata_i		      (bram_axi_wdata_i	)      ,
.bram_axi_wvalid_i		      (bram_axi_wvalid_i	)      ,
.bram_axi_wstrb_i		      (bram_axi_wstrb_i	)      ,
.bram_axi_wready_o		      (bram_axi_wready_o	)      ,
//		                              (/		                  )      ,
.bram_axi_bresp_o		      (bram_axi_bresp_o	)      ,
.bram_axi_bvalid_o		      (bram_axi_bvalid_o	)      ,
.bram_axi_bready_i		      (bram_axi_bready_i	)      ,
//		                              (/		                  )      ,
.bram_axi_araddr_i		      (bram_axi_araddr_i	)      ,
.bram_axi_arvalid_i		      (bram_axi_arvalid_i	)      ,
.bram_axi_arready_o		      (bram_axi_arready_o	)      ,
//		                              (/		                  )      ,
.bram_axi_rdata_o		      (bram_axi_rdata_o	)      ,
.bram_axi_rvalid_o		      (bram_axi_rvalid_o	)      ,
.bram_axi_rready_i		      (bram_axi_rready_i	)      ,
.bram_axi_rresp_o		      (bram_axi_rresp_o	)      ,
	
//other 
.device_lock					 (device_lock	),
.link_success                         (link_success  ),
.ack_out	                         (ack_out	  )

	
 


);


udp_top
#(
.OURMAC			(OURMAC	),
.OURIP				(OURIP		),
.OURPORT			(OURPORT	)
)
UDP(
.sclk						(sclk),
.reset                                  (reset),
	
.rgmii_rxclk_i				(rgmii_rxclk_i)	,
.rgmii_rxd_i					(rgmii_rxd_i	),
.rgmii_rxdv_i				(rgmii_rxdv_i)	,
.rgmii_txd_o					(rgmii_txd_o	),
.rgmii_txdv_o				(rgmii_txdv_o)	,
.rgmii_txclk_o    		      	(rgmii_txclk_o),

	
.rx_usr_data_vld_o			(rx_usr_data_vld_o	),
.rx_usr_data_o				(rx_usr_data_o		),
.rx_user_o					(rx_user_o			),
.rx_usr_be_o				(rx_usr_be_o		),
.rx_usr_tlast_o				(rx_usr_tlast_o		),
.rx_usr_ready_i				(rx_usr_ready_i		),
	
	//user tx to udp
	.tx_usr_data_vld_i		(tx_usr_data_vld_i	),
	.tx_usr_data_i			(tx_usr_data_i		),	
	.tx_user_i				(tx_user_i			),
	.tx_usr_be_i				(tx_usr_be_i			),
	.tx_usr_tlast_i			(tx_usr_tlast_i		)		,
	.tx_usr_ready_o			(tx_usr_ready_o		)

);


endmodule