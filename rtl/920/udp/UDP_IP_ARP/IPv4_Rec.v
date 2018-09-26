/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\      \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：IPv4_Rec.v
功能：
详细描述：
	IP模块的接口：
	IP收模块
写端口：
读端口：
*/
module IPv4_Rec(
//system signals
input	reset_i,
input	clk_user_i,

//mac_rx_to_ip
input			rx_mac_data_vld_i	,//rx_mac_ra
output	reg 		rx_mac_data_rd_o	,//rx_mac_rd
input		[31:0]	rx_mac_data_i		,
input		[1:0]	rx_mac_data_be_i	,//00,01,10,11  4,1,2,3  1111 1110 1100 1000
input			rx_mac_data_pa_i	,
input			rx_mac_data_sop_i	,
input			rx_mac_data_eop_i	,

//ip rx to udp
output	reg		rx_ip_data_vld_o	= 'b0,
output	reg	[31:0]	rx_ip_data_o		= 'b0,
output	reg		rx_ip_data_tlast	= 'b0,
output	reg	[3:0]	rx_ip_data_be_o		= 'b0,
input			rx_ip_data_ready_i	,

//broadcast control
output reg		BroadValid_o=1'b0	,

//control signals
input		[47:0]	our_mac_i		,
input		[31:0]	our_ip_i		,
output reg	[47:0]	SourceMac_o	= 'b0	,
output reg	[31:0]	SourceIP_o	= 'b0	,
output [127:0] debug_ip
);

reg	[4:0]	Mac_cnt		= 'b0;
reg	[47:0]	DistinationMac	= 'b0;
reg	[4:0]	HeadLength	= 'b0;
reg		Send_Flag 	= 0;//如果发来的帧不是IPv4格式的，则这个信号为0；否则为1；之后的数据继续发送
reg	[47:0]	SourceMac	= 'b0	;
reg	[31:0]	SourceIP	= 'b0	;

reg	[31:0]	DistinationIP	= 'b0;
reg	[3:0]	IP_Rec_State	= 'b0;
reg	[31:0]	DataR		= 'b0;

assign debug_ip = {'b0,
   rx_mac_data_vld_i , 
   rx_mac_data_rd_o  , 
   rx_mac_data_i     ,     
   rx_mac_data_be_i  ,
   rx_mac_data_pa_i  ,
   rx_mac_data_sop_i ,
   rx_mac_data_eop_i ,
                     
                     
   rx_ip_data_vld_o  ,
   rx_ip_data_o	     ,
   rx_ip_data_tlast  ,
   rx_ip_data_be_o   ,     
   rx_ip_data_ready_i,
   Mac_cnt, IP_Rec_State
    };


always@(posedge clk_user_i )
	if(reset_i)
		begin
		Mac_cnt <= 'd0;	
		rx_mac_data_rd_o <= 'd0;
		end
	else
	begin
		if(rx_mac_data_pa_i == 1 && rx_mac_data_eop_i == 1)
			rx_mac_data_rd_o <= 'd0; 
		else if(rx_mac_data_vld_i)
			rx_mac_data_rd_o <= 'd1; 
		else if(!rx_mac_data_vld_i)
			rx_mac_data_rd_o <= 'd0; 
		if(rx_mac_data_pa_i == 1)
			begin
			if(rx_mac_data_eop_i == 1)
				begin
				Mac_cnt <= 'd0;	
				end
			else
				begin
				if(Mac_cnt!=9)
					Mac_cnt <= Mac_cnt + 1'b1 ;
				end
			end
	end

