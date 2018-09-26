

`timescale 1ns/1ns

module tb_top();
	reg	 sclk=1'b0;
	reg		reset=1'b0;

	
		reg		TCK=1'b0;
	reg		TMS=1'b1;
	reg		TDI=1'b0;
	reg		TDO=1'b0;

	reg	[5:0]	TAP='d0;
	
	
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
	

initial begin
	forever begin
		#5 sclk=~sclk;
	end
end

initial begin
	forever begin
		#50 TCK=~TCK;
	end
end



initial begin
	
		@(posedge sclk);
		@(posedge sclk);
		@(posedge sclk);
		@(negedge TCK);
			TMS<=1'b0;
		IR(8,32'h0000_0025);
		DR(36,36'ha_1234_5678,36'hb_1111_1111);
	
	
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







	

top top(
	.sclk		(sclk),
	.reset		(reset),
	
	.TCK		(TCK),
	.TMS		(TMS),
	.TDO		(TDO),
	.TDI		(TDI)
);	

endmodule 