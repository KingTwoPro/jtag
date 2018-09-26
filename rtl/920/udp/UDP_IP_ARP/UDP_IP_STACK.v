/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\      \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：top
功能：
详细描述：
	 高电平复位
写端口：
读端口：
*/
module	UDP_IP_STACK(
input			reset_i			,
input			clk_user_i		,
//udp rx to usr
output			rx_usr_data_vld_o	,
output	[31:0]		rx_usr_data_o		,
output	[31:0]		rx_user_o		,
output	[3:0]		rx_usr_be_o		,
output			rx_usr_tlast_o		,
input			rx_usr_ready_i		,

//user tx to udp
input			tx_usr_data_vld_i	,
input	[31:0]		tx_usr_data_i		,	
input	[63:0]		tx_user_i		,
input	[3:0]		tx_usr_be_i		,
input			tx_usr_tlast_i		,
output			tx_usr_ready_o		,

//from mac
input	rx_mac_data_vld_i,//rx_mac_ra
output	rx_mac_data_rd_o,//rx_mac_rd
input	[31:0]	rx_mac_data_i,
input	[1:0]	rx_mac_data_be_i,
input		rx_mac_data_pa_i,
input		rx_mac_data_sop_i,
input		rx_mac_data_eop_i,

//To mac
input		Tx_mac_wa,
output	wire	Tx_mac_wr,
output	wire[31:0]	Tx_mac_data,
output	wire[1:0]	Tx_mac_BE,
output	wire	Tx_mac_sop,
output	wire	Tx_mac_eop,

input	[47:0]	our_mac_i	,  
input	[31:0]	our_ip_i	,    
input	[15:0]	our_port_i	,
input		DisableARP_i	,
output		BroadValid_o	,

//from the other mac
input		TxReq_i,
output     	TxGnt_o,
input		TxDataVld_i,
input [35:0]	TxData_i,
input [3:0]	TxDataTkeep_i,
input		TxDataTlast_i,
output		TxDataRdy_o,

//, input    [31:0]        TargetIP_i
output [127:0] debug_ip
);
wire		rx_ip_data_vld_o	;
wire	[31:0]	rx_ip_data_o		;
wire		rx_ip_data_tlast	;
wire	[3:0]	rx_ip_data_be_o		;
wire		rx_ip_data_ready_i	;

wire	             w_en                ;
wire	 [47:0]      w_mac_address       ;
wire	 [31:0]      w_ip_address        ;


wire	             reply_send_en       ;
wire	 [47:0]      reply_send_mac_addr ;
wire	 [31:0]      reply_send_ip_addr  ;

//ip to abriter
wire		tx_ip_req_o		;
wire		tx_ip_gnt_i		;
wire		tx_ip_data_vld_o	;
wire		tx_ip_data_ready_i	;
wire	[31:0]	tx_ip_data_o		;
wire	[3:0]	tx_ip_data_be_o		;
wire		tx_ip_data_tlast_o	;

wire			tx_udp_data_vld_o	;
wire	[31:0]		tx_udp_data_o		;
wire	[3:0]		tx_udp_be_o		;
wire			tx_udp_tlast_o		;
wire	[31:0]		tx_udp_tuser_o		;
wire			tx_udp_ready_i		;
                                                  
wire	             	r_en                ;   
wire	 [31:0]      	r_ip_addr           ;   
wire	 [47:0]      	r_mac_addr          ;                                                     
wire			r_e                 ; 

wire                  request_send_en     ;                                
wire      [31:0]      request_ip_addr   ;

wire		tx_arp_req_o		;
wire		tx_arp_gnt_i		;
wire		tx_arp_data_vld_o	;
wire		tx_arp_data_ready_i	;
wire	[31:0]	tx_arp_data_o		;
wire	[3:0]	tx_arp_data_be_o	;
wire		tx_arp_data_tlast_o     ;
 
//wire	            reply_send_en       ;                
//wire	[47:0]      reply_send_mac_addr ;                
//wire	[31:0]      reply_send_ip_addr  ;                

wire [47:0]	SourceMac	;
wire [31:0]	SourceIP	;
 
                                                            
IPv4_Rec	IPv4_Rec_inst(
	//system signals
	.reset_i	(reset_i	)	,
	.clk_user_i	(clk_user_i	),
	
	//mac_rx_to_ip
	.rx_mac_data_vld_i	(rx_mac_data_vld_i	),	//rx_mac_ra
	.rx_mac_data_rd_o	(rx_mac_data_rd_o	),	//rx_mac_rd
	.rx_mac_data_i		(rx_mac_data_i		),
	.rx_mac_data_be_i	(rx_mac_data_be_i	),
	.rx_mac_data_pa_i	(rx_mac_data_pa_i	),
	.rx_mac_data_sop_i	(rx_mac_data_sop_i	),
	.rx_mac_data_eop_i	(rx_mac_data_eop_i	),
	
	//ip rx to udp
	.rx_ip_data_vld_o	(rx_ip_data_vld_o	        ),
	.rx_ip_data_o		(rx_ip_data_o		        ),
	.rx_ip_data_tlast	(rx_ip_data_tlast	        ),
	.rx_ip_data_be_o	(rx_ip_data_be_o		),
	.rx_ip_data_ready_i	(rx_ip_data_ready_i	        ),
	
	//control signals
	.SourceMac_o		(SourceMac		),
	.SourceIP_o		(SourceIP		),
	.our_mac_i	 (our_mac_i	     ), 
	.our_ip_i         (our_ip_i	     ),
	.BroadValid_o		(BroadValid_o		),
	.debug_ip(debug_ip)
	);
