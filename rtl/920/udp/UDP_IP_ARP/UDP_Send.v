module 		UDP_Send(
//system signals
input			reset_i			,
input			clk_user_i		,


//user tx to udp
input				tx_usr_data_vld_i	,
input		[31:0]		tx_usr_data_i		,//用户数据
input		[63:0]		tx_user_i		,//用户参数（目标ip，目标port口）
input		[3:0]		tx_usr_be_i		,
input				tx_usr_tlast_i		,
output		reg		tx_usr_ready_o		= 'd1,

//udp tx to ip
output	reg			tx_udp_data_vld_o	= 'd0,
input				tx_udp_ready_i		,
output	reg	[31:0]		tx_udp_data_o		= 'd0,
output	reg	[31:0]		tx_udp_tuser_o		= 'd0,//用户参数（目标ip，目标port口）changed to length of UDP
output	reg	[3:0]		tx_udp_be_o		= 'd0,
output	reg			tx_udp_tlast_o		= 'd0,


//output		[31:0]	tx_udp_target_ip,
//control
input	[15:0]		our_port_i
);

reg [5:0] St;
reg [31:0] DataR0, DataR1;

always @(posedge clk_user_i) begin
	if(reset_i) begin
		St<=0; tx_usr_ready_o<=1'b0; tx_udp_data_vld_o<=1'b0; tx_udp_tlast_o<=1'b0;
	end
	else begin
		case(St)
			'h0: begin	//check if usr valid is high
				tx_usr_ready_o<=1'b1; 
				if(tx_usr_data_vld_i) begin
					DataR0<=tx_usr_data_i; St<='h2;
				end
			end
			'h1: begin	//store first data
				DataR0<=tx_usr_data_i; St<='h2;
			end
			'h2: begin	//store second data
				DataR1<=DataR0; DataR0<=tx_usr_data_i; St<='h3; tx_usr_ready_o<=1'b0;
			end
			'h3: begin	//output UDP header
				tx_udp_data_vld_o<=1'b1; tx_udp_data_o <= {tx_user_i[16+:16],tx_user_i[0+:16]}; tx_udp_tuser_o[0+:16] <=tx_user_i[48+:16]+'d8; St<='h4;
			end
			'h4: begin
				if(tx_udp_ready_i) begin
					St<='h8;
					tx_udp_data_o <= {'d8+tx_user_i[48+:16],16'h00};//user 数据长度 
				end
			end
			'h8: begin
				if(tx_udp_ready_i) begin
					St<='h9;
					tx_udp_data_o <= DataR1; 
				end
			end
			'h9: begin
				tx_usr_ready_o<=tx_udp_ready_i;
				if(tx_udp_ready_i) begin
					St<='h5;
					tx_udp_data_o <= DataR0; 
				end
			end
			'h5: begin
				tx_usr_ready_o<=tx_udp_ready_i;  
				if(tx_udp_ready_i) begin
					tx_udp_data_o<=tx_usr_data_i;
				end
				if(!tx_udp_ready_i) begin
					DataR0<=tx_usr_data_i;
				end
				if(tx_usr_ready_o && tx_usr_tlast_i && tx_udp_ready_i) begin
					St<='ha; tx_udp_tlast_o<=1'b1; tx_udp_be_o<=tx_usr_be_i; tx_usr_ready_o<=1'b0;
				end
				else if(tx_usr_ready_o && tx_usr_tlast_i && !tx_udp_ready_i) begin
					St<='h7; tx_usr_ready_o<=1'b0; tx_udp_be_o<=tx_usr_be_i; 
				end
				else if(!tx_udp_ready_i) begin
					St<='h6; 
				end
			end
			'h6: begin
				tx_usr_ready_o<=tx_udp_ready_i;  
				if(tx_udp_ready_i) begin
					tx_udp_data_o<=DataR0; St<='h5;
				end
			end
			'h7: begin
				if(tx_udp_ready_i) begin
					St<='ha;tx_udp_data_o<=DataR0; tx_udp_tlast_o<=1'b1; 
				end
			end
			'ha: begin
				if(tx_udp_ready_i) begin
					tx_udp_tlast_o<=1'b0; tx_udp_data_vld_o<=1'b0; St<='h0;
				end
			end
			default: St<='h0;
		endcase
	end
end

endmodule
