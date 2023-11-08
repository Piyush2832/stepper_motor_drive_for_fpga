///////////////////////////////////////////////////////////////////////////////
// Description: SPI (Serial Peripheral Interface) Slave
//              Creates slave based on input configuration.
//              Receives a byte one bit at a time on MOSI
//              Will also push out byte data one bit at a time on MISO.  
//              Any data on input byte will be shipped out on MISO.
//              Supports multiple bytes per transaction when CS_n is kept 
//              low during the transaction.
//
// Note:        i_Clk must be at least 4x faster than i_SPI_Clk
//              MISO is tri-stated when not communicating.  Allows for multiple
//              SPI Slaves on the same interface.
//
// Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
//              Can be configured in one of 4 modes:
//              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
//             
///////////////////////////////////////////////////////////////////////////////



// first 32 bit data :-  FF00FF00
// second 32 bit data :-  03FF02FF
// third 32 bit data :-   01FF00FF                                                  

 module SPI_Slave
  #(parameter CLKS_PER_BIT = 104)
  (
   // Control/Data Signals,
   input                i_Rst_L,    // FPGA Reset
   input                i_Clk,      // FPGA Clock
   output reg           o_RX_DV,    // Data Valid pulse (1 clock cycle)
   output reg   [7:0]   o_RX_Byte,  // Byte received on MOSI
   output reg           o_TX_sent,  // Pulse when byte TX done
//	input i_Tx_DV,   // push for data
//	output      o_Tx_Active,
//   output reg  o_Tx_Serial,
//   output      o_Tx_Done,

	output reg pulses,
	output reg puls_in,
	output reg pulses_x,
	output reg pulses_y,
   output reg pin1,
   output reg pin2,
	output reg pin1y,
   output reg pin2y,
	output reg pin1x,
   output reg pin2x,
   input E_STOP,
	input pb_gpiox,
	input pb_gpioy,
	input pb_gpioz,
	output reg gpio_pin,
   input dead_end,
   input dead_endx,
   input dead_endy,
   // SPI Interface
   input      i_SPI_Clk, 
   output     o_SPI_MISO,
   input      i_SPI_MOSI,
   input      i_SPI_CS_n,
	output [7:0] out1, 
	output reg ackn
   );
	
  wire i_TX_DV;
  wire [7:0] i_TX_Byte;
  // SPI Interface (All Runs at SPI Clock Domain)
  wire w_CPOL;     // Clock polarity
  wire w_CPHA;     // Clock phase
  wire w_SPI_CLK;  // Inverted/non-inverted depending on settings
  wire w_SPI_MISO_Mux;
  reg [95:0] data_out;
  reg [95:0] data_store;
  reg dir;
  
  assign out1 = data_out[7:0];
  
  reg [31:0] cntr;
  reg flag = 0;
  reg [3:0] data_check = 4'b0000;
  reg [7:0] first8 = 0;
  reg [7:0] second8 = 0;
  reg [7:0] third8 = 0;
  reg [7:0] fourth8 = 0;
  reg [7:0] fifth8 = 0;
  reg [7:0] sixth8 = 0;
  reg [7:0] seventh8 = 0;
  reg [7:0] eighth8 = 0;
  reg [7:0] ninth8 = 0;
  reg [7:0] tenth8 = 0;
  reg [7:0] eleven8 = 0;
  reg [7:0] twelve8 = 0;
		
  reg [2:0] r_RX_Bit_Count;
  reg [2:0] r_TX_Bit_Count;
  reg [2:0] old_r_TX_Bit_Count;
  reg [7:0] r_Temp_RX_Byte;
  reg [7:0] r_RX_Byte;
  reg r_RX_Done, r2_RX_Done, r3_RX_Done;
  reg [7:0] r_TX_Byte;
  reg r_SPI_MISO_Bit, r_Preload_MISO;
  reg stopp = 0;
  reg stoppx = 0;
  reg stoppy = 0;

  
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
  parameter SPI_MODE = 0;
  
  reg [2:0]    r_SM_Main     = 0;
  reg [15:0]    r_Clock_Count = 0;
  reg [3:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Tx_Data     = 0;
  reg          r_Tx_Done     = 0;
  reg          r_Tx_Active   = 0;
  reg [1:0] data_checks = 0;
 
  reg [23:0] counter1;
  reg [23:0] counter2;
  
  
  
reg stopx =0;
reg stopy =0;
reg stop =0;

reg [31:0] cnt;
reg [31:0] cntx;
reg [31:0] cnty;

reg [31:0] dist1;
reg [31:0] dist2 = 0;
reg [31:0] dist3 = 0;

reg [31:0] dist1y;
reg [31:0] dist1x;

reg [31:0] dist2y = 0;
reg [31:0] dist2x = 0;

reg [31:0] dist3x = 0;
reg [31:0] dist3y = 0;


reg [23:0] int_rpm;
reg [23:0] int_rpmy;
reg [23:0] int_rpmx;

reg [15:0] rpm = 30;
reg [15:0] rpmy = 30;
reg [15:0] rpmx = 30;

reg [15:0] distx = 0;
reg [15:0] disty = 0;
reg [15:0] dist = 0;

reg [15:0] pulse_rate = 400;

reg [23:0] counterx = 0;
reg [23:0] countery = 0;
reg [23:0] counter = 0;

reg togglex = 1;
reg toggley = 1;
reg toggle = 1;

reg [23:0] storex;
reg [23:0] storey;
reg [23:0] store;  

  
  
  /*ila_0  myila(.clk(i_Clk),.probe0(o_SPI_MISO),.probe1(r_Temp_RX_Byte),.probe2(r_RX_Byte),.probe3(i_TX_Byte),
  .probe4(r_TX_Byte), .probe5(i_TX_Byte),.probe6(old_r_TX_Bit_Count),.probe7(r_TX_Bit_Count),
  .probe8(i_Rst_L),.probe9(r_RX_Byte),.probe10(i_SPI_Clk),.probe11(i_SPI_MOSI),.probe12(i_SPI_CS_n),
  .probe13(r_RX_Done),.probe14(r2_RX_Done),.probe15(r3_RX_Done),
  .probe16(o_RX_DV),.probe17(i_TX_DV),.probe18(r_RX_Done),.probe19(o_TX_sent));
   */
  // CPOL: Clock Polarity
  // CPOL=0 means clock idles at 0, leading edge is rising edge.
  // CPOL=1 means clock idles at 1, leading edge is falling edge.
  assign w_CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);

  // CPHA: Clock Phase
  // CPHA=0 means the "out" side changes the data on trailing edge of clock
  //              the "in" side captures data on leading edge of clock
  // CPHA=1 means the "out" side changes the data on leading edge of clock
  //              the "in" side captures data on the trailing edge of clock
  assign w_CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);

  assign w_SPI_CLK = w_CPHA ? ~i_SPI_Clk : i_SPI_Clk;
  
   
	////////////////////////////////// SPI CODE ///////////////////////////////////////
	
  
  always@(posedge i_Clk or negedge i_Rst_L) begin
		if(!i_Rst_L) begin
			data_out <= 0;
