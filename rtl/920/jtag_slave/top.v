



module top(
	input	wire	sclk,
	input	wire	reset,
	
	input	wire			TCK,
	input	wire			TMS,
	input	wire			TDO,
	input	wire			TDI
);


wire	[31:0]		s_axi_awaddr_i;
wire				s_axi_awvalid_i;
wire				s_axi_awready_o;
                        
wire	[31:0]		s_axi_wdata_i;
wire				s_axi_wvalid_i;
wire	[3:0]		s_axi_wstrb_i;
wire				s_axi_wready_o;
                        
wire		[1:0]	s_axi_bresp_o;
wire				s_axi_bvalid_o;
wire				s_axi_bready_i;
                        
wire	[31:0]		s_axi_araddr_i;
wire			s_axi_arvalid_i;
wire				s_axi_arready_o;
                        
wire		[31:0]	s_axi_rdata_o;
wire				s_axi_rvalid_o;
wire			s_axi_rready_i;
wire		[1:0]	s_axi_rresp_o;







 slave_top top(
	.sclk					(sclk				),
	.reset 		                  (reset 		           ),
//			                        (		                 ),
//			                        (		                 ),
	.s_axi_awaddr_i 		      (s_axi_awaddr_i 		),
	.s_axi_awvalid_i 		(s_axi_awvalid_i 	),
	.s_axi_awready_o 		(s_axi_awready_o 	),
//			                        (		                 ),
	.s_axi_wdata_i 		      (s_axi_wdata_i 		),
	.s_axi_wvalid_i 		      (s_axi_wvalid_i 		),
	.s_axi_wstrb_i 		      (s_axi_wstrb_i 		),
	.s_axi_wready_o 		(s_axi_wready_o 	),
//			                        (		                 ),
	.s_axi_bresp_o 		      (s_axi_bresp_o 		),
	.s_axi_bvalid_o 		      (s_axi_bvalid_o 		),
	.s_axi_bready_i 		      (s_axi_bready_i 		),
//			                        (		                 ),
	.s_axi_araddr_i 		      (s_axi_araddr_i 		),
	.s_axi_arvalid_i 		      (s_axi_arvalid_i 		),
	.s_axi_arready_o 		(s_axi_arready_o 	),
//			                        (		                 ),
	.s_axi_rdata_o 		      (s_axi_rdata_o 		),
	.s_axi_rvalid_o 		      (s_axi_rvalid_o 		),
	.s_axi_rready_i 		      (s_axi_rready_i 		),
	.s_axi_rresp_o 		      (s_axi_rresp_o 		),
//			                        (		                 ),
	.TCK 		                  (TCK 		           ),
	.TMS 		                  (TMS 		           ),
	.TDO 		                  (TDO 		           ),
	.TDI 		                  (TDI 		           ),
//			                        (),
	.INT		                  ()

);

cpu_top  cpu(

 .RESET												(reset),
 .CLK_P				                              	            (sclk),
.axilite2axilite_0_m_axi_rresp_pin 					(s_axi_rresp_o),
.axilite2axilite_0_m_axi_rvalid_pin 				      (s_axi_rvalid_o),
.axilite2axilite_0_m_axi_rready_pin 				      (s_axi_rready_i),
.axilite2axilite_0_m_axi_arvalid_pin 				      (s_axi_arvalid_i),
.axilite2axilite_0_m_axi_arready_pin 				      (s_axi_arready_o),
.axilite2axilite_0_m_axi_rdata_pin 					(s_axi_rdata_o),
.axilite2axilite_0_m_axi_bvalid_pin 				      (s_axi_bvalid_o),
.axilite2axilite_0_m_axi_araddr_pin 					(s_axi_araddr_i),
.axilite2axilite_0_m_axi_arprot_pin 					(),
.axilite2axilite_0_m_axi_wready_pin 				      (s_axi_wready_o),
.axilite2axilite_0_m_axi_bresp_pin 					(s_axi_bresp_o),
.axilite2axilite_0_m_axi_bready_pin 				      (s_axi_bready_i),
.axilite2axilite_0_m_axi_wvalid_pin 				      (s_axi_wvalid_i),
.axilite2axilite_0_m_axi_wdata_pin 					(s_axi_wdata_i),
.axilite2axilite_0_m_axi_awprot_pin 					(),
.axilite2axilite_0_m_axi_awvalid_pin 				      (s_axi_awvalid_i),
.axilite2axilite_0_m_axi_wstrb_pin 					(s_axi_wstrb_i),
.axilite2axilite_0_m_axi_awaddr_pin 					(s_axi_awaddr_i),
.axilite2axilite_0_m_axi_awready_pin 				      (s_axi_awready_o)
  );


endmodule