UDP_Rec	UDP_Rec_inst(
	//system signals
	.reset_i	(reset_i	)	,
	.clk_user_i	(clk_user_i	),
	
	//ip rx to UDP
	.rx_ip_data_vld_i	(rx_ip_data_vld_o	        ),  
	.rx_ip_data_i		(rx_ip_data_o		        ),  
	.rx_ip_tlast		(rx_ip_data_tlast	        ),  
	.rx_ip_be_i		(rx_ip_data_be_o		),  
	.rx_ip_ready_o		(rx_ip_data_ready_i	        ),  
	
	//udp rx to usr
	.rx_usr_data_vld_o	(rx_usr_data_vld_o	),
	.rx_usr_data_o		(rx_usr_data_o		),
	.rx_user_o		(rx_user_o		),
	.rx_usr_be_o		(rx_usr_be_o		),
	.rx_usr_tlast_o		(rx_usr_tlast_o		),
	.rx_usr_ready_i		(rx_usr_ready_i		),
	
	//control
	.our_ip_address      (our_ip_i		     ),
	.our_mac_address     ( our_mac_i	    ),
	.our_port_i  (our_port_i      )
);

UDP_Send	UDP_Send_inst(
	//system signals
	.reset_i	(reset_i	)	,
	.clk_user_i	(clk_user_i	),
	
	
	//user tx to udp
	.tx_usr_data_vld_i	(tx_usr_data_vld_i	),
	.tx_usr_data_i		(tx_usr_data_i		),
	.tx_user_i		(tx_user_i		),
	.tx_usr_be_i		(tx_usr_be_i		),
	.tx_usr_tlast_i		(tx_usr_tlast_i		),
	.tx_usr_ready_o		(tx_usr_ready_o		),
	
	
	
	
	//udp tx to ip
	.tx_udp_data_vld_o	(tx_udp_data_vld_o	),
	.tx_udp_data_o		(tx_udp_data_o		),
	.tx_udp_be_o		(tx_udp_be_o		),
	.tx_udp_tlast_o		(tx_udp_tlast_o		),
	.tx_udp_tuser_o		(tx_udp_tuser_o		),
	.tx_udp_ready_i		(tx_udp_ready_i		),
	
	//control
	.our_port_i  (our_port_i)
	
	
);

ARP_Rec	ARP_Rec(
	//system signals
	.reset_i	(reset_i	)	,
	.clk_user_i	(clk_user_i	),
	
	//control signals
	.our_mac_i	  (our_mac_i	     ), 
	.our_ip_i         (our_ip_i	     ), 
	
	//mac_rx to ARP_Rec
	.rx_arp_data_i		(rx_mac_data_i    ),
	.rx_arp_data_be_i	(rx_mac_data_be_i  ),
	.rx_arp_data_pa_i	(rx_mac_data_pa_i  ),
	.rx_arp_data_sop_i	(rx_mac_data_sop_i ),
	.rx_arp_data_eop_i	(rx_mac_data_eop_i ),
	
	//arp_rec to mac cache
	.w_en          ( w_en          )      ,
	.w_mac_address ( w_mac_address )      ,
	.w_ip_address  ( w_ip_address  )      ,
	
	//arp_rec to mac_send 产生arp应答帧
	.reply_send_en       (reply_send_en      ),
	.reply_send_mac_addr (reply_send_mac_addr),
	.reply_send_ip_addr  (reply_send_ip_addr )
	
);

mac_cache mac_cache_inst
(
	.tx_clk(clk_user_i	) ,
	.reset (reset_i		) ,
	//from ip_send
	.target_ip_address (TargetIP_i),      
	//from arp_rec
	.w_en             ( w_en             ),
	.w_mac_address    ( w_mac_address    ),
	.w_ip_address     ( w_ip_address     ),  
	
	//from ip_send
	.r_en            (r_en        )    ,
	.r_ip_addr       (r_ip_addr   )    ,
	.r_mac_addr      (r_mac_addr  )    ,
	.r_e		(r_e         ),//当前返回值有效信号
	//to arp_send
	.request_send_en  (request_send_en)   ,
	.request_ip_addr(request_ip_addr)
);

