

module udp_top
#(
	parameter OURMAC=48'd0,
	parameter	OURIP=32'd0,
	parameter	OURPORT=16'd0
)
(
	input	wire	sclk,
	input	wire	reset,
	
	input 		rgmii_rxclk_i		,
	input [3:0]	rgmii_rxd_i		,
	input 		rgmii_rxdv_i		,
	output[3:0]	rgmii_txd_o		,
	output 		rgmii_txdv_o		,
	output 		rgmii_txclk_o           ,

	
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
	output			tx_usr_ready_o		

);


wire			rx_mac_ra				;//rx_mac_ra
wire			rx_mac_rd			;//rx_mac_rd
wire	[31:0]	rx_mac_data				;
wire	[1:0]	rx_mac_data_be	;
wire			rx_mac_data_pa	;
wire			rx_mac_data_sop	;
wire			rx_mac_data_eop	;


wire			Tx_mac_wa				;
wire			Tx_mac_wr			      ;
wire[31:0]		Tx_mac_data	            ;
wire[1:0]		Tx_mac_BE	                  ;
wire			Tx_mac_sop	                  ;
wire			Tx_mac_eop	                  ;

wire		Mdi;
wire		Mdo;
wire		MdoEn;
wire    	Mdc, MDIO;

UDP_IP_STACK  UDP(
.reset_i						(reset),
.clk_user_i					(sclk),
//udp rx to usr
.rx_usr_data_vld_o			(rx_usr_data_vld_o	),
.rx_usr_data_o				(rx_usr_data_o		),
.rx_user_o					(rx_user_o			),
.rx_usr_be_o				(rx_usr_be_o		),
.rx_usr_tlast_o				(rx_usr_tlast_o		),
.rx_usr_ready_i				(rx_usr_ready_i		),
//		                              (		                  )
//		                              (		                  )
.tx_usr_data_vld_i			(tx_usr_data_vld_i	),
.tx_usr_data_i				(tx_usr_data_i		),	
.tx_user_i					(tx_user_i			),
.tx_usr_be_i					(tx_usr_be_i			),
.tx_usr_tlast_i				(tx_usr_tlast_i		),
.tx_usr_ready_o				(tx_usr_ready_o		),

//from mac
.rx_mac_data_vld_i			(rx_mac_ra		),
.rx_mac_data_rd_o 			(rx_mac_rd		),
.rx_mac_data_i 	                  (rx_mac_data		),
.rx_mac_data_be_i 	            (rx_mac_data_be	),
.rx_mac_data_pa_i 	            (rx_mac_data_pa	),
.rx_mac_data_sop_i 	            (rx_mac_data_sop),
.rx_mac_data_eop_i 	            (rx_mac_data_eop),

//To mac
.Tx_mac_wa 				(Tx_mac_wa	),
.Tx_mac_wr 		                  (Tx_mac_wr	),
.Tx_mac_data 		            (Tx_mac_data),
.Tx_mac_BE 		                  (Tx_mac_BE	),
.Tx_mac_sop 		            (Tx_mac_sop	),
.Tx_mac_eop 		            (Tx_mac_eop	),

.our_mac_i					(OURMAC),  
.our_ip_i					(OURIP),    
.our_port_i					(OURPORT),
.DisableARP_i				(1'b0),
.BroadValid_o				()

// from the other mac
// input		TxReq_i,
// output     	TxGnt_o,
// input		TxDataVld_i,
// input [35:0]	TxData_i,
// input [3:0]	TxDataTkeep_i,
// input		TxDataTlast_i,
// output		TxDataRdy_o,

//, input    [31:0]        TargetIP_i
// output [127:0] debug_ip
);


MAC_GMII_Top 
(
.Reset               			(1'b0)   ,
.Clk_125M          			(sclk)      ,
.Clk_user           			(sclk)    ,
.Clk_reg             			(sclk)    ,
.Speed               			()    ,
                //user interface 
.Rx_mac_ra         			(rx_mac_ra		)     ,
.Rx_mac_rd         			(rx_mac_rd		)     ,
.Rx_mac_data      			(rx_mac_data		)      ,
.Rx_mac_BE         			(rx_mac_data_be	)      ,
.Rx_mac_pa         			(rx_mac_data_pa	)      ,
.Rx_mac_sop       			(rx_mac_data_sop)      ,
.Rx_mac_eop       			(rx_mac_data_eop)      ,
                //user interface 
.Tx_mac_wa          			(Tx_mac_wa	)     ,
.Tx_mac_wr           			(Tx_mac_wr	)    ,
.Tx_mac_data        			(Tx_mac_data)     ,
.Tx_mac_BE          			(Tx_mac_BE	)    ,//big endian
.Tx_mac_sop         			(Tx_mac_sop	)     ,
.Tx_mac_eop         			(Tx_mac_eop	)     ,
                //pkg_lgth fifo
.Pkg_lgth_fifo_rd      			(1'b1)  ,
.Pkg_lgth_fifo_ra      			()  ,
.Pkg_lgth_fifo_data  			()   ,
                //Phy GMII interface         
.rgmii_rxclk_i				(rgmii_rxclk_i	)	,
.rgmii_rxd_i					(rgmii_rxd_i	),
.rgmii_rxdv_i				(rgmii_rxdv_i	)	,
.rgmii_txd_o					(rgmii_txd_o	),
.rgmii_txdv_o				(rgmii_txdv_o)	,
.rgmii_txclk_o    			      (rgmii_txclk_o  ),
                //host interface
.CSB            				(1'b1)       ,
.WRB           				()        ,
.CD_in         				()         ,
.CD_out       				()          ,
.CA              				()      ,                
                //mdx
.Mdo           					(Mdo  ),   // MII Management Data Output
.MdoEn        				(MdoE),	    // MII Management Data Output Enable
.Mdi					      (Mdi),
.Mdc           					(Mdc  )         // MII Management Data Clock       
);

endmodule