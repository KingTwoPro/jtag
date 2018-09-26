/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\      \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：ARP.v
功能：
详细描述：
	
写端口：
读端口：
*/
module	ARP(
	//system signals
input		reset_i,
input		clk_user_i,

//control signals
input		[47:0]	our_mac_i,
input		[31:0]	our_ip_i,

//mac_rx to arp
input		[31:0]	rx_arp_data_i,
input		[1:0]	rx_arp_data_be_i,
input			rx_arp_data_pa_i,
input			rx_arp_data_sop_i,
input			rx_arp_data_eop_i,

//arp tx to abriter
output			tx_arp_req_o,
input			tx_arp_gnt_i,
output			tx_arp_data_wld_o,
input			tx_arp_data_ready_i,
output		[31:0]	tx_arp_data_o,
output		[3:0]	tx_arp_data_be_o,
output			tx_arp_data_tlast_o,

//arp to ip
input			IpArpReq_i,
input		[47:0]	TargetIp_i,
output			ArpIpGnt_o,
output			ArpIpStatus_o
);


endmodule