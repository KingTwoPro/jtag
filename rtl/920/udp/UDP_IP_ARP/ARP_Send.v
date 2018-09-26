/*         
FPGA主站项目：
功能：
详细描述：
	ARP  缓存模块
写端口：
读端口：
*/

module ARP_Send(
	//system signals
input				reset_i,
input				clk_user_i,
		
input		[31:0]	our_ip_address      	,
input		[47:0]	our_mac_address     	,
		
input			reply_send_en       	,
input		[47:0]	reply_send_mac_addr 	,
input		[31:0]	reply_send_ip_addr  	,
output	      		reply_ready      	,

input                   request_send_en     ,
input       	[31:0]	request_ip_addr     ,

//arp tx to arbiter
output	reg		tx_arp_req_o		,
input			tx_arp_gnt_i		,
output	reg		tx_arp_data_vld_o	,
input			tx_arp_data_ready_i	,
output	reg	[31:0]	tx_arp_data_o		,
output	reg	[3:0]	tx_arp_data_be_o	= 'hc,
output	reg		tx_arp_data_tlast_o 
);

reg         [2 :0]      arp_tx_state       = 'b0 ;
reg         [2 :0]      nxt_arp_tx_state   = 'b0 ;
reg         [7 :0]      tx_cnt             = 'b0 ;
wire                    reply_send_end      	;
wire                    request_send_end   	;

localparam ARP_PACKAGE_LENGTH = 16          ;

localparam  IDLE            = 3'd0;
localparam  REPLY           = 3'd1;
localparam  REPLY_PRE       = 3'd2;
localparam  REQUEST         = 3'd3;
localparam  REQUEST_PRE     = 3'd4;


assign  reply_ready = (arp_tx_state == IDLE) ? 1'b1 : 1'b0;

/*****************************************************************************************

******************************************************************************************/
always@(posedge clk_user_i )
if(reset_i)begin
	arp_tx_state <= IDLE;
	end
