

	module slave_top(
	input	wire	sclk,
	input	wire	reset,
	
	
	input	wire	[31:0]	s_axi_awaddr_i,
	input	wire			s_axi_awvalid_i,
	output	wire				s_axi_awready_o,
	                                    
	input	wire	[31:0]	s_axi_wdata_i,
	input	wire			s_axi_wvalid_i,
	input	wire	[3:0]	s_axi_wstrb_i,
	output	wire				s_axi_wready_o,
	                                    
	output	wire		[1:0]	s_axi_bresp_o,
	output	wire				s_axi_bvalid_o,
	input	wire			s_axi_bready_i,
	                                    
	input	wire	[31:0]	s_axi_araddr_i,
	input	wire			s_axi_arvalid_i,
	output	wire				s_axi_arready_o,
	                                    
	output	wire		[31:0]	s_axi_rdata_o,
	output	wire				s_axi_rvalid_o,
	input	wire			s_axi_rready_i,
	output	wire		[1:0]	s_axi_rresp_o,
	
	input	wire			TCK,
	input	wire			TMS,
	input	wire			TDO,
	input	wire			TDI,
	
	output	wire			INT

);

wire		[1:0]	enable_register		;
wire				int_register			;
wire		[7:0]	IR_register 			;
wire		[15:0]	DATALEN_register	;
wire				clear_int			;
wire		[7:0]	IRLEN_register		;


wire	[9:0]	ram_raddr				;
wire	[31:0]	ram_rdata				;

wire				ram_we				;
wire		[8:0]	ram_waddr		;
wire		[31:0]	ram_wdata		;

jtag_register REG(

	.sclk				(sclk),
	.reset				(reset),
	
//axilite
	.s_axi_awaddr_i 		(s_axi_awaddr_i 	)	    ,
	.s_axi_awvalid_i 	(s_axi_awvalid_i )         ,
	.s_axi_awready_o	(s_axi_awready_o)        ,
		                          	                            
	.s_axi_wdata_i 	      (s_axi_wdata_i 	)         ,
	.s_axi_wvalid_i 	      (s_axi_wvalid_i 	)         ,
	.s_axi_wstrb_i 	      (s_axi_wstrb_i 	)         ,
	.s_axi_wready_o 	(s_axi_wready_o )         ,
		                          	                            
	.s_axi_bresp_o	      (s_axi_bresp_o	)         ,
	.s_axi_bvalid_o 	      (s_axi_bvalid_o 	)         ,
	.s_axi_bready_i 	      (s_axi_bready_i 	)         ,
	                          	                            
	.s_axi_araddr_i 	      (s_axi_araddr_i 	)         ,
	.s_axi_arvalid_i 	      (s_axi_arvalid_i 	)         ,
	.s_axi_arready_o 	(s_axi_arready_o )         ,
		                          	                            
	.s_axi_rdata_o 	      (s_axi_rdata_o 	)         ,
	.s_axi_rvalid_o 	      (s_axi_rvalid_o 	)         ,
	.s_axi_rready_i 	      (s_axi_rready_i 	)         ,
	.s_axi_rresp_o	      (s_axi_rresp_o	)         ,

//reg
	.enable_register_o 	(enable_register		)	 ,
	.int_register_i 		(int_register			)      ,
	.IR_register_i 		(IR_register 			)      ,
	.DATALEN_register_i 	(DATALEN_register	)      ,
	.clear_int_o 			(clear_int			)      ,
	                                                                   
//ram
	.ram_raddr			(ram_raddr),
	.ram_rdata			(ram_rdata)
	
);


jtag_catch CATCH(
//global signals
	.sclk				(sclk),
	.reset				(reset),
	
//JTAG signals
	.TCK				(TCK),
	.TMS				(TMS),
	.TDI					(TDI	),
	.TDO				(TDO),

//register signals
	.enable_register_i 	(enable_register			)	 ,
	.int_register_o          (int_register				)      ,
	.IR_register              (IR_register 				)      ,
	.DATALEN_register_o (DATALEN_register		)      ,
	.clear_int_i               (clear_int				)      ,
	.IRLEN_register		(IRLEN_register),
	
//interrupt 
	.INT				(INT),
	
//ram
	.ram_we			 (ram_we	)	,
	.ram_waddr               (ram_waddr  )    ,
	.ram_wdata               (ram_wdata  )
	
	

	
);

ram_32x512 ram_32x256 (
  .clka(sclk), // input clka
  .wea(ram_we), // input [0 : 0] wea
  .addra(ram_waddr), // input [8 : 0] addra
  .dina(ram_wdata), // input [31 : 0] dina
  .clkb(sclk), // input clkb
  .addrb(ram_raddr), // input [8 : 0] addrb
  .doutb(ram_rdata) // output [31 : 0] doutb
);


endmodule