//数据帧头解析
always@(posedge clk_user_i)
	if(reset_i)
		begin
		DistinationMac	 	<= 'd0;
		SourceMac 		<= 'd0;
		HeadLength 		<= 'd0;
		Send_Flag 		<= 'd0;	
		//SourceIP  		<= 'd0;
		DistinationIP 		<= 'd0;
		end
	else	
	begin
		if(rx_mac_data_pa_i && rx_mac_data_eop_i)Send_Flag <= 'd0;
		if(rx_mac_data_pa_i == 1)
		begin
		case(Mac_cnt)
		'd0:   begin  	DistinationMac[16+:32] 	<=  rx_mac_data_i; 
				end
		'd1:  	begin  	DistinationMac[0+:16] 	<=  rx_mac_data_i[16+:16];
				SourceMac [32+:16]	<= rx_mac_data_i[0+:16];
				end
		'd2:	begin	SourceMac [0+:32]	<= rx_mac_data_i;
				 
				end
		'd3:	begin
			if(rx_mac_data_i[12+:4]=='d4 && rx_mac_data_i[16+:16]==16'h0800)
				begin	HeadLength <= 	rx_mac_data_i[8+:4]+1;Send_Flag <= 'd1;	end
			else	Send_Flag 		<= 'd0;	
			end
		'd5:	begin
			if(rx_mac_data_i[0+:8]=='d17 && Send_Flag)   Send_Flag <= 'd1;	
			else				Send_Flag <= 'd0;	end
		'd6:
			begin
			SourceIP [16+:16]	<= 	rx_mac_data_i[0+:16];
			end
		'd7:
			begin
			SourceIP [0+:16]	<= 	rx_mac_data_i[16+:16];
			DistinationIP[16+:16]	<= 	rx_mac_data_i[0+:16];	
			end
		'd8:
			begin
			DistinationIP[0+:16]	<= 	rx_mac_data_i[16+:16];			
			end
		endcase	
		end	
		end
//数据传输
//ip rx to udp
//output		rx_ip_data_vld_o,
//output	[31:0]	rx_ip_data_o,
///output		rx_ip_data_tlast,
//output	[3:0]	rx_ip_data_be_o,
//input			rx_ip_data_ready_i,


//IP_Rec_State

always@(posedge clk_user_i)
	if(reset_i)
		begin
		IP_Rec_State 		<= 'd0;
		BroadValid_o		<=1'b0;
		end
	else  
		begin
		if(rx_mac_data_pa_i&&rx_mac_data_eop_i) BroadValid_o<=1'b0;
		else if(rx_mac_data_pa_i == 1&&Mac_cnt == 'd8 && (&DistinationMac == 1'b1 || DistinationMac!=our_mac_i)) BroadValid_o<=1'b1; 
		if(rx_mac_data_pa_i)
			DataR <=  rx_mac_data_i ;
		case(IP_Rec_State)	
		'd0:
			if( Send_Flag && ( (rx_mac_data_pa_i == 1&&Mac_cnt == 'd8 && DistinationMac == our_mac_i && {DistinationIP[16+:16],rx_mac_data_i[16+:16]} == our_ip_i )
		  	  ||(rx_mac_data_pa_i == 1&&Mac_cnt == 'd8 && (&DistinationMac == 1'b1) && (&{DistinationIP[16+:16],rx_mac_data_i[16+:16]}==1'b1) && (|SourceIP!=1'b0)) 
			))
			begin
			IP_Rec_State <= 'd1;		
			end
		'd1:
			begin
			SourceMac_o<=SourceMac;
			SourceIP_o<=SourceIP;
			if(rx_mac_data_eop_i != 'd1)
				begin
					if(rx_mac_data_pa_i) begin
						rx_ip_data_vld_o  <= 1'b1;
						rx_ip_data_o <= {DataR[0+:16],rx_mac_data_i[16+:16]};	
						IP_Rec_State <= 'd1;		
					end
					else begin
						rx_ip_data_vld_o  <= 1'b0;
						IP_Rec_State <= 'd1;		
					end
				end
			else if(rx_mac_data_eop_i == 'd1)
				begin
				//rx_mac_data_rd_o <= 1'b0;
				case(rx_mac_data_be_i)	
				2'd0://输入4byte有效；输出2byte
				begin
					rx_ip_data_vld_o  <= 1'b1;
					rx_ip_data_o <= {DataR[0+:16],rx_mac_data_i[16+:16]};	
					IP_Rec_State <= 'd2;		
					end
				2'd1:begin//输入 1byte有效；输出3byte有效
					rx_ip_data_vld_o  <= 1'b1;
					rx_ip_data_o <= {DataR[0+:16],rx_mac_data_i[24+:8],8'b0};	
					IP_Rec_State <= 'd4;	
					rx_ip_data_tlast <= 'd1;
					rx_ip_data_be_o	<= 4'b1110;	
					end
				2'd2://输入2byte 有效;输出4byte有效
				begin
					rx_ip_data_vld_o  <= 1'b1;
					rx_ip_data_o <= {DataR[0+:16],rx_mac_data_i[16+:16]};	
					IP_Rec_State <= 'd4;	
					rx_ip_data_tlast <= 'd1;
					rx_ip_data_be_o	<= 4'b1111;	
					end
				2'd3://输入3byte有效；输出1byte有效
				begin
					rx_ip_data_vld_o  <= 1'b1;
					rx_ip_data_o <= {DataR[0+:16],rx_mac_data_i[16+:16]};	
					IP_Rec_State <= 'd3;		
					end
				endcase
					
				end
			end
		'd2://输入4byte有效；输出2byte
		begin
					rx_ip_data_vld_o  <= 1'b1;
					rx_ip_data_o <= {DataR[0+:16],16'h0};	
					IP_Rec_State <= 'd4;	
					rx_ip_data_tlast <= 'd1;
					rx_ip_data_be_o	<= 4'b1100;	
					end
		
		'd3://输入3byte有效；输出1byte有效
		begin
					rx_ip_data_vld_o  <= 1'b1;
					rx_ip_data_o <= {DataR[8+:8],24'b0};	
					IP_Rec_State <= 'd4;	
					rx_ip_data_tlast <= 'd1;
					rx_ip_data_be_o	<= 4'b1000;	
					end
		'd4://
		begin
					//rx_mac_data_rd_o <= 1'b1;
					rx_ip_data_vld_o  <= 1'b0;
					rx_ip_data_o <= 'd0;
					IP_Rec_State <= 'd0;	
					rx_ip_data_tlast <= 'd0;
					rx_ip_data_be_o	<= 4'h0;	
					end
		default:
			begin
			IP_Rec_State <= 'd0;		
			end
		endcase
		end


endmodule