else	begin
//tx_arp_req_o <= 1'b0;
    case(arp_tx_state)
        IDLE:
            begin
                if(reply_send_en == 1'b1)
                    begin
                    	tx_arp_req_o <= 1'b1;
                    	arp_tx_state <= REPLY_PRE;
                    end
                else if(request_send_en == 1'b1)
                    begin
                    tx_arp_req_o <= 1'b1;
                    arp_tx_state <= REQUEST_PRE;  
            	end 
                else
                    arp_tx_state <= IDLE;
            end
        REQUEST_PRE :
        	begin	
        	if(tx_arp_gnt_i)
        		begin
			tx_arp_req_o <= 1'b0;
			arp_tx_state <= REQUEST;  
				end
        	end   
       REPLY_PRE:   
            begin
        	if(tx_arp_gnt_i)
		begin
			tx_arp_req_o <= 1'b0;
        		arp_tx_state <= REPLY;  
			end			
        	end  
        REQUEST:
            begin
                if(request_send_end == 1'b1)
                    arp_tx_state <= IDLE;   
                else
                    arp_tx_state <= REQUEST;
            end
        REPLY:
            begin
                if(reply_send_end == 1'b1)
                    arp_tx_state <= IDLE;   
                else
                    arp_tx_state <= REPLY;
            end        
        default:
            arp_tx_state <= IDLE;
    endcase                                  
end    
always@(posedge clk_user_i )
begin
   if(reset_i) 
        tx_cnt <= 8'd0;
    else if((arp_tx_state == REPLY)||(arp_tx_state == REQUEST) &&tx_arp_data_ready_i) 
        tx_cnt <= tx_cnt + 'd1;
    else if((arp_tx_state == REPLY)||(arp_tx_state == REQUEST) &&tx_arp_data_ready_i=='d0) 
        tx_cnt <= tx_cnt ;
    else
        tx_cnt <= 8'd0;       
end

assign reply_send_end = ((tx_cnt == ARP_PACKAGE_LENGTH-1)&&(arp_tx_state == REPLY)) ? 1'b1 : 1'b0;
assign request_send_end = ((tx_cnt == ARP_PACKAGE_LENGTH-1)&&(arp_tx_state == REQUEST)) ? 1'b1 : 1'b0;

always@(posedge clk_user_i )
begin
  if(reset_i) 
        begin
        //    arp_mac_tx_tfirst <= 1'b0;
            tx_arp_data_tlast_o <= 1'b0;
            tx_arp_data_vld_o<= 1'b0;
        end
    else if(((arp_tx_state == REPLY)||(arp_tx_state == REQUEST)) &&tx_arp_data_ready_i)
        begin       
            if(tx_cnt=='d0)//第一个数据
                begin
          //          arp_mac_tx_tfirst <= 1'b1;
                    tx_arp_data_tlast_o <= 1'b0;
                    tx_arp_data_vld_o<= 1'b1;
                end
            else if((tx_cnt > 8'd0)&&(tx_cnt < ARP_PACKAGE_LENGTH-'d1))//中间一个数据
                begin
             //       arp_mac_tx_tfirst <= 1'b0;
                    tx_arp_data_tlast_o <= 1'b0;
                    tx_arp_data_vld_o<= 1'b1;
                end
            else if(tx_cnt == ARP_PACKAGE_LENGTH-1'b1)//最后一个数据
                begin
              //      arp_mac_tx_tfirst <= 1'b0;
                    tx_arp_data_tlast_o <= 1'b1;
                    tx_arp_data_vld_o<= 1'b1;
                end
            else
                begin
              //      arp_mac_tx_tfirst <= 1'b0;
                    tx_arp_data_tlast_o <= 1'b0;
                    tx_arp_data_vld_o<= 1'b0;
                end
        end
    else
        begin
         //   arp_mac_tx_tfirst <= 1'b0;
           tx_arp_data_tlast_o <= 1'b0;
            tx_arp_data_vld_o<= 1'b0;
        end                              
end

always@(posedge clk_user_i )
begin
  if(reset_i) 
        tx_arp_data_o <= 'd0;
    else if(arp_tx_state == REPLY)
        begin
            case(tx_cnt)
                'd0:  tx_arp_data_o <= reply_send_mac_addr[16+:32];  
                'd1:  tx_arp_data_o <= {reply_send_mac_addr[0+:16],our_mac_address[32+:16]};
                'd2:  tx_arp_data_o <= our_mac_address[0+:32];
                'd3:  tx_arp_data_o <= 32'h08060001;
                'd4:  tx_arp_data_o <= 32'h08000604;
                'd5:  tx_arp_data_o <= {16'h0002,our_mac_address[32+:16]};
                'd6:  tx_arp_data_o <=	our_mac_address[0+:32];
                'd7:  tx_arp_data_o <= our_ip_address;
                'd8:  tx_arp_data_o <= reply_send_mac_addr[16+:32];
                'd9:  tx_arp_data_o <= {reply_send_mac_addr[0+:16],reply_send_ip_addr[16+:16]};
        	'd10: tx_arp_data_o <= {reply_send_ip_addr[0+:16],16'h0};
                default: tx_arp_data_o <= 32'h00;
            endcase
        end
    else if(arp_tx_state == REQUEST)
        begin
        	 case(tx_cnt)
                'd0:  tx_arp_data_o <= 32'hFFFFFFFF;  
                'd1:  tx_arp_data_o <= {16'hffff,our_mac_address[32+:16]};
                'd2:  tx_arp_data_o <= our_mac_address[0+:32];
                'd3:  tx_arp_data_o <= 32'h08060001;
                'd4:  tx_arp_data_o <= 32'h08000604;
                'd5:  tx_arp_data_o <= {16'h0001,our_mac_address[32+:16]};
                'd6:  tx_arp_data_o <=our_mac_address[0+:32];
                'd7:  tx_arp_data_o <= our_ip_address;
                'd8:  tx_arp_data_o <= 32'h0;
                'd9:  tx_arp_data_o <= {16'h0,request_ip_addr[16+:16]};
        	'd10: tx_arp_data_o <= {request_ip_addr[0+:16],16'h0};
                default: tx_arp_data_o <= 32'h00;
            endcase
        end    
    else
        tx_arp_data_o <= 32'h00;             
end


assign arp_mac_req = reply_send_en|request_send_en;


endmodule
