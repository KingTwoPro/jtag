/* this is top module including rmii2mii and 100M mac. */

module Mac_rmii_top (
                //system signals
input           Reset                   ,
input           Clk_125M                ,
input           Clk_user                ,
input           Clk_reg                 ,
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
                //Phy interface          
input		rmii_ref_clk 		,
input		rmii_rx_err_i		,
input [1:0]	rmii_rxd_i		,
input 		rmii_rxdv_i		,
output[1:0]	rmii_txd_o		,
output 		rmii_txdv_o		,
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

);

wire        Rx_clk                  ;
wire        Tx_clk                  ;//used only in MII mode
wire        Tx_er                   ;
wire        Tx_en                   ;
wire[7:0]   Txd                     ;
wire        Rx_er                   ;
wire        Rx_dv                   ;
wire[7:0]   Rxd                     ;
wire        Crs                     ;
wire        Col                     ;

wire        Ref_clk_div  	    ;
wire [31:0] rmii_debug;
assign debug_wire = {rmii_debug, Ref_clk_div, Tx_en, Txd, rmii_rxdv_i, rmii_rxd_i, Rx_clk, Rx_dv, Rxd};
//													22			21		13			12				10			9			8	   0
MAC_top_mii mac_mii_top (
                //system signals
.Reset                  (Reset                  ) ,
.Clk_125M               (Clk_125M               ) ,
.Clk_user               (Clk_user               ) ,
.Clk_reg                (Clk_reg                ) ,
.Speed                  (Speed                  ) ,
//user interface         //user interface 
.Rx_mac_ra              (Rx_mac_ra              ) ,
.Rx_mac_rd              (Rx_mac_rd              ) ,
.Rx_mac_data            (Rx_mac_data            ) ,
.Rx_mac_BE              (Rx_mac_BE              ) ,
.Rx_mac_pa              (Rx_mac_pa              ) ,
.Rx_mac_sop             (Rx_mac_sop             ) ,
.Rx_mac_eop             (Rx_mac_eop             ) ,
//user interface         //user interface 
.Tx_mac_wa              (Tx_mac_wa              ) ,
.Tx_mac_wr              (Tx_mac_wr              ) ,
.Tx_mac_data            (Tx_mac_data            ) ,
.Tx_mac_BE              (Tx_mac_BE              ) ,//big endian
.Tx_mac_sop             (Tx_mac_sop             ) ,
.Tx_mac_eop             (Tx_mac_eop             ) ,
//pkg_lgth fifo          //pkg_lgth fifo
.Pkg_lgth_fifo_rd       (Pkg_lgth_fifo_rd       ) ,
.Pkg_lgth_fifo_ra       (Pkg_lgth_fifo_ra       ) ,
.Pkg_lgth_fifo_data     (Pkg_lgth_fifo_data     ) ,
//Phy interface         (//Phy interface         ) 
//Phy interface         (//Phy interface         )
.Gtx_clk                (                       ) ,//used only in GMII mode
.Rx_clk                 (Rx_clk                 ) ,
.Tx_clk                 (Tx_clk                 ) ,//used only in MII mode
.Tx_er                  (Tx_er                  ) ,
.Tx_en                  (Tx_en                  ) ,
.Txd                    (Txd                    ) ,
.Rx_er                  (Rx_er                  ) ,
.Rx_dv                  (Rx_dv                  ) ,
.Rxd                    (Rxd                    ) ,
.Crs                    (Crs                    ) ,
.Col                    (Col                    ) ,
//host interface        //host interface
.CSB                    (CSB                    ) ,
.WRB                    (WRB                    ) ,
.CD_in                  (CD_in                  ) ,
.CD_out                 (CD_out                 ) ,
.CA                     (CA                     ) ,                
//mdx                   //mdx
.Mdo			(Mdo			),                // MII Management Data Output
.MdoEn			(MdoEn			),              // MII Management Data Output Enable
.Mdi			(Mdi			),
.Mdc			(Mdc			),                      // MII Management Data Clock       
.Ref_clk_div_i		(Ref_clk_div  		)
);


MII2RMII rmii2mii
(
//system signals
.clk125_i	(Clk_125M	)			, 
.reset_i	(Reset  	)			,
//MII            /MII
.Rx_clk_o       (Rx_clk         )           ,
.Tx_clk_o	(Tx_clk		)	  ,
.Tx_er_i        (Tx_er          )           ,
.Tx_en_i        (Tx_en          )           ,
.Txd_i          (Txd            )           ,
.Rx_er_o        (Rx_er          )           ,
.Rx_dv_o        (Rx_dv          )           ,
.Rx_crs_o	(Rx_crs  	)	  ,
.Rxd_o          (Rxd            )           ,
//RMII           /RMII
.rmii_ref_clk 	(rmii_ref_clk 	)	,
.rmii_rx_err_i	(rmii_rx_err_i	)	,
.rmii_rxd_i	(rmii_rxd_i	)	,
.rmii_rxdv_i	(rmii_rxdv_i	)	,
.rmii_txd_o	(rmii_txd_o	)	,
.rmii_txdv_o	(rmii_txdv_o	)	,
//div clk        /div clk
.Ref_clk_div_o	(Ref_clk_div	)
, .rmii_debug(rmii_debug)
);

endmodule


