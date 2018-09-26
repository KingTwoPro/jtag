/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\      \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：ARP_Rec.v
功能：判断ARP帧，存储MAC/IP地址
详细描述：
	
写端口：
读端口：
*/
module	ARP_Rec(
	//system signals
input		reset_i,
input		clk_user_i,

//control signals
input		[47:0]	our_mac_i,
input		[31:0]	our_ip_i,

//mac_rx to ARP_Rec
input		[31:0]	rx_arp_data_i,
input		[1:0]	rx_arp_data_be_i,
input			rx_arp_data_pa_i,
input			rx_arp_data_sop_i,
input			rx_arp_data_eop_i,

//arp_rec to mac cache
output  reg             w_en           = 'b0 ,
output  reg [47:0]      w_mac_address  = 48'h00_21_CC_6D_35_96 ,
output  reg [31:0]      w_ip_address   = 32'hc0a80003   ,

//arp_rec to mac_send 产生arp应答帧
output  reg             reply_send_en  = 'b0     ,
output  reg [47:0]      reply_send_mac_addr = 'b0,
output  reg [31:0]      reply_send_ip_addr  = 'b0

);
reg	[10:0]	Arp_Cnt = 'b0;//接收数据的计数器
reg	[10:0]	Arp_rec_state= 'b0;//帧头解析状态寄存器

reg	    [15:0]	FTYPE		= 'b0	;//帧类型
reg         [15:0]      HTYPE            = 'b0   ;    // 硬件类型    
reg         [15:0]      PTYPE           = 'b0    ;    // 协议类型
reg         [15:0]      OPER           = 'b0     ;    // ARP帧类型
reg         [7 :0]      HLEN            = 'b0    ;    //  硬件地址长度
reg         [7 :0]      PLEN           = 'b0     ;    //   协议地址长度
reg         [47:0]      SHA            = 'b0     ;    //  源MAC
reg         [47:0]      THA             = 'b0    ;    //   目标MAC
reg         [31:0]      SPA            = 'b0     ;    //   源IP
reg         [31:0]      TPA             = 'b0    ;    //   目标IP
reg                     set_outputs     = 'b0    ;    //是否传送给mac_che或者是否发送响应包

reg         [47:0]      BMAC		= 'h0	 ;	//broad mac. should be all FF.

always@(posedge clk_user_i )
	if(reset_i)
		begin
		Arp_Cnt <= 'd0;	
		end
	else
	begin
		if(rx_arp_data_pa_i == 1)
			begin
			if(rx_arp_data_eop_i == 1)
				Arp_Cnt <= 'd0;	
			else
				Arp_Cnt <= Arp_Cnt + 1'b1 ;			
			end
	end



//arp帧的解析
always@(posedge clk_user_i)
	if(reset_i)
		begin
		BMAC <= 'h0;
		FTYPE<= 'd0;
		HTYPE<= 'd0;
		PTYPE<= 'd0;
		HLEN <= 'd0;
		PLEN <= 'd0;
		OPER <= 'd0;
		SHA  <= 'd0;
		SPA  <= 'd0;
		THA  <= 'd0;
		TPA  <= 'd0;
		set_outputs 	<= 1'b0;
		end
	else	begin
		set_outputs <= 1'b0;
		if(rx_arp_data_pa_i == 1)
		begin
		case(Arp_Cnt)
			'd0:begin	BMAC[16+:32] <=rx_arp_data_i; end 
			'd1:begin	BMAC[0+:16] <=rx_arp_data_i[16+:16]; end 
			'd3:begin 	FTYPE	 <= rx_arp_data_i[16+:16];	
					HTYPE <= rx_arp_data_i[0+:16];	 end
			'd4:begin
				PTYPE <= rx_arp_data_i[16+:16];  // 协议类型
 				HLEN  <= rx_arp_data_i[8+:8];  //  硬件地址长度
				PLEN   <= rx_arp_data_i[0+:8];  //   协议地址长度
				end
			'd5:
			     begin
			     	OPER <= rx_arp_data_i[16+:16]; 
			     	SHA[32+:16] <= rx_arp_data_i[0+:16]; 
				end
			'd6:begin
			     	SHA[0+:32] <= rx_arp_data_i; 
				end
			'd7:
				begin
				SPA<= rx_arp_data_i;		
				end
			'd8:
				begin
				THA[16+:32]	<= rx_arp_data_i;		
				end
			
			'd9:
				begin	
				THA[0+:16]	<= rx_arp_data_i[16+:16];	
				TPA[16+:16]	<= rx_arp_data_i[0+:16];
				end
			
			'd10:
				begin	
				TPA[0+:16]	<= rx_arp_data_i[16+:16];
				set_outputs 	<= 1'b1;
				end
			default:
				set_outputs 	<= 1'b0;
		endcase	
			
		end
	end
//

always@(posedge clk_user_i)
	if(reset_i)
        begin
            reply_send_en <= 1'b0;
            w_en    <= 1'b0;
            w_mac_address <= 48'd0;
            w_ip_address <= 32'd0;
            reply_send_mac_addr <= 48'd0;
            reply_send_ip_addr <= 32'd0;
        end     
    else
        begin
            if(set_outputs == 1'b1)//如果arp协议应答帧的目的地址是our_ip
                begin 
                    if((OPER == 16'd1) && (&BMAC==1'b1) && (TPA == our_ip_i))
                        begin//请求包
                            reply_send_en <= 1'b1;
                            reply_send_mac_addr <= SHA;
                            reply_send_ip_addr <= SPA;
                            w_en <= 1'b1;
                            w_mac_address <= SHA;
                            w_ip_address <= SPA;
                        end
                    else if((OPER == 16'd2)&&(TPA == our_ip_i) && (BMAC == our_mac_i))
                        begin//应答包
                            w_en <= 1'b1;
                            w_mac_address <= SHA;
                            w_ip_address <= SPA;
                        end
                end
            else
                begin
                    w_en <= 1'b0;
                    reply_send_en <= 1'b0;
                end
        end                                                                                                                          

		
		
		
endmodule
