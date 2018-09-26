/*                 
                                                     ///+++\\\\     
                                                     |||     \\\     \\\          ///  
                                                      \\\             \\\        ///    
                                                       \\\+++\\\      \\\      ///   
                                                              \\\       \\\    ///    
                                                      \\\     |||        \\\  ///     
                                                       \\\+++///          \\\///        
                            
   
FPGA主站项目：arbiter.v
功能：
详细描述：
	
写端口：
读端口：
*/

module	Arbiter(

//system signals
input		reset_i,
input		clk_user_i,

//ip tx to arbiter
input		tx_ip_req_i,
output		reg	tx_ip_gnt_o= 'b0,
input		tx_ip_data_vld_i,
output		reg	tx_ip_data_ready_o= 'b0,
input	[31:0]	tx_ip_data_i,
input	[3:0]	tx_ip_data_be_i,
input		tx_ip_data_tlast_i,

//arp tx to arbiter
input		tx_arp_req_i,
output		reg	tx_arp_gnt_o= 'b0,
input		tx_arp_data_vld_i,
output		reg	tx_arp_data_ready_o= 'b0,
input	[31:0]	tx_arp_data_i,
input	[3:0]	tx_arp_data_be_i,
input		tx_arp_data_tlast_i,

//from the other mac
input		TxReq_i,
output reg 	TxGnt_o,
input		TxDataVld_i,
input [35:0]	TxData_i,
input [3:0]	TxDataTkeep_i,
input		TxDataTlast_i,
output		TxDataRdy_o,

//arbiter	tx to mac
input		Tx_mac_wa,
output		reg	Tx_mac_wr = 'b0,
output	reg[31:0] 	Tx_mac_data= 'b0,
output	reg[1:0] 	Tx_mac_BE= 'b0,
output		reg	Tx_mac_sop= 'b0,
output		reg	Tx_mac_eop= 'b0

);
reg	[4:0]	ArbState = 'b0;
reg 	[31:0] DataR='h0;
assign TxDataRdy_o = Tx_mac_wa;
always@(posedge clk_user_i)  begin
	if(reset_i) begin
		tx_ip_gnt_o <= 'd0; tx_arp_gnt_o<=1'b0; TxGnt_o<=1'b0;
		ArbState <= 'd0;
	end
	else	begin
		case(ArbState)
			'd0: begin
				if(tx_ip_req_i) begin
					tx_ip_gnt_o<=1'b1; ArbState<='d3;
				end
				else begin
					ArbState<='d1;
				end
			end
			'd1: begin
				if(tx_arp_req_i) begin
					tx_arp_gnt_o<=1'b1; ArbState<='d10;
				end
				else begin
					ArbState<='d23;
				end
			end
			'd23: begin
				if(TxReq_i) begin
					TxGnt_o<=1'b1; ArbState<='d24;
				end
				else begin
					ArbState<='d0;
				end
			end
			'd24: begin
				TxGnt_o<=1'b0; 
				Tx_mac_BE<=TxDataTkeep_i[2:1];
				Tx_mac_sop<=TxDataTkeep_i[0];
				Tx_mac_eop<=TxDataTlast_i;
				if(TxDataVld_i && Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; Tx_mac_data<=TxData_i; 
				end
				else if(!Tx_mac_wa)begin
					Tx_mac_wr<=1'b0; ArbState<='d25; 
				end
				else if(Tx_mac_wr && Tx_mac_eop) begin
					ArbState<='d0; Tx_mac_wr<=1'b0;
				end
			end
			'd25: begin
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; Tx_mac_data<=TxData_i; 
				end
				else begin
					Tx_mac_wr<=1'b0;  
				end
				Tx_mac_BE<=TxDataTkeep_i[2:1];
				Tx_mac_sop<=TxDataTkeep_i[0];
				Tx_mac_eop<=TxDataTlast_i;
				if(Tx_mac_wr && Tx_mac_eop) begin
					ArbState<='d0; Tx_mac_wr<=1'b0;
				end
			end
			'd3: begin	//start to send IP data
				tx_ip_gnt_o<=1'b0; 
				if(Tx_mac_wa) begin
					tx_ip_data_ready_o<=1'b1; ArbState<='d4;
				end
			end
			'd4: begin
				if(tx_ip_data_vld_i) begin
					tx_ip_data_ready_o<=Tx_mac_wa; 
					if(!Tx_mac_wa)
						Tx_mac_wr<=1'b0;
					else if(tx_ip_data_ready_o)
						Tx_mac_wr<=1'b1;
					if(!Tx_mac_wa) 
						Tx_mac_sop<=1'b0;
					else 
						Tx_mac_sop<=1'b1;
					if(tx_ip_data_ready_o) begin
						Tx_mac_data<=tx_ip_data_i; 
					end
					if(tx_ip_data_ready_o && Tx_mac_wa) begin
						ArbState<='d5;
					end
					else if(tx_ip_data_ready_o && !Tx_mac_wa) begin
						ArbState<='d6;
					end
				end
			end
			'd6: begin	//first sop meet low wa
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; Tx_mac_sop<=1'b1;
				end
				if(Tx_mac_wa && Tx_mac_wr) begin
					ArbState<='d21; Tx_mac_wr<=1'b0; 
					Tx_mac_sop<=1'b0;
				end
			end
			'd21: begin
				tx_ip_data_ready_o<=Tx_mac_wa; 
				if(!Tx_mac_wa) begin
					Tx_mac_wr<=1'b0;
				end
				else if(tx_ip_data_ready_o) begin
					Tx_mac_wr<=1'b1; ArbState<='d5;
				end
			end
			'd5: begin	//first sop meet continuous wa
				Tx_mac_sop<=1'b0;
				if(tx_ip_data_tlast_i)   
					tx_ip_data_ready_o<=1'b0;
				else 
					tx_ip_data_ready_o<=Tx_mac_wa; 
				if(!Tx_mac_wa)
					Tx_mac_wr<=1'b0;
				else 
					Tx_mac_wr<=1'b1;
				if(tx_ip_data_ready_o) begin
					Tx_mac_data<=tx_ip_data_i; 
				end
				if(Tx_mac_wa && tx_ip_data_tlast_i) begin
					ArbState<='d7; Tx_mac_eop<=1'b1;
					case(tx_ip_data_be_i)
						4'hf: Tx_mac_BE<=2'b00;
						4'he: Tx_mac_BE<=2'b11;
						4'hc: Tx_mac_BE<=2'b10;
						4'h8: Tx_mac_BE<=2'b01;
						default: Tx_mac_BE<=2'b00;
					endcase
				end 
				else if(!Tx_mac_wa && Tx_mac_wr && tx_ip_data_tlast_i) begin
					ArbState<='d20; 
				end
				else if(!Tx_mac_wa && !Tx_mac_wr && tx_ip_data_tlast_i) begin
					ArbState<='d17; DataR<=tx_ip_data_i; tx_ip_data_ready_o<=1'b1;
				end
			end
			'd7: begin
				ArbState<='d1; Tx_mac_eop<=1'b0; Tx_mac_wr<=1'b0;
			end
			'd17: begin
				tx_ip_data_ready_o<=1'b0;
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; ArbState<='d8;
				end
			end
			'd8: begin	//last eop due to non-continuous wa
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; ArbState<='d9;
					Tx_mac_eop<=1'b1; Tx_mac_data<=DataR;
					case(tx_ip_data_be_i)
						4'hf: Tx_mac_BE<=2'b00;
						4'he: Tx_mac_BE<=2'b11;
						4'hc: Tx_mac_BE<=2'b10;
						4'h8: Tx_mac_BE<=2'b01;
						default: Tx_mac_BE<=2'b00;
					endcase
				end
				else begin
					Tx_mac_wr<=1'b0; 
				end
			end
			'd9: begin
				Tx_mac_wr<=1'b0; Tx_mac_eop<=1'b0; ArbState<='d1;
			end
			'd20: begin
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; Tx_mac_eop<=1'b1; ArbState<='d9; 
					case(tx_ip_data_be_i)
						4'hf: Tx_mac_BE<=2'b00;
						4'he: Tx_mac_BE<=2'b11;
						4'hc: Tx_mac_BE<=2'b10;
						4'h8: Tx_mac_BE<=2'b01;
						default: Tx_mac_BE<=2'b00;
					endcase
				end
			end 
			'd10: begin	//start to send Arp data
				tx_arp_gnt_o<=1'b0; 
				if(Tx_mac_wa) begin
					tx_arp_data_ready_o<=1'b1; ArbState<='d11;
				end
			end
			'd11: begin
				if(tx_arp_data_vld_i) begin
					tx_arp_data_ready_o<=Tx_mac_wa; 
					if(!Tx_mac_wa)
						Tx_mac_wr<=1'b0;
					else if(tx_arp_data_ready_o)
						Tx_mac_wr<=1'b1;
					if(!Tx_mac_wa) Tx_mac_sop<=1'b0;
					else if (tx_arp_data_ready_o)Tx_mac_sop<=1'b1;
					if(tx_arp_data_ready_o) begin
						Tx_mac_data<=tx_arp_data_i; 
					end
					if(tx_arp_data_ready_o && Tx_mac_wa) begin
						ArbState<='d12;
					end
					else if(tx_arp_data_ready_o && !Tx_mac_wa) begin
						ArbState<='d13;
					end
				end
			end
			'd13: begin	//first sop meet low wa
				if(Tx_mac_wa) Tx_mac_wr<=1'b1;
				if(Tx_mac_wa && Tx_mac_wr) begin
					ArbState<='d22; Tx_mac_wr<=1'b0; Tx_mac_sop<=1'b0;
				end
			end
			'd22: begin
				tx_arp_data_ready_o<=Tx_mac_wa; 
				if(!Tx_mac_wa) begin
					Tx_mac_wr<=1'b0;
				end
				else if(tx_arp_data_ready_o) begin
					Tx_mac_wr<=1'b1; ArbState<='d12;
				end
			end
			'd12: begin	//first sop meet continuous wa
				Tx_mac_sop<=1'b0;
				if(tx_arp_data_tlast_i)   
					tx_arp_data_ready_o<=1'b0;
				else 
					tx_arp_data_ready_o<=Tx_mac_wa; 
				if(!Tx_mac_wa)
					Tx_mac_wr<=1'b0;
				else if(Tx_mac_wa)
					Tx_mac_wr<=1'b1;
				if(tx_arp_data_ready_o) begin
					Tx_mac_data<=tx_arp_data_i; 
				end
				if(Tx_mac_wa && tx_arp_data_tlast_i) begin
					ArbState<='d14; Tx_mac_eop<=1'b1;
					case(tx_arp_data_be_i)
						4'hf: Tx_mac_BE<=2'b00;
						4'he: Tx_mac_BE<=2'b11;
						4'hc: Tx_mac_BE<=2'b10;
						4'h8: Tx_mac_BE<=2'b01;
						default: Tx_mac_BE<=2'b00;
					endcase
				end
				else if(!Tx_mac_wa && Tx_mac_wr && tx_arp_data_tlast_i) begin
					ArbState<='d19;  
				end
				else if(!Tx_mac_wa && !Tx_mac_wr && tx_arp_data_tlast_i) begin
					ArbState<='d18; DataR<=tx_ip_data_i; tx_arp_data_ready_o<=1'b1;
				end
			end
			'd14: begin
				ArbState<='d0; Tx_mac_eop<=1'b0; Tx_mac_wr<=1'b0;
			end
			'd18: begin
				tx_arp_data_ready_o<=1'b0;
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; ArbState<='d15;
				end
			end
			'd15: begin	//last eop due to non-continuous wa
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; Tx_mac_eop<=1'b1; ArbState<='d16; Tx_mac_data<=DataR;
					case(tx_arp_data_be_i)
						4'hf: Tx_mac_BE<=2'b00;
						4'he: Tx_mac_BE<=2'b11;
						4'hc: Tx_mac_BE<=2'b10;
						4'h8: Tx_mac_BE<=2'b01;
						default: Tx_mac_BE<=2'b00;
					endcase
				end
				else begin
					Tx_mac_wr<=1'b0;
				end
			end
			'd16: begin
				Tx_mac_wr<=1'b0; Tx_mac_eop<=1'b0; ArbState<='d0;
			end
			'd19: begin
				if(Tx_mac_wa) begin
					Tx_mac_wr<=1'b1; Tx_mac_eop<=1'b1; ArbState<='d16; 
					case(tx_arp_data_be_i)
						4'hf: Tx_mac_BE<=2'b00;
						4'he: Tx_mac_BE<=2'b11;
						4'hc: Tx_mac_BE<=2'b10;
						4'h8: Tx_mac_BE<=2'b01;
						default: Tx_mac_BE<=2'b00;
					endcase
				end
			end  
			default: ArbState<='d0;
		endcase
	end
end

endmodule
