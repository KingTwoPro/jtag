/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\       \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：IPv4_Send.v
功能：
详细描述：
	IP模块的接口：
	IP发送模块
写端口：
读端口：
*/
module IPv4_Send(
//system signals
input		reset_i,
input		clk_user_i,

//ip tx to arbiter
output	reg		tx_ip_req_o ='b0		,//发送请求
input			tx_ip_gnt_i		,//发送响应
output	reg		tx_ip_data_vld_o='b0	,
input			tx_ip_data_ready_i	,
output	reg 	[31:0]	tx_ip_data_o='b0		,
output	reg	[3:0]	tx_ip_data_be_o='b0		,
output	reg		tx_ip_data_tlast_o='b0	,

//udp tx to ip
//数据来源需要有，IP地址
input		tx_udp_data_vld_i	,
output	reg	tx_udp_data_ready_o	,
input	[31:0]	tx_udp_data_i		,
input	[31:0]	tx_udp_tuser_i		,
input	[3:0]	tx_udp_data_be_i	,
input		tx_udp_tlast_i		,
input	[31:0]	tx_udp_target_ip	,

input	[47:0]	SourceMac		,
input		BroadValid_i		,

//控制信号
input	[47:0]	our_mac_i,
input	[31:0]	our_ip_i,

//ip to ARP lookup table
output   reg               r_en                ,
output  reg[31:0]      	r_ip_addr           ,
input    [47:0]      	r_mac_addr          ,
input	 		r_e //当前返回值有效信号

);
reg	r_en_R= 'b0;
reg	[9:0]	IpSendState= 'b0;
reg	[31:0]	tx_udp_data_R= 'b0;
reg	[47:0]	target_mac= 'b0;
reg	[31:0]	target_ip= 'b0;
reg	[31:0] DataR0='h0, DataR1, IpCheckSum='h0;

