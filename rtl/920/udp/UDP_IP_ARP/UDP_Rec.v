/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\      \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：UDP_Rec.v
功能：
详细描述：
	
写端口：
读端口：
*/

module UDP_Rec(
//system signals
input			reset_i,
input			clk_user_i,

//ip rx to UDP
input			rx_ip_data_vld_i,
input	[31:0]		rx_ip_data_i,
input	[3:0]		rx_ip_be_i,// 1111 1110 1100 1000
input			rx_ip_tlast,
output	reg		rx_ip_ready_o= 'b0,

//udp rx to usr
output	reg			rx_usr_data_vld_o= 'b0,
output	reg	[31:0]		rx_usr_data_o= 'b0,
output	reg	[31:0]		rx_user_o= 'b0,
output	reg	[3:0]		rx_usr_be_o= 'b0,
output	reg			rx_usr_tlast_o= 'b0,
input				rx_usr_ready_i,

//control
input       [31:0]      our_ip_address      ,
input       [47:0]      our_mac_address     ,
input	    [15:0]		our_port_i
);
reg	[15:0]	SourcePort= 'b0;
reg	[15:0]	DestiPort= 'b0;
reg	[15:0]	Rx_user_o= 'b0;
reg	[9:0]	UDP_Rec_State= 'b0;
//rx_ip_ready_o
always@(posedge clk_user_i )
	if(reset_i)
		begin
		rx_ip_ready_o <= 'd0;	
		end
	else
		rx_ip_ready_o <= 'd1;		

//UDP REC
always@(posedge clk_user_i )
	if(reset_i)
		begin
		UDP_Rec_State <= 'd0;
		end
	else	
		begin
		case(UDP_Rec_State)
			'd0:
				begin
				if(rx_ip_data_vld_i)
					begin
					SourcePort 	<= rx_ip_data_i[16+:16] ;
					DestiPort	<= rx_ip_data_i[0+:16] ;
					rx_user_o	<= rx_ip_data_i ;
					UDP_Rec_State	<= 'd1;	
					end
				else
					UDP_Rec_State	<= 'd0;		
				end
			'd1:
				begin
				if(rx_ip_data_vld_i)
					begin
					Rx_user_o 	<= rx_ip_data_i[16+:16] ;//UDP头+数据长度
					UDP_Rec_State	<= 'd2;	
					end
				else
					UDP_Rec_State	<= 'd1;			
				end
			'd2:
				begin
				if(rx_ip_data_vld_i)	
					begin
					if(rx_ip_tlast != 1'b1)	//不是最后一个数据
						begin	
						rx_usr_data_vld_o 	<= 1'b1;                
						rx_usr_data_o 		<= rx_ip_data_i;	
						UDP_Rec_State	<= 'd2;	
						end
					else if(rx_ip_tlast == 1'b1)//最后一个数据
						begin
						rx_usr_data_vld_o 	<= 1'b1;
						rx_usr_data_o 		<= rx_ip_data_i;	
						UDP_Rec_State		<= 'd3;		
						rx_usr_tlast_o		<= 'd1;	
						rx_usr_be_o		<= rx_ip_be_i;
						end
						
					end
				else begin
					rx_usr_data_vld_o 	<= 1'b0;
				end
			end
			'd3:
				begin
						rx_usr_data_vld_o 	<=0;
						rx_usr_data_o 		<= 'b0;	
						UDP_Rec_State	<= 'd0;		
						rx_usr_tlast_o	<= 'd0;		
					        rx_usr_be_o	<= 'd0;		
					
				end
			default:
					UDP_Rec_State	<= 'd0;		
		endcase	
		end

endmodule
