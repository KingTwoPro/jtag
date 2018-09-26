/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\      \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：
功能：
详细描述：
	ARP  缓存模块
写端口：
读端口：
*/
module mac_cache
#
(
parameter   ARP_AGE = 60        //60s
)
(
input                   tx_clk              ,
input                   reset               ,
//from ip_send
input       [31:0]      target_ip_address   ,
//from arp_rec
input                   w_en                ,
input       [47:0]      w_mac_address       ,
input       [31:0]      w_ip_address        ,  

//from ip_send
input                   r_en                ,
input       [31:0]      r_ip_addr           ,
output reg  [47:0]      r_mac_addr  = 'h0   ,
output	reg		r_e = 'b0,//当前返回值有效信号
//to arp_send
output   reg	               request_send_en  = 'b0     ,
output   reg  [31:0]      request_ip_addr = 'h0
);

//====================写端口
reg [2:0] addr= 'b0;
reg	w_en_R;
always @(posedge tx_clk )
begin
	w_en_R <= (reset)? 1'b0 : w_en;
end
always@(posedge tx_clk)
	begin
	 if(reset == 1'b1)
	 addr <= 'd0;
	 else if(w_en == 1'b0 && w_en_R == 1'b1)//下降沿增加地址
	 addr <= addr + 1'b1;
	 end
	 
	 
//===================读端口：
reg	[7:0]	read_state;
reg	[2:0]	read_addr = 'h0;
wire	[80:0]	read_data;
always@	 (posedge tx_clk)
	begin
		if(reset == 1'b1) begin
			read_state <= 'd0; r_e <= 1'b0;
		end
		else	
		case(read_state)
		'd0:
			begin
			if(r_en)
				read_state <= 'd1;
			else
				read_state <= 'd0;
			end
		'd1:
			begin
			read_addr <= 'd0;
			read_state <= 'd2;
			end 
		'd2:
			begin
			if(read_addr!=3'b000 && read_data[80]==1'b1 && read_data [48+:32] ==r_ip_addr) begin
				r_mac_addr <= read_data[0+:48];
			end
			if(read_addr!=3'b000 && read_data[80]==1'b1 && read_data [48+:32] ==r_ip_addr) 
				read_state <= 'd3;//找到了
			else if(read_addr == 3'b111)
				read_state <= 'd7;	//没找到
			read_addr <= read_addr + 1'b1;
			end 
		'd3:
			begin
			
			r_e <= 1'b1;
			read_state <= 'd5;//轮询
			end
		
		'd4:
			begin
			request_send_en <= 1'b1;
			request_ip_addr <= r_ip_addr;
			read_state <= 'd6;
			end
			
		'd5:
			begin
			read_state <= 'd0;//轮询
			r_e <= 1'b0;
			end
		
		'd6:
			begin
			request_send_en <= 1'b0;
			if(w_en == 1 && w_ip_address == r_ip_addr )
				begin
				r_mac_addr <= w_mac_address;
				r_e <= 1'b1;
				read_state <= 'd5;//轮询
				
				end
			
			end

		'd7: begin 	//add one state due to latency
			if(read_data[80]==1'b1 && read_data [48+:32] ==r_ip_addr) begin
				read_state <= 'd3;//找到了
				r_mac_addr <= read_data[0+:48];
			end
			else begin
				read_state <= 'd4;
			end
		end 
			
		default:
			read_state <= 'd0;
		endcase
	end
			
Bram8dx80b_2port	SLAVE_INFO_0(
	.clka(tx_clk),
	.wea(w_en //&& SlaveInfo_WbAddr_i[24+:8]==NUMBER_0
	),
	.addra(addr),
	.dina({1'b1,w_ip_address,w_mac_address}),
	
	.clkb(tx_clk),
	.addrb(read_addr),
	.doutb(read_data)
);	
endmodule
