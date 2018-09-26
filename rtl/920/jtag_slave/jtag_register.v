

module jtag_register(

	input	wire		sclk,
	input	wire		reset,
	
//axilite
	input	wire	[31:0]	s_axi_awaddr_i,
	input	wire			s_axi_awvalid_i,
	output	reg				s_axi_awready_o=1'b1,
	                                    
	input	wire	[31:0]	s_axi_wdata_i,
	input	wire			s_axi_wvalid_i,
	input	wire	[3:0]	s_axi_wstrb_i,
	output	reg				s_axi_wready_o=1'b0,
	                                    
	output	reg		[1:0]	s_axi_bresp_o=2'd0,
	output	reg				s_axi_bvalid_o=1'b0,
	input	wire			s_axi_bready_i,
	                                    
	input	wire	[31:0]	s_axi_araddr_i,
	input	wire			s_axi_arvalid_i,
	output	reg				s_axi_arready_o=1'b1,
	                                    
	output	reg		[31:0]	s_axi_rdata_o,
	output	reg				s_axi_rvalid_o=1'b0,
	input	wire			s_axi_rready_i,
	output	reg		[1:0]	s_axi_rresp_o=2'd0,

//reg
	output	reg	[1:0]	enable_register_o='d0,
	input	wire				int_register_i,
	input	wire		[7:0]	IR_register_i,
	input	wire		[15:0]	DATALEN_register_i,
	output	reg					clear_int_o=1'b0,
	input	wire		[7:0]	IRLEN_register,
	
//ram
	output	reg		[8:0]	ram_raddr,
	input	wire	[31:0]	ram_rdata
	
);


localparam
	INTERRUPT_ENABLE = 16'h0000,
	INTERRUPT_STATUS = 16'h0004,
	IR_REGISTER = 16'h0008,
	DATLEN_REGISTER = 16'h000c;
	

reg		[3:0]	state='h0;
reg		[15:0]	addr='d0;

always@(posedge sclk)
	if(reset) begin
		state<='h0;
		
	end
	else case(state)
		'h0:begin
		
		
			
			s_axi_awready_o<=1'b1;
			s_axi_arready_o<=1'b1;
			if(s_axi_awvalid_i&&s_axi_awready_o)
			begin
				s_axi_awready_o<=1'b0;
				s_axi_arready_o<=1'b0;
				addr<=s_axi_awaddr_i[0+:16];
				
				state<='h1;
			end
			
			else if(s_axi_arvalid_i&&s_axi_arready_o)
			begin
				s_axi_awready_o<=1'b0;
				s_axi_arready_o<=1'b0;
				addr<=s_axi_araddr_i[0+:16];
				// ram_raddr<=s_axi_araddr_i[0+:16]-16'h0400;
				state<='h3;
			end
		end
	
		'h1:begin
			s_axi_wready_o<=1'b1;
			if(s_axi_wvalid_i&&s_axi_wready_o)
			begin
				s_axi_wready_o<=1'b0;
				state<='h2;
				case(addr)
					INTERRUPT_ENABLE: enable_register_o<=s_axi_wdata_i[1:0];
				endcase
				
			end
		end
		
		'h2:begin
			s_axi_bvalid_o<=1'b1;
			if(s_axi_bvalid_o&&s_axi_bready_i)
			begin
				s_axi_bvalid_o<=1'b0;
				state<='h0;
			end
			
		end
		
		'h3:begin
			s_axi_rvalid_o<=1'b1;
			if(addr==INTERRUPT_ENABLE)	s_axi_rdata_o<=enable_register_o;
				
			else if(addr==INTERRUPT_STATUS)	begin s_axi_rdata_o<=int_register_i; clear_int_o<=1'b1; end
				
			else if(addr==IR_REGISTER)	 s_axi_rdata_o<=IR_register_i;
				
			else if(addr==DATLEN_REGISTER)  s_axi_rdata_o<={IRLEN_register,DATALEN_register_i};
				
			else if(addr>=16'h0400)	 s_axi_rdata_o<= ram_rdata;
			
			
		
			if(s_axi_rvalid_o&&s_axi_rready_i)
			begin
				clear_int_o<=1'b0;
				
				s_axi_rvalid_o<=1'b0;
				state<='h0;
			end
			
		end
		
	
	endcase

// always@(posedge sclk)
	// if(addr>=16'h0400&&addr<=16'h0800)
		// ram_raddr<=addr-16'h0400;

// always@(*)
	// if(addr>=16'h0400&&addr<=16'h0800)
		// ram_raddr<=addr[9:0]>>2;
	// else 
		// ram_raddr<=ram_raddr;
		
always@(*)
	if(s_axi_arvalid_i&&s_axi_arready_o)
		ram_raddr<=s_axi_araddr_i[0+:10]>>2;
	else 
		ram_raddr<=ram_raddr;
		
		
endmodule 