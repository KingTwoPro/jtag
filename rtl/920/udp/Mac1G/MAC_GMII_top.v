/* this module includes GMII and MAC top */

module MAC_GMII_Top #(
	parameter SIM = 0	//1 for simulation
)
(
input           Reset                   ,
input           Clk_125M                ,
input           Clk_user                ,
input           Clk_reg                 ,
output  [2:0]   Speed                   ,
                //user interface 
output          Rx_mac_ra               ,
input           Rx_mac_rd               ,
output  [31:0]  Rx_mac_data             ,
output  [1:0]   Rx_mac_BE               ,
output          Rx_mac_pa               ,
output          Rx_mac_sop              ,
output          Rx_mac_eop              ,
                //user interface 
output          Tx_mac_wa               ,
input           Tx_mac_wr               ,
input   [31:0]  Tx_mac_data             ,
input   [1:0]   Tx_mac_BE               ,//big endian
input           Tx_mac_sop              ,
input           Tx_mac_eop              ,
                //pkg_lgth fifo
input           Pkg_lgth_fifo_rd        ,
output          Pkg_lgth_fifo_ra        ,
output  [15:0]  Pkg_lgth_fifo_data      ,
                //Phy GMII interface         
input 		rgmii_rxclk_i		,
input [3:0]	rgmii_rxd_i		,
input 		rgmii_rxdv_i		,
output[3:0]	rgmii_txd_o		,
output 		rgmii_txdv_o		,
output 		rgmii_txclk_o           ,
                //host interface
input           CSB                     ,
input           WRB                     ,
input   [15:0]  CD_in                   ,
output  [15:0]  CD_out                  ,
input   [7:0]   CA                      ,                
                //mdx
output          Mdo,                // MII Management Data Output
output          MdoEn,              // MII Management Data Output Enable
input           Mdi,
output          Mdc                      // MII Management Data Clock       
, output [127:0] debug_wire
, input clk125_90
);

wire           Gtx_clk                 ;//used only in GMII mode
wire           Rx_clk                  ;
wire           Tx_clk                  ;//used only in MII mode
wire           Tx_er                   ;
wire           Tx_en                   ;
wire   [7:0]   Txd                     ;
wire           Rx_er                   ;
wire           Rx_dv                   ;
wire   [7:0]   Rxd                     ;
wire           Crs = 1'b0              ;
wire           Col = 1'b0              ;

//assign debug_wire = {'b0, rgmii_rxdv_i, rgmii_rxd_i, Rx_clk, Rx_dv, Rxd};
assign debug_wire = {'b0, Gtx_clk, Tx_en, Txd};

MAC_top_1g mac_top(
	//system signals
	.Reset              (Reset             )     ,
	.Clk_125M           (Clk_125M          )     ,
	.Clk_user           (Clk_user          )     ,
	.Clk_reg            (Clk_reg           )     ,
	.Speed              (Speed             )     ,
	//user interface    //user interface 
	.Rx_mac_ra          (Rx_mac_ra         )     ,
	.Rx_mac_rd          (Rx_mac_rd         )     ,
	.Rx_mac_data        (Rx_mac_data       )     ,
	.Rx_mac_BE          (Rx_mac_BE         )     ,
	.Rx_mac_pa          (Rx_mac_pa         )     ,
	.Rx_mac_sop         (Rx_mac_sop        )     ,
	.Rx_mac_eop         (Rx_mac_eop        )     ,
	//user interface     
	.Tx_mac_wa          (Tx_mac_wa         )     ,
	.Tx_mac_wr          (Tx_mac_wr         )     ,
	.Tx_mac_data        (Tx_mac_data       )     ,
	.Tx_mac_BE          (Tx_mac_BE         )     ,//big endian
	.Tx_mac_sop         (Tx_mac_sop        )     ,
	.Tx_mac_eop         (Tx_mac_eop        )     ,
	//pkg_lgth fifo     
	.Pkg_lgth_fifo_rd   (Pkg_lgth_fifo_rd  )     ,
	.Pkg_lgth_fifo_ra   (Pkg_lgth_fifo_ra  )     ,
	.Pkg_lgth_fifo_data (Pkg_lgth_fifo_data)     ,
	//Phy interface         
	.Gtx_clk            (Gtx_clk)     ,//used only in GMII mode
	.Rx_clk             (Rx_clk )     ,
	.Tx_clk             (Tx_clk )     ,//used only in MII mode
	.Tx_er              (Tx_er  )     ,
	.Tx_en              (Tx_en  )     ,
	.Txd                (Txd    )     ,
	.Rx_er              (Rx_er  )     ,
	.Rx_dv              (Rx_dv  )     ,
	.Rxd                (Rxd    )     ,
	.Crs                (Crs    )     ,
	.Col                (Col    )     ,
	//host interface     
	.CSB                (CSB    )     ,
	.WRB                (WRB    )     ,
	.CD_in              (CD_in  )     ,
	.CD_out             (CD_out )     ,
	.CA                 (CA     )     ,                
	//mdx               
	.Mdo                (Mdo   ), // MII Management Data Output
	.MdoEn              (MdoEn ), // MII Management Data Output Enable
	.Mdi                (Mdi    ),
	.Mdc                (Mdc    )      // MII Management Data Clock       

);                       


GMII2RGMII #(
	.SIM(SIM)	//set 1 for simulation
) gmii_top
(
	//system signals
	.clk125_i(Clk_125M), 
	.reset_i(Reset),
	//GMII
	.Gtx_clk_i    (Gtx_clk)             ,//used only in GMII mode
	.Rx_clk_o     (Rx_clk)             ,
	.Tx_er_i      (Tx_er)             ,
	.Tx_en_i      (Tx_en)             ,
	.Txd_i        (Txd)             ,
	.Rx_er_o      (Rx_er)             ,
	.Rx_dv_o      (Rx_dv)             ,
	.Rxd_o        (Rxd)             ,
	
	.rgmii_rxclk_i(rgmii_rxclk_i)		,
	.rgmii_rxd_i  (rgmii_rxd_i  )  	,
	.rgmii_rxdv_i (rgmii_rxdv_i )  	,
	.rgmii_txd_o  (rgmii_txd_o  )  	,
	.rgmii_txdv_o (rgmii_txdv_o )  	,
	.rgmii_txclk_o(rgmii_txclk_o)
	, .clk125_90(clk125_90)
);


endmodule