IPv4_Send	IPv4_Send_inst(
	//system signals
	.reset_i	(reset_i	),
	.clk_user_i	(clk_user_i	),
	
	
	//ip tx to arbiter
	.tx_ip_req_o		(tx_ip_req_o		        ),//发送请求
	.tx_ip_gnt_i		(tx_ip_gnt_i		        ),//发送响应
	.tx_ip_data_vld_o	(tx_ip_data_vld_o	        ),
	.tx_ip_data_ready_i	(tx_ip_data_ready_i	        ),
	.tx_ip_data_o		(tx_ip_data_o		        ),
	.tx_ip_data_be_o	(tx_ip_data_be_o		),
	.tx_ip_data_tlast_o	(tx_ip_data_tlast_o	        ),
	
	
	//udp tx to ip
	//数据来源需要有，IP地
	.tx_udp_data_vld_i		(tx_udp_data_vld_o	),    
	.tx_udp_data_i			(tx_udp_data_o		),    
	.tx_udp_data_be_i		(tx_udp_be_o		),    
	.tx_udp_tlast_i			(tx_udp_tlast_o		),    
	.tx_udp_tuser_i			(tx_udp_tuser_o		),    
	.tx_udp_data_ready_o		(tx_udp_ready_i		),    
	
	.tx_udp_target_ip		(SourceIP		),
	
	.BroadValid_i			(DisableARP_i		),
	.SourceMac			(SourceMac		),
	
	//控制信号
	.our_mac_i	(our_mac_i	),
	.our_ip_i	(our_ip_i	),
	
	//ip to ARP lookup table
	.r_en        (r_en      ),        
	.r_ip_addr   (r_ip_addr ),        
	.r_mac_addr  (r_mac_addr),      
	.r_e         (r_e 	) 	
	
);

ARP_Send	ARP_Send(
	.reset_i	(reset_i	)	,
	.clk_user_i	(clk_user_i	),
	
	
	.our_ip_address(our_ip_i)      ,
	.our_mac_address(our_mac_i)     ,
	
	.reply_send_en       (reply_send_en      ),
	.reply_send_mac_addr (reply_send_mac_addr),
	.reply_send_ip_addr  (reply_send_ip_addr ),
	//output                  reply_ready         ,
	
	.request_send_en (request_send_en)    ,
	.request_ip_addr (request_ip_addr)    ,
	
	//arp tx to arbiter
	.tx_arp_req_o		(tx_arp_req_o		),
	.tx_arp_gnt_i		(tx_arp_gnt_i		),
	.tx_arp_data_vld_o	(tx_arp_data_vld_o	),
	.tx_arp_data_ready_i	(tx_arp_data_ready_i	),
	.tx_arp_data_o		(tx_arp_data_o		),
	.tx_arp_data_be_o	(tx_arp_data_be_o	),
	.tx_arp_data_tlast_o     (tx_arp_data_tlast_o    )
);

Arbiter	Arbiter_inst(

	//system signals
	.reset_i	(reset_i	),
	.clk_user_i	(clk_user_i	),
	
	//ip tx to arbiter
	.tx_ip_req_i		(tx_ip_req_o		        ),
	.tx_ip_gnt_o		(tx_ip_gnt_i		        ),
	.tx_ip_data_vld_i	(tx_ip_data_vld_o	        ),
	.tx_ip_data_ready_o	(tx_ip_data_ready_i	        ),
	.tx_ip_data_i		(tx_ip_data_o		        ),
	.tx_ip_data_be_i	(tx_ip_data_be_o		),
	.tx_ip_data_tlast_i	(tx_ip_data_tlast_o	        ),
	
	//arp tx to arbiter
	.tx_arp_req_i		(tx_arp_req_o		),
	.tx_arp_gnt_o		(tx_arp_gnt_i		),
	.tx_arp_data_vld_i	(tx_arp_data_vld_o	),
	.tx_arp_data_ready_o	(tx_arp_data_ready_i	),
	.tx_arp_data_i		(tx_arp_data_o		),
	.tx_arp_data_be_i	(tx_arp_data_be_o	),
	.tx_arp_data_tlast_i	(tx_arp_data_tlast_o    ),
	
	//from the other mac
	.TxReq_i		(TxReq_i	),
	.TxGnt_o		(TxGnt_o	),
	.TxDataVld_i		(TxDataVld_i	),
	.TxData_i		(TxData_i	),
	.TxDataTkeep_i		(TxDataTkeep_i	),
	.TxDataTlast_i		(TxDataTlast_i	),
	.TxDataRdy_o		(TxDataRdy_o	),
	
	//arbiter	tx to mac
	.Tx_mac_wa	(Tx_mac_wa	 ),
	.Tx_mac_wr	(Tx_mac_wr	 ),
	.Tx_mac_data	(Tx_mac_data	 ),
	.Tx_mac_BE	(Tx_mac_BE	 ),
	.Tx_mac_sop	(Tx_mac_sop	 ),
	.Tx_mac_eop      (Tx_mac_eop      )
	
);

endmodule
