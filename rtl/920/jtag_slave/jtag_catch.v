

module jtag_catch(
//global signals
	input	wire		sclk,
	input	wire		reset,
	
//JTAG signals
	input	wire		TCK,
	input	wire		TMS,
	input	wire		TDI,
	input	wire		TDO,

//register signals
	input	wire	[1:0]	enable_register_i,
	output	reg				int_register_o=1'b0,
	output	reg		[7:0]	IR_register='d0,
	output	reg		[15:0]	DATALEN_register_o='d0,
	input	wire			clear_int_i,
	output	reg		[7:0]	IRLEN_register='d0,
	
//interrupt 
	output	reg			INT=1'b0,
	
//ram
	output	reg				ram_we,
	output	reg		[8:0]	ram_waddr='d0,
	output	reg		[31:0]	ram_wdata='d0
	
	

	
);


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
	UPDATE_IR='hf,
	
	IDLE = 'h10;
	

reg	 [4:0]	state=IDLE;

reg			TCK_r;
wire	tck_pos;


reg	[31:0]	TDI_reg='d0;
reg	[31:0]	TDO_reg='d0;

reg	[5:0]	data_cnt='d0;
reg	[9:0]	dword_cnt='d0;	
reg	[7:0]	ir_cnt='d0;

reg		ram_1_done=1'b0,ram_2_done=1'b0;
// reg	[9:0]	ram_waddr='d0;
reg		[8:0]	tdi_addr='d0,tdo_addr='h80;


always@(posedge sclk)
	TCK_r<=TCK;
	
assign tck_pos=TCK&&~TCK_r;



//fsm
always@(posedge sclk)
	if(reset)
		state<=IDLE;
	else case(state)
		IDLE:begin	
				data_cnt<='d0;
				dword_cnt<='d0;
				ir_cnt<='d0;
			if(enable_register_i[0])
				state<=TEST_LOGIC_RESET;
		
			
			
			
			
		end
	
		TEST_LOGIC_RESET:begin
			if(tck_pos&&TMS==1'b0)
				state<=RUN_TEST;
		end
		
		RUN_TEST:begin
				data_cnt<='d0;
				dword_cnt<='d0;
				ir_cnt<='d0;
			if(tck_pos&&TMS)
				state<=SELECT_DR_SCAN;
		end
		
		SELECT_DR_SCAN:begin
			if(tck_pos&&TMS==1'b0)
				state<=CAPTURE_DR;
			else if(tck_pos&&TMS)
				state<=SELECT_IR_SCAN;
		
		end
		
		CAPTURE_DR:begin
			if(tck_pos&&TMS==1'b0)
				state<=SHIFT_DR;
			else if(tck_pos&&TMS)
				state<=EXIT_1_DR;
		end
		
		SHIFT_DR:begin
			if(tck_pos&&TMS)
				state<=EXIT_1_DR;
				
			if(tck_pos)
			begin
				data_cnt<=data_cnt+1'b1;
				TDI_reg[data_cnt]<=TDI;
				TDO_reg[data_cnt]<=TDO;
				if(data_cnt=='d31) begin
					dword_cnt<=dword_cnt+1'b1;
					data_cnt<='d0;
				end
			end
			
			if(ram_1_done)
				TDI_reg<='d0;
			if(ram_2_done)
				TDO_reg<='d0;
			
		end
		
		EXIT_1_DR:begin
			if(tck_pos&&TMS==1'b0)
				state<=PAUSE_DR;
			else if(tck_pos&&TMS)
				state<=UPDATE_DR;
		end
		
		PAUSE_DR:begin
			if(tck_pos&&TMS)
				state<=EXIT_2_DR;
		end
		
		EXIT_2_DR:begin
			if(tck_pos&&TMS)
				state<=UPDATE_DR;
			else if(tck_pos&&TMS==1'b0)
				state<=SHIFT_DR;
		end
		
		UPDATE_DR:begin
			if(tck_pos&&TMS)
				state<=SELECT_DR_SCAN;
			else if(tck_pos&&TMS==1'b0)
				state<=RUN_TEST;
				
			DATALEN_register_o<={dword_cnt[9:0],data_cnt[0+:5]};	
		end
		
		SELECT_IR_SCAN:begin
			if(tck_pos&&TMS)
				state<=TEST_LOGIC_RESET;
			else if(tck_pos&&TMS==1'b0)
				state<=CAPTURE_IR;
		end
		
		CAPTURE_IR:begin
			if(tck_pos&&TMS)
				state<=EXIT_1_IR;
			else if(tck_pos&&TMS==1'b0)
				state<=SHIFT_IR;
			
		end
		
		SHIFT_IR:begin
			if(tck_pos&&TMS)
				state<=EXIT_1_IR;
				
			if(tck_pos) begin
				TDI_reg[ir_cnt]<=TDI;
				TDO_reg[ir_cnt]<=TDO;
				
				// TDI_reg<={TDI,TDI_reg[31:1]};
				// TDO_reg<={TDO,TDO_reg[31:1]};
				
				ir_cnt<=ir_cnt+1'b1;
			end	
				
		end
	
		EXIT_1_IR:begin
			if(tck_pos&&TMS)
				state<=UPDATE_IR;
			else if(tck_pos&&TMS==1'b0)
				state<=PAUSE_IR;
		end
		
		PAUSE_IR:begin
			if(tck_pos&&TMS)
				state<=EXIT_2_IR;
		end
	
		EXIT_2_IR:begin
			if(tck_pos&&TMS)
				state<=UPDATE_IR;
			else if(tck_pos&&TMS==1'b0)
				state<=SHIFT_IR;
		end
		
		UPDATE_IR:begin
			if(tck_pos&&TMS)
				state<=SELECT_DR_SCAN;
			else if(tck_pos&&TMS==1'b0)
				state<=RUN_TEST;
				
			IR_register<=TDI_reg;	
			IRLEN_register<=ir_cnt;
			
		end
		
	endcase
	
	
//ram
always@(posedge sclk)
	if(state==SHIFT_DR&&data_cnt=='d31&&tck_pos)
		ram_1_done<=1'b1;
	else if(state==EXIT_1_DR&&tck_pos&&TMS)
		ram_1_done<=1'b1;
	else 
		ram_1_done<=1'b0;
	
always@(posedge sclk)
	if(ram_1_done)
		ram_2_done<=1'b1;
	else
		ram_2_done<=1'b0;
		
always@(posedge sclk)
	if(enable_register_i[0]==1'b0)
		tdi_addr<='d0;
	else if(clear_int_i)
		tdi_addr<='d0;
	else if(ram_1_done)
		tdi_addr<=tdi_addr+1'b1;
	
always@(posedge sclk)
	if(enable_register_i[0]==1'b0)
		tdo_addr<='h80;
	else if(clear_int_i)
		tdo_addr<='h80;
	else if(ram_2_done)
		tdo_addr<=tdo_addr+1'b1;	

always@(posedge sclk)
	if(ram_1_done) begin
		ram_we<=1'b1;
		ram_waddr<=tdi_addr;
		ram_wdata<=TDI_reg;
	end
	else if(ram_2_done) begin
		ram_we<=1'b1;
		ram_waddr<=tdo_addr;
		ram_wdata<=TDO_reg;
	end
	else 
		ram_we<=1'b0;

		

	
//interrupt	
always@(posedge sclk)
	if(clear_int_i) begin
		INT<=1'b0;
		int_register_o<=1'b0;
	end
	else if(enable_register_i[1]&&state==UPDATE_DR)
	begin
		INT<=1'b1;
		int_register_o<=1'b1;
	end
	
	
	
 


endmodule