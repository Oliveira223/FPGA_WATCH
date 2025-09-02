//
//  File: dspl_drv_NexysA7.vhd
//  created by Ney Calazans 15/06/2021 16:20:00
//
//
// This module implements the interface hardware needed to drive some 
// Digilent boards 8-digit seven segment displays. This 
// display is multiplexed (see the specific board Reference Manual for details)
// requiring that just one digit be displayed at any moment.
// Example board for which this design is useful is the Nexys A7
// 
// The inputs of the module are:
//		clock - the 100MHz system board clock
//		reset - the active-high system reset signal
//    di vectors - 8 vectors, each with 6 bits, where each vector is:
//		di(0) is the decimal point (active-low)
//		di(4 downto 1) is the binary value of the digit
//		di(5) is the (active-high) enable signal of the digit
//      here, i varies from 4 to 1 (8 to 5), 4(8) corresponds to the rightmost
//		  digit of the display and 1(5) corresponds to the leftmost digit
// 
// The outputs of the module are:
//		an (8 downto 1) - the 8-wire active-low anode vector.
// 			In this circuit, exactly one of these 8 wires is at logic 0
//			at any moment. The wire in 0 lights up one of the 4 7-segment
//			displays. 8 is the rightmost display while 1 is the leftmost.
//		dec_ddp (7 downto 0) - is the decoded value of the digit to show
//			at the current instant. dec_ddp(7 downto 1)  corresponds
//			respectively to the segments a b c d e f g, and dec_ddp(0) is
//			the decimal point of that display.
//
// Functional description: The 100MHz is divided to obtain the
//		1KHz display refresh clock. Upon reset all displays are turned
//		off. The 1KHz clock feeds a 3-bit counter. This counter
//		generates a signal to select one of the eight di vectors. This
//		vector is in turn used to enable or not to show the digit in
//		question (through di(5)) and furnishes the digit value for the
//		single multiplexed 7-segment decoder. All outputs are registered
//		using the 1KHz clock.
//
// no timescale needed

module dspl_drv_8dig
(
	input wire clock,
	input wire reset,
	input wire [5:0] d8,
	input wire [5:0] d7,
	input wire [5:0] d6,
	input wire [5:0] d5,
	input wire [5:0] d4,
	input wire [5:0] d3,
	input wire [5:0] d2,
	input wire [5:0] d1,
	output reg [7:0] an,
	output reg [7:0] dec_ddp
);

	parameter [31:0] HALF_MS_COUNT=50000;

//}} End of automatically maintained section
	reg ck_1KHz;
	reg [2:0] dig_selection;
	reg [4:0] selected_dig;

	// 1KHz clock generation
	always @(posedge clock, posedge reset) begin : P1
		reg [31:0] count_50K;

		if (reset == 1'b1) begin
			count_50K = 0;
			ck_1KHz <= 1'b0;
		end else begin
			count_50K = count_50K + 1;
			if ((count_50K == (HALF_MS_COUNT - 1))) begin
				count_50K = 0;
				ck_1KHz <=  ~ck_1KHz;
			end
		end
	end

	// 1KHz counter to select digit and register output
	always @(posedge ck_1KHz, posedge reset) begin
		if (reset == 1'b1) begin
			dig_selection <= {3{1'b0}};
			an <= {8{1'b1}};
			// Disable all displays
		end else begin
		// a 3-bit binary counter
			if (dig_selection == 3'b111) begin
				dig_selection <= {3{1'b0}};
			end
			else begin
				dig_selection <= dig_selection + 1;
			end
			if (dig_selection == 3'b000) begin
				selected_dig <= d1[4:0];
				an <= {7'b1111111, ~d1[5]};
			end
			else if (dig_selection == 3'b001) begin
				selected_dig <= d2[4:0];
				an <= {6'b111111, ~d2[5],1'b1};
			end
			else if (dig_selection == 3'b010) begin
				selected_dig <= d3[4:0];
				an <= {5'b11111, ~d3[5],2'b11};
			end
			else if (dig_selection == 3'b011) begin
				selected_dig <= d4[4:0];
				an <= {4'b1111, ~d4[5],3'b111};
			end
			else if (dig_selection == 3'b100) begin
				selected_dig <= d5[4:0];
				an <= {3'b111, ~d5[5],4'b1111};
			end
			else if (dig_selection == 3'b101) begin
				selected_dig <= d6[4:0];
				an <= {2'b11, ~d6[5],5'b11111};
			end
			else if (dig_selection == 3'b110) begin
				selected_dig <= d7[4:0];
				an <= {1'b1, ~d7[5],6'b111111};
			end
			else begin
				selected_dig <= d8[4:0];
				an <= { ~d8[5],7'b1111111};
			end
		end
	end

	// digit 4-to-hex decoder
	always @(*) begin
		case (selected_dig[4:1])
		4'b0000 : dec_ddp[7:1] <= 7'b0000001; //0
		4'b0001 : dec_ddp[7:1] <= 7'b1001111; //1
		4'b0010 : dec_ddp[7:1] <= 7'b0010010; //2
		4'b0011 : dec_ddp[7:1] <= 7'b0000110; //3
		4'b0100 : dec_ddp[7:1] <= 7'b1001100; //4
		4'b0101 : dec_ddp[7:1] <= 7'b0100100; //5
		4'b0110 : dec_ddp[7:1] <= 7'b0100000; //6
		4'b0111 : dec_ddp[7:1] <= 7'b0001111; //7
		4'b1000 : dec_ddp[7:1] <= 7'b0000000; //8
		4'b1001 : dec_ddp[7:1] <= 7'b0000100; //9
		4'b1010 : dec_ddp[7:1] <= 7'b0001000; //A
		4'b1011 : dec_ddp[7:1] <= 7'b1100000; //b
		4'b1100 : dec_ddp[7:1] <= 7'b0110001; //C
		4'b1101 : dec_ddp[7:1] <= 7'b1000010; //d
		4'b1110 : dec_ddp[7:1] <= 7'b0110000; //E
		default : dec_ddp[7:1] <= 7'b0111000; //F
		endcase
		// and the decimal point
		dec_ddp[0] <= selected_dig[0];
	end

endmodule
