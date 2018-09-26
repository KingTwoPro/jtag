

module bram_top(
//global signals
	input	wire		sclk,
	input	wire		reset,
//to udp
	input	wire			axi_tx_tready_i,
	output	wire			axi_tx_tvalid_o,
	output	wire	[31:0]	axi_tx_tdata_o,
	output	wire	[63:0]	axi_tx_tuser_o,
	output	wire	[3:0]	axi_tx_tkeep_o,
	output	wire			axi_tx_tlast_o,
	            
	output	wire			axi_rx_tready_o,
	input	wire			axi_rx_tvalid_i,
	input	wire 	[31:0]	axi_rx_tdata_i,
	input	wire 	[63:0]	axi_rx_tuser_i,
	input	wire 	[3:0]	axi_rx_tkeep_i,
	input	wire 			axi_rx_tlast_i,
	           
//axilite       wire
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
	
//other 
	input	wire			device_lock,
	input	wire			link_success,
	input	wire			ack_out	

	



);

wire 			tx_valid				;
wire [31:0]		tx_data			      ;
wire [16:0]		SDLEN_reg			;
wire 			tx_int_enable		;
wire 			INT_tx			      ;
wire 			tx_error			      ;
			                                    
wire 			int_tx_clear			;
wire 			tx_error_clear		;
			                                    
wire 			rx_valid			      ;
wire [31:0]		rx_data			      ;
wire [15:0]		RDLEN_reg			;
wire 			rx_int_enable		;
wire 			INT_rx			      ;
wire 			rx_error			      ;
			                                    
wire 			int_rx_clear			;
wire 			rx_error_clear		;






bram_reg
REG(

//global signals
	.sclk 					(sclk 				)		,
	.reset 	                        (reset 	                   )          ,
//		                              (	                         )          ,
//axilite	                              (ite	                         )          ,
	.bram_axi_awaddr_i 	      (bram_axi_awaddr_i 	 )          ,
	.bram_axi_awvalid_i 	      (bram_axi_awvalid_i 	 )          ,
	.bram_axi_awready_o 	(bram_axi_awready_o )          ,
//		                              (	                         )          ,
	.bram_axi_wdata_i 	      (bram_axi_wdata_i 	 )          ,
	.bram_axi_wvalid_i 	      (bram_axi_wvalid_i 	 )          ,
	.bram_axi_wstrb_i 	      (bram_axi_wstrb_i 	 )          ,
	.bram_axi_wready_o 	      (bram_axi_wready_o 	 )          ,
//		                              (	                         )          ,
	.bram_axi_bresp_o 	      (bram_axi_bresp_o 	 )          ,
	.bram_axi_bvalid_o 	      (bram_axi_bvalid_o 	 )          ,
	.bram_axi_bready_i 	      (bram_axi_bready_i 	 )          ,
//		                              (	                         )          ,
	.bram_axi_araddr_i 	      (bram_axi_araddr_i 	 )          ,
	.bram_axi_arvalid_i 	      (bram_axi_arvalid_i 	 )          ,
	.bram_axi_arready_o 	(bram_axi_arready_o )           ,
//		                              (	                         )          ,
	.bram_axi_rdata_o 	      (bram_axi_rdata_o 	 )          ,
	.bram_axi_rvalid_o 	      (bram_axi_rvalid_o 	 )          ,
	.bram_axi_rready_i 	      (bram_axi_rready_i 	 )          ,
	.bram_axi_rresp_o 	      (bram_axi_rresp_o 	 )          ,
	
//reg
	.tx_valid_o 				(tx_valid		)			,
	.tx_data_o 	                  (tx_data		)                 ,
	.SDLEN_reg_o 	            (SDLEN_reg	)                       ,
	.tx_int_enable_o 		(tx_int_enable)                     ,
	.INT_tx_i 	                  (INT_tx		)                       ,
	.tx_error_i 	                  (tx_error		)                 ,
//	.	                              (                   )                     ,
	.int_tx_clear_o 	            (int_tx_clear	)                       ,
	.tx_error_clear_o 	      (tx_error_clear)                     ,

	
	.rx_valid_o 				(rx_valid			),
	.rx_data_i 		            (rx_data			),
	.RDLEN_reg_i 		      (RDLEN_reg		),
	.rx_int_enable_o 		(rx_int_enable	),
	.INT_rx_i 		            (INT_rx			),
	.rx_error_i 		            (rx_error			),
//	.		                        (                        ),
	.int_rx_clear_o 		      (int_rx_clear		),
	.rx_error_clear_o 		(rx_error_clear	),
	
	.device_lock 			(device_lock ),
	.link_success 		      (link_success),
	.ack_out		            (ack_out	)
		                              


);






bram_tx
TX(

//global signals
	.sclk 					(sclk),
	.reset 					(reset),
	
//rx
	.axi_rx_tuser_i 			(axi_rx_tuser_i),
	
//register signals		
	.tx_valid_i 				(tx_valid		),
	.tx_data_i 			      (tx_data		),
	.SDLEN_reg_i 			(SDLEN_reg	),
	.tx_int_enable_i 			(tx_int_enable),
	.INT_tx_o 			      (INT_tx		),
	.tx_error 			      (tx_error		),
//	.			                  (                   ),
	.int_tx_clear_i 			(int_tx_clear	),
	.tx_error_clear_i 			(tx_error_clear),
	
//axi
	.axi_tx_tready_i 			(axi_tx_tready_i 	),
	.axi_tx_tvalid_o 	            (axi_tx_tvalid_o 	),
	.axi_tx_tdata_o 	            (axi_tx_tdata_o 	),
	.axi_tx_tuser_o 	            (axi_tx_tuser_o 	),
	.axi_tx_tkeep_o 	            (axi_tx_tkeep_o 	),
	.axi_tx_tlast_o	            (axi_tx_tlast_o	)



);

bram_rx RX( 

//global signals
	.sclk					(sclk),
	.reset					(reset),
	
	
//register siganls
	.rx_valid_i 				(rx_valid			),
	.rx_data_o 	                  (rx_data			),
	.RDLEN_reg_o 	            (RDLEN_reg		),
	.rx_int_enable_i 	            (rx_int_enable	),
	.INT_rx_o 	                  (INT_rx			),
	.rx_error 	                  (rx_error			),
//	.	                              (                        ),
	.int_rx_clear_i 	            (int_rx_clear		),
	.rx_error_clear_i 	            (rx_error_clear	),
	
//axi
	.axi_rx_tready_o			(axi_rx_tready_o	),
	.axi_rx_tvalid_i 		      (axi_rx_tvalid_i 	),
	.axi_rx_tdata_i 		      (axi_rx_tdata_i 	),
	.axi_rx_tuser_i 		      (axi_rx_tuser_i 	),
	.axi_rx_tkeep_i 		      (axi_rx_tkeep_i 	),
	.axi_rx_tlast_i		      (axi_rx_tlast_i	)
	
);















endmodule 