always@(posedge clk_user_i )
	if(reset_i)
		begin
		IpSendState <= 'd0;
		tx_udp_data_ready_o <= 'd0;
		end
	else
		begin
		r_en_R <= r_en;
		case(IpSendState)	
		'd0:
			begin	//get first udp data
			tx_udp_data_ready_o <= 1'b1;
			if(tx_udp_data_vld_i && tx_udp_data_ready_o)	
			begin
				DataR0 <= tx_udp_data_i;
				IpSendState <= 'd1;
			end
		end
		'd1: begin		//get second udp data
			if(tx_udp_data_vld_i)	
			begin
				DataR1 <= tx_udp_data_i;
				IpSendState <= 'd2;
				tx_udp_data_ready_o <= 1'b0;
			end
		end
		'd2: begin
			if(!BroadValid_i) begin
				r_en    <= 1; 
				r_ip_addr <=  tx_udp_target_ip;
			end
				IpSendState <= 'd3;
				//缓存第一个数据，想
				//向mac_cache发送请求，检测当前的ip地址是否在mac_cache中
		end
			
		'd3: begin
			if(!BroadValid_i) begin
				if(r_e==1)	
					begin
					r_en    <= 0; 
					tx_ip_req_o <= 1'b1;
					target_mac <= r_mac_addr;
					target_ip <=  r_ip_addr;
					IpSendState <= 'd4;			//test only. do not buffer arp
					end
			end
			else begin
				tx_ip_req_o <= 1'b1;
				target_mac <= 48'hffff_ffff_ffff; //SourceMac;
				target_ip <=  32'hffff_ffff; //tx_udp_target_ip;
				IpSendState <= 'd4;			//test only. do not buffer arp
			end
		end	
		'd4: begin
			if(tx_ip_gnt_i==1)
				begin
				tx_ip_req_o <= 1'b0;	
				IpSendState <= 'd5;
			end
		end
		'd5: begin	//first DW
				tx_ip_data_vld_o <= 1'b1;
				tx_ip_data_o <= target_mac[16+:32];
				IpSendState <= 'd6;
				IpCheckSum<=16'h4500+tx_udp_tuser_i[0+:16]+16'd20+16'h8011+our_ip_i[0+:16]+our_ip_i[16+:16]+target_ip[0+:16]+target_ip[16+:16];//16'h40 is IP total Length
			end
		'd6:		
			begin	//second DW
			if(tx_ip_data_ready_i == 1)
				begin
				tx_ip_data_o <= {target_mac[0+:16],our_mac_i[32+:16]};
				IpSendState <= 'd7;	
				end
			if( |IpCheckSum[16+:16] == 1'b1)
				IpCheckSum<=IpCheckSum[0+:16]+IpCheckSum[16+:16];
			end
		
		'd7:
		begin	//third DW
			if(tx_ip_data_ready_i == 1)
				begin
				tx_ip_data_o <= {our_mac_i[0+:32]};
				IpSendState <= 'd8;	
				//tx_udp_data_ready_o <= 1'b1;
				end
				
			end
		'd8:
			begin	//fourth DW
			if(tx_ip_data_ready_i == 1)
				begin
				tx_ip_data_o <= {16'h0800,16'h4500};
				IpSendState <= 'd18;	
				end
			end
		'd18:
			begin	//5th DW
			if(tx_ip_data_ready_i == 1)
				begin
				tx_ip_data_o <= {tx_udp_tuser_i[0+:16]+'d20,16'h0};
				IpSendState <= 'd19;	
				end	
			end
		'd19:
			begin	//6th DW
			if(tx_ip_data_ready_i == 1)
				begin
				tx_ip_data_o <= 32'h0000_8011;
				IpSendState <= 'd20;	
				end	
				end
		
		'd20:
		begin		//7th DW
			if(tx_ip_data_ready_i == 1)
				begin
				tx_ip_data_o <= {~IpCheckSum[0+:16],our_ip_i[16+:16]};
				IpSendState <= 'd9;	
				end	
		end
		'd9:
		begin		//8th DW
			if(tx_ip_data_ready_i == 1)
				begin
				tx_ip_data_o <= {our_ip_i[0+:16],target_ip[16+:16]};
				IpSendState <= 'd10;	
				end	
		end
		'd10:
		begin		//9th DW + user data
		if(tx_ip_data_ready_i == 1)
			begin
				begin
				tx_ip_data_o <= {target_ip[0+:16],DataR0[16+:16]}; 
				IpSendState <= 'd11;	
				end
			end		
		end
		'd11:
		begin
			tx_udp_data_ready_o <= tx_ip_data_ready_i;
			if(tx_ip_data_ready_i == 1) begin
				tx_ip_data_o <= {DataR0[0+:16], DataR1[16+:16]}; 
				IpSendState <= 'd12;	
			end
		end
		'd12: begin
			tx_udp_data_ready_o <= tx_ip_data_ready_i;
			if(tx_udp_data_ready_o) begin 
				DataR1<=tx_udp_data_i;
				DataR0<=DataR1;
			end
			//if(!tx_ip_data_ready_i) begin
			//	DataR0<=tx_udp_data_i;
			//end
			if(tx_ip_data_ready_i) begin
				tx_ip_data_o <= {DataR1[0+:16], tx_udp_data_i[16+:16]}; 
			end
			if(tx_udp_data_ready_o && tx_udp_tlast_i && tx_ip_data_ready_i) begin
				IpSendState <= 'd13; tx_udp_data_ready_o<=1'b0; 
				if(tx_udp_data_be_i==4'h8) begin	//only one byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'he; tx_ip_data_tlast_o<=1'b1;
				end
				else if(tx_udp_data_be_i==4'hc) begin	//only two byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'hf; tx_ip_data_tlast_o<=1'b1;
				end
				else if(tx_udp_data_be_i==4'he) begin	//only three byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'h8;
					IpSendState <= 'd17;	
				end
				else if(tx_udp_data_be_i==4'hf) begin	//only four byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'hc;
					IpSendState <= 'd17;	
				end
			end
			else if(tx_udp_data_ready_o && tx_udp_tlast_i && !tx_ip_data_ready_i) begin
				IpSendState <= 'd15; tx_udp_data_ready_o<=1'b0;
				if(tx_udp_data_be_i==4'h8) begin	//only one byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'he; 
				end
				else if(tx_udp_data_be_i==4'hc) begin	//only two byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'hf;
				end
				else if(tx_udp_data_be_i==4'he) begin	//only three byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'h8;
				end
				else if(tx_udp_data_be_i==4'hf) begin	//only three byte. must plus 2 left bytes.
					tx_ip_data_be_o <= 4'hc;
				end
			end
			else if(!tx_ip_data_ready_i) begin
				IpSendState <= 'd16; 
			end
		end
		'd16: begin	//wait ip read assert again
			tx_udp_data_ready_o <= tx_ip_data_ready_i;
			if(tx_ip_data_ready_i) begin
				tx_ip_data_o <= {DataR0[0+:16], DataR1[16+:16]}; 
				IpSendState <= 'd12; 
			end
		end
		'd15: begin	//gen last for non-continous case
			if(tx_ip_data_ready_i) begin
				tx_ip_data_o <= {DataR0[0+:16], DataR1[16+:16]}; 
				if(tx_ip_data_be_o==4'hf) begin	//only one byte. must plus 2 left bytes.
					tx_ip_data_tlast_o<=1'b1;
					IpSendState <= 'd13; 
				end
				else if(tx_ip_data_be_o==4'he) begin	//only two byte. must plus 2 left bytes.
					tx_ip_data_tlast_o<=1'b1;
					IpSendState <= 'd13; 
				end
				else if(tx_ip_data_be_o==4'h8) begin	//only three byte. must plus 2 left bytes.
					IpSendState <= 'd17; 
				end
				else if(tx_ip_data_be_o==4'hc) begin	//only three byte. must plus 2 left bytes.
					IpSendState <= 'd17; 
				end
			end
		end
		'd17: begin	//last 2 bytes
			if(tx_ip_data_ready_i) begin
				tx_ip_data_o <= {DataR1[0+:16], 16'h0}; 
				tx_ip_data_tlast_o<=1'b1; 
				IpSendState <= 'd13; 
			end
		end
		'd13: begin
			if(tx_ip_data_ready_i) begin
				tx_ip_data_tlast_o<=1'b0; tx_ip_data_vld_o<=1'b0; 
				IpSendState <= 'd0; 
			end
		end
		default:IpSendState <= 'd0;	
	endcase	
end

endmodule