//			data_store <= 0;
		end else begin
			if(flag) begin
				data_out <= {first8,second8,third8,fourth8,fifth8,sixth8,seventh8,eighth8,ninth8,tenth8, eleven8, twelve8};
			end else begin
				data_out <= data_out;
			end
		end
  end
  
  always@(posedge i_Clk) begin
	if(!i_Rst_L) begin
		stopp = 0;
	end else begin
		if((E_STOP == 1) || (pb_gpiox == 1) || (pb_gpioy == 1) || (pb_gpioz == 1)) begin
			stopp = 1;
			stoppx = 1;
			stoppy = 1;
		end
	end
  end
  
  always@(posedge i_Clk or negedge i_Rst_L) begin
  

		if(!i_Rst_L) begin
		   flag <= 1'b0;
			data_check <= 4'b0000;
			first8 	<= 0;
			second8 <= 0;
			third8 	<= 0;
			fourth8 <= 0;
			fifth8 	<= 0;
			sixth8 	<= 0;
			seventh8 <= 0;
			eighth8 <= 0;
			ninth8 	<= 0;
			tenth8 	<= 0;
			eleven8 <= 0;
			twelve8 <= 0;
			
		end else begin
			if(r3_RX_Done == 1'b0 && r2_RX_Done == 1'b1) begin
			
				if(data_check == 4'b1011) begin
					twelve8 <= r_RX_Byte;
					flag <= 1'b1;
					//data_out <= {first8,second8,third8,fourth8,fifth8,sixth8,seventh8,eighth8,ninth8,tenth8, eleven8, twelve8};
					data_check <= 4'b0000;
				end
				
				if(data_check == 4'b1010) begin
					eleven8 <= r_RX_Byte;
					data_check <= 4'b1011;
				end
			
				if(data_check == 4'b1001) begin
					tenth8 <= r_RX_Byte;
					
					data_check <= 4'b1010;
				end
				
				if(data_check == 4'b1000) begin
					ninth8 <= r_RX_Byte;
					data_check <= 4'b1001;
				end
				
				if(data_check == 4'b0111) begin
					eighth8 <= r_RX_Byte;
					data_check <= 4'b1000;
				end
				
				if(data_check == 4'b0110) begin
					seventh8 <= r_RX_Byte;
					data_check <= 4'b0111;
				end
				
				if(data_check == 4'b0101) begin
					sixth8 <= r_RX_Byte;
					data_check <= 4'b0110;
				end
				
				if(data_check == 4'b0100) begin
					fifth8 <= r_RX_Byte;
					data_check <= 4'b0101;
				end
			
			
				if(data_check == 4'b0011) begin
					fourth8 <= r_RX_Byte;
					data_check <= 4'b0100;
				end
				
				if(data_check == 4'b0010) begin
					third8 <= r_RX_Byte;
					data_check <= 4'b0011;
				end
				
				if(data_check == 4'b0001) begin
					second8 <= r_RX_Byte;
					data_check <= 4'b0010;
				end
				
				if(data_check == 4'b0000) begin
					first8 <= r_RX_Byte;
					flag <= 1'b0;
					data_check <= 4'b0001;
				end
			end
		end
  end

  // Purpose: Recover SPI Byte in SPI Clock Domain
  // Samples line on correct edge of SPI Clock
  always @(posedge w_SPI_CLK or posedge i_SPI_CS_n)
  begin
    if (i_SPI_CS_n)
    begin
      r_RX_Bit_Count <= 0;
      r_RX_Done      <= 1'b0;
    end
    else
    begin
      r_RX_Bit_Count <= r_RX_Bit_Count + 1;

      // Receive in LSB, shift up to MSB
      r_Temp_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};
    
      if (r_RX_Bit_Count == 3'b111)
      begin
        r_RX_Done <= 1'b1;
        r_RX_Byte <= {r_Temp_RX_Byte[6:0], i_SPI_MOSI};
      end
      else if (r_RX_Bit_Count == 3'b010)
      begin
        r_RX_Done <= 1'b0;        
      end

    end // else: !if(i_SPI_CS_n)
  end // always @ (posedge w_SPI_Clk or posedge i_SPI_CS_n)

  // Purpose: Cross from SPI Clock Domain to main FPGA clock domain
  // Assert o_RX_DV for 1 clock cycle when o_RX_Byte has valid data.
  always @(posedge i_Clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      r2_RX_Done <= 1'b0;
      r3_RX_Done <= 1'b0;
      o_RX_DV    <= 1'b0;
      o_RX_Byte  <= 8'h00;
    end
    else
    begin
      // Here is where clock domains are crossed.
      // This will require timing constraint created, can set up long path.
      r2_RX_Done <= r_RX_Done;

      r3_RX_Done <= r2_RX_Done;

      if (r3_RX_Done == 1'b0 && r2_RX_Done == 1'b1) // rising edge
      begin
        o_RX_DV   <= 1'b1;  // Pulse Data Valid 1 clock cycle
        o_RX_Byte <= r_RX_Byte;
      end
      else
      begin
        o_RX_DV <= 1'b0;
      end
    end // else: !if(~i_Rst_L)
  end // always @ (posedge i_Bus_Clk)

  // Control preload signal.  Should be 1 when CS is high, but as soon as
  // first clock edge is seen it goes low.
  always @(posedge w_SPI_CLK or posedge i_SPI_CS_n)
  begin
    if (i_SPI_CS_n)
    begin
      r_Preload_MISO <= 1'b1;
    end
    else
    begin
      r_Preload_MISO <= 1'b0;
    end
  end

  // Purpose: Transmits 1 SPI Byte whenever SPI clock is toggling
  // Will transmit read data back to SW over MISO line.
  // Want to put data on the line immediately when CS goes low.
  always @(posedge w_SPI_CLK or posedge i_SPI_CS_n)
  begin
    if (i_SPI_CS_n)
    begin
      r_TX_Bit_Count <= 3'b111;  // Send MSb first
      r_SPI_MISO_Bit <= r_TX_Byte[3'b111];  // Reset to MSb
    end
    else
    begin
      r_TX_Bit_Count <= r_TX_Bit_Count - 1;

      // Here is where data crosses clock domains from i_Clk to w_SPI_Clk
      // Can set up a timing constraint with wide margin for data path.
      r_SPI_MISO_Bit <= r_TX_Byte[r_TX_Bit_Count];

    end // else: !if(i_SPI_CS_n)
  end // always @ (negedge w_SPI_Clk or posedge i_SPI_CS_n_SW)


  // Purpose: Register TX Byte when DV pulse comes.  Keeps registed byte in 
  // this module to get serialized and sent back to master.
  always @(posedge i_Clk or negedge i_Rst_L)
  begin
	if(!i_Rst_L) begin
		old_r_TX_Bit_Count <= 0;
	end else begin
    old_r_TX_Bit_Count<=r_TX_Bit_Count;
    if((old_r_TX_Bit_Count==1)&&(r_TX_Bit_Count==0))
    begin
        o_TX_sent<=1'b1;
    end
    else
    begin
        o_TX_sent<=1'b0;
    end
    if (i_Rst_L || (r_TX_Bit_Count==0 && w_SPI_CLK) && ~i_TX_DV)  // Will remove message on send
    begin
      r_TX_Byte <= 8'h00;
    end // if (i_Rst_L || (r_TX_Bit_Count==0 && w_SPI_CLK)) 
    else
    begin
      if (i_TX_DV)
      begin
        r_TX_Byte <= i_TX_Byte; 
      end
    end // else: !if(~i_Rst_L)
	end
  end // always @ (posedge i_Clk or negedge i_Rst_L)
  
   
  
  always@(posedge i_Clk)
begin

storex = ((1800000) / int_rpmx);
	 if (cntx > (11999999/2)) begin
		  if (int_rpmx < (rpmx-200) && dist2x < (dist1x - dist3x)) begin
				if (int_rpmx > 3500) begin
					int_rpmx <= 3500;
				end else begin
					int_rpmx <= int_rpmx + 200;
				end	
		  end
		  else if (dist2x < (dist1x - dist3x)) begin
	        		  if(int_rpmx > (rpmx + 200)) begin
	        			  int_rpmx <= int_rpmx - 200;
	        		  end else begin
	        			if (rpmx > 3500) begin
	        				int_rpmx <= 3500;
	        			end else begin
	        				int_rpmx <= rpmx;
	        			end
	        		  end
					  end
		  else if (dist2x < dist1x) begin
		    if(dead_endx) begin
			  int_rpmx <= int_rpmx - 200;
			 end else begin
				int_rpmx <= rpmx;
			 end
		  end else begin
			  int_rpmx <= 250;
		  end

		  cntx <= 0;
	  end else begin
		  cntx <= cntx + 1;
	  end
//end
//  
//always@(posedge i_Clk)
//begin


if(!i_Rst_L) begin
	stopx = 0;                      // issue
end
dist1x = (pulse_rate/5)*distx;         // 5mm pitch  
	 	


if (stopx == 0 && stoppx == 0) begin

//pulses_x = togglex; 




if((dist2x == 0) && (dist2 == 0) && (dist2y == 0))//|| dist2 > (dist1-(dist3-5)))
begin
//dist2 <= 0;

distx = data_out[30:16];
rpmx <= data_out[15:0];
//dir = data_out[31];
            


//if(distx > 0 && rpmx > 0)
//begin
  if (data_out[31] == 1) begin
				  int_rpmx <= 0;
				  rpmx <= 0;
		    	  pin1x <= 0;
				  pin2x <= 1;
			  end else begin
				  int_rpmx <= 0;
				  rpmx <= 0;
				  pin1x <= 1;
				  pin2x <= 0;
			  end
//			end 			  
		
		
end
else
begin
distx = distx;
rpmx <= rpmx;
//if(data_out[15:0] > 3500)
//begin
//rpmx <= 3500;
//end
//else
//begin
//rpmx <= data_out[15:0];
//end
end

if(distx > 0)
begin
		  counterx <= counterx + 1;

		  if (counterx > storex) begin
			  togglex = ~togglex;
			  counterx <= 0;

			 

			  if (dist2x > dist1x) begin
//					int_rpm <= 0;   // 250 			
					dist2x <= 0;
//					if(int_rpmx > rpmx)
//					begin
//					int_rpmx <= int_rpmx - 200;
//					end
//					if(int_rpmx < rpmx)
//					begin
//					int_rpmx <= int_rpmx + 200;
//					end
					
				if (dead_endx)
					begin		
						 if (int_rpmx <= (rpmx - 200)) begin
					  dist3x <= dist2x;
				  end 
				   stopx = 1;
					end

		  end 
		  
//		  end
		  
		  if(togglex == 0)
		  begin
		  dist2x <= dist2x + 1;
		  end
		  
		  end else begin
			  pulses_x = togglex;       // pulses insted of toggle if not worked copy line no 366;
			  
			  end
			  
		  end
	  end
end


always@(posedge i_Clk)
begin
storey = ((1800000) / int_rpmy);
	 if (cnty > (11999999/2)) begin
		  if (int_rpmy < (rpmy-40) && dist2y < (dist1y - dist3y)) begin
				if (int_rpmy > 960) begin
					int_rpmy <= 1200;
				end else begin
					int_rpmy <= int_rpmy + 40;
				end	
		  end
		  else if (dist2y < (dist1y - dist3y)) begin
	        		  if(int_rpmy > (rpmy+40)) begin
	        			  int_rpmy <= int_rpmy - 40;
	        		  end else begin
	        			if (rpmy > 1200) begin
	        				int_rpmy <= 1200;
	        			end else begin
	        				int_rpmy <= rpmy;
	        			end
	        		  end
					  end
		  else if (dist2y < dist1y) begin
		    if(dead_endy) begin
			  int_rpmy <= int_rpmy - 40;
			 end else begin
				int_rpmy <= rpmy;
			 end
		  end else begin
			  int_rpmy <= 250;
		  end

		  cnty <= 0;
	  end else begin
		  cnty <= cnty + 1;
	  end
end
  
always@(posedge i_Clk)
begin



if(!i_Rst_L) begin
	stopy = 0;                      // issue
end
dist1y = (pulse_rate/5)*disty;


if (stopy == 0 && stopp == 0) begin

pulses_y = toggley; 




if((dist2y == 0) && (dist2 == 0) && (dist2x == 0))//|| dist2 > (dist1-(dist3-5)))
begin
//dist2 <= 0;
disty = data_out[62:48];
rpmy = data_out[47:32];




  if (data_out[63] == 1) begin
		    	  pin1y <= 0;
				  pin2y <= 1;
			  end else begin
				  pin1y <= 1;
				  pin2y <= 0;
			  end
		
end
else
begin
disty = disty;
rpmy = rpmy;
end
if(disty > 0)
begin
		  countery <= countery + 1;

		  if (countery > storey) begin
			  toggley = ~toggley;
			  countery <= 0;

			 

			  if (dist2y > dist1y) begin
//					int_rpm <= 0;   // 250 			
					dist2y <= 0;
				if (dead_endy)
					begin		
						 if (int_rpmy <= (rpmy - 40)) begin
					  dist3y <= dist2y;
				  end 
				   stopy = 1;
					end

		  end else begin
				  dist2y <= dist2y + 1;
				  stopy = 0;
				  if (int_rpmy <= (rpmy - 40)) begin
					  dist3y <= dist2y;
				  end 

			  end
		  end else begin
			  toggley = toggley;       // pulses insted of toggle if not worked copy line no 366;
			  if(data_out == 0)
			  begin
			  stopy = 0;
			  end
			  
			  end
			  
		  end
	  end
end

  always@(posedge i_Clk)
	begin
		store = ((1800000) / int_rpm);
	 if (cnt > (11999999/2)) begin
		  if (int_rpm < (rpm-200) && dist2 < (dist1 - dist3)) begin
				if((int_rpm < 1100) && (rpm < 1200)) begin
					int_rpm <= 1200;
				end else if (int_rpm > 4300) begin
					int_rpm <= 4500;
				end else begin
					int_rpm <= int_rpm + 200;
				end	
		  end
		  else if (dist2 < (dist1 - dist3)) begin
	        		  if(int_rpm > (rpm + 200)) begin
	        			  int_rpm <= int_rpm - 200;
	        		  end else begin
	        			if (rpm > 4300) begin
	        				int_rpm <= 4500;
	        			end else begin
	        				int_rpm <= rpm;
	        			end
	        		  end
					  end
		  else if (dist2 < dist1) begin
		    if(dead_end) begin
			  int_rpm <= int_rpm - 200;
			 end else begin
				int_rpm <= rpm;
			 end
		  end else begin
			  int_rpm <= 250;
		  end

		  cnt <= 0;
	  end else begin
		  cnt <= cnt + 1;
	  end
//end
//  


if(!i_Rst_L) begin
	stop = 0;                      // issue
	pulses <= 0; 
end
dist1 = (pulse_rate/5)*dist;
	 	

if (stop == 0 && stopp == 0) begin

puls_in = ~ pulses;


if((dist2 == 0) && (dist2x == 0) && (dist2y == 0))//|| dist2 > (dist1-(dist3-5)))     // remove dist2x dist2y if not worked same for 2 others 
begin
//dist2 <= 0;

dist <= data_out[94:80];
rpm <= data_out[79:64];


  if (data_out[95] == 1) begin
				  int_rpm <= 0;
				  rpm <= 0;
		    	  pin1 <= 0;
				  pin2 <= 1;
				  
			  end else begin
				  int_rpm <= 0;
				  rpm <= 0;
				  pin1 <= 1;
				  pin2 <= 0;

			  end
			 			  
		
		
end
else
begin
dist <= dist;

			  rpm <= rpm;
			  end
if(dist > 0)
begin
		  counter <= counter + 1;

		  if (counter > store) begin
			  toggle <= ~toggle;
			  counter <= 0;

			 

			  if (dist2 > dist1) 
			  begin
					dist2 <= 0;
					//pulses <= 0;
					if(int_rpm > rpm)
					begin
					int_rpm <= int_rpm - 200;
					end
					if(int_rpm < rpm)
					begin
					int_rpm <= int_rpm + 200;
					end
					
				if (dead_end)
					begin		
						 if (int_rpm <= (rpm - 200)) 
						 begin
							dist3 <= dist2;
						 end 
					pulses <= 0;
				   stop = 1;
					end

				end
			
				if(toggle == 0)   // Can count one edge of pulses
					begin
					dist2 <= dist2 + 1;
				  end
				  

		  end else begin
			  pulses <= toggle;       // pulses insted of toggle if not worked copy line no 366
			  end
			  
		  end
	  end
end  

always@(posedge i_Clk) begin
	if(~i_Rst_L) begin
		cntr <= 0;
		gpio_pin <= 0;
	end else begin
		if (cntr < 59999999) begin   //5 second on
			gpio_pin <= 1;
			cntr<= cntr + 1;
		end else if (cntr< 89999999) begin  //3 second off
			gpio_pin <= 0;
			cntr <= cntr + 1;
		end else begin
			cntr <= 0;
			gpio_pin <= 0;
		end
	end
end 
 

  // Preload MISO with top bit of send data when preload selector is high.
  // Otherwise just send the normal MISO data
  assign w_SPI_MISO_Mux = r_Preload_MISO ? r_TX_Byte[3'b111] : r_SPI_MISO_Bit;
  assign i_TX_DV = o_RX_DV;
  assign i_TX_Byte = o_RX_Byte;

  // Tri-statae MISO when CS is high.  Allows for multiple slaves to talk.
//  assign o_SPI_MISO = i_SPI_CS_n ? 1'bZ : w_SPI_MISO_Mux;
  
  assign o_SPI_MISO = (rpm == data_out[15:0] || dist == data_out[31:16]) ? 1 : 0;
 
  
  
  assign o_Tx_Active = r_Tx_Active;
  assign o_Tx_Done   = r_Tx_Done;

endmodule // SPI_Slave
