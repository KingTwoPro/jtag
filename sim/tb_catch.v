
`timescale 1ns/1ns


module tb_catch();

localparam
	TEST_LOGIC_RESET='h0,
	RUN_TEST	=	'h1,
	SELECT_DR_SCAN = 'h2,
	SELECT_IR_SCAN = 'h3,
	CAPTURE_DR = 'h4,
	SHIFT_DR = 'h5,
	EXIT_1_DR = 'h6,
	PAUSE_DR= 'h7,
	EXIT_2_DR = 'h8,
	UPDATE_DR = 'h9,
	
	CAPTURE_IR = 'ha,
	SHIFT_IR = 'hb,
	EXIT_1_IR = 'hc,
	PAUSE_IR='hd,
	EXIT_2_IR = 'he,
	UPDATE_IR='hf;

	reg		 sclk=1'b0;
	reg		reset=1'b0;
	
	reg		TCK=1'b0;
	reg		TMS=1'b1;
	reg		TDI=1'b0;
	reg		TDO=1'b0;

	reg	[5:0]	TAP='d0;
	
reg	[1:0]	enable_register='d0;

wire				int_register			;
wire		[7:0]	IR_register 			;
wire		[15:0]	DATALEN_register	;
reg				clear_int=1'b0			;




reg	[9:0]	ram_raddr='d0				;
wire	[31:0]	ram_rdata				;

wire				ram_we				;
wire		[9:0]	ram_waddr		;
wire		[31:0]	ram_wdata		;













initial begin
	forever begin
		#50 TCK<=~TCK;
		
	end
	
end	
	
initial begin
	forever begin
		#5 sclk<=~sclk;
	end
end



initial begin
	@(posedge sclk);
		enable_register<='b11;
	
		@(posedge sclk);
		@(posedge sclk);
		@(posedge sclk);
		@(negedge TCK);
			TMS<=1'b0;
		IR(8,32'h0000_0025);
		DR(36,36'ha_1234_5678,36'hb_1111_1111);
	
	@(posedge sclk);
		@(posedge sclk);
		@(posedge sclk);
		ram_raddr<=ram_raddr+1'b1;
			@(posedge sclk);
		ram_raddr<=ram_raddr+1'b1;
	
	
end



task IR(input integer N,input	 reg	[31:0]	IR_r);
begin	
	// @(posedge TCK);
		// TMS<=1'b0;
		// TAP<=RUN_TEST;
	@(negedge TCK);
		TMS<=1'b1;
		TAP<=SELECT_DR_SCAN;
	@(negedge TCK);
		TMS<=1'b1;
		TAP<=SELECT_IR_SCAN;
	@(negedge TCK);
		TMS<=1'b0;
		TAP<=CAPTURE_IR;
	@(negedge TCK);
		TMS<=1'b0;
		TAP<=SHIFT_IR;
	repeat(N-1) begin	
	@(negedge TCK);
		TDI<=IR_r[0];
		IR_r<={1'b0,IR_r[31:1]};
	end
	
	@(negedge TCK);
		TDI<=IR_r[0];
		IR_r<={1'b0,IR_r[31:1]};
		
		TMS<=1'b1;
		TAP<=EXIT_1_IR;
	@(negedge TCK);
		TMS<=1'b1;
		TAP<=UPDATE_IR;		
	@(negedge TCK);
		TMS<=1'b0;
		TAP<=RUN_TEST;
end
endtask


task DR(input	integer M,input reg	[95:0]	DATAIN,input reg	[95:0]	DATAOUT);
begin
	@(negedge TCK);
		TMS<=1'b1;
		TAP<=SELECT_DR_SCAN;
	@(negedge TCK);
		TMS<=1'b0;
		TAP<=CAPTURE_DR;
	@(negedge TCK);
		TMS<=1'b0;
		TAP<=SHIFT_DR;
	repeat(M-1) begin
		@(negedge TCK);
		TDI<=DATAIN[0];
		DATAIN<={1'b0,DATAIN[95:1]};
		
		TDO<=DATAOUT[0];
		DATAOUT<={1'b0,DATAOUT[95:1]};
	end
	@(negedge TCK);
		TDI<=DATAIN[0];
		DATAIN<={1'b0,DATAIN[95:1]};
		
		TDO<=DATAOUT[0];
		DATAOUT<={1'b0,DATAOUT[95:1]};
		
		TMS<=1'b1;
		TAP<=EXIT_1_DR;
	@(negedge TCK);
		TMS<=1'b1;
		TAP<=UPDATE_DR;
	@(negedge TCK);
		TMS<=1'b0;
		TAP<=RUN_TEST;



end
endtask
	
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
	
//interrupt 
	.INT				(INT),
	
//ram
	.ram_we			 (ram_we	)	,
	.ram_waddr               (ram_waddr  )    ,
	.ram_wdata               (ram_wdata  )
	
);	
	
ram_32x512 ram (
  .clka(sclk), // input clka
  .wea(ram_we), // input [3 : 0] wea
  .addra(ram_waddr), // input [31 : 0] addra
  .dina(ram_wdata), // input [31 : 0] dina
  .clkb(sclk), // input clkb
  .addrb(ram_raddr), // input [31 : 0] addrb
  .doutb(ram_rdata) // output [31 : 0] doutb
);	


endmodule 