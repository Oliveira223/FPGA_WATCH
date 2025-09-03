module debounce #(
	parameter [31:0] DELAY = 500000
) (
	input wire clk_i,
	input wire rstn_i,
	input wire key_i,
	output wire debkey_o
);

	parameter [2:0] state1 = 0, state2 = 1, state3 = 2, state4 = 3, state5 = 4;

	reg [2:0] state; wire [2:0] nextstate;
	reg intclock;
	reg [23:0] clockdiv;

	always @(posedge clk_i, negedge rstn_i) begin
		if (rstn_i == 1'b0) begin
			state <= state1;
		end else begin
			case(state)
			state1 : begin
				if (intclock == 1'b0) begin
					if (key_i == 1'b1) begin
						state <= state2;
					end
				end
			end
			state2 : begin
				if (intclock == 1'b1) begin
					if (key_i == 1'b1) begin
						state <= state3;
					end
					else begin
						state <= state1;
					end
				end
			end
			state3 : begin
				if (intclock == 1'b0) begin
					if (key_i == 1'b0) begin
						state <= state4;
					end
				end
			end
			state4 : begin
				if (intclock == 1'b1) begin
					if (key_i == 1'b0) begin
						state <= state5;
					end
					else begin
						state <= state3;
					end
				end
			end
			state5 : begin
				state <= state1;
			end
			endcase
		end
	end

	always @(posedge clk_i, negedge rstn_i) begin
		if (rstn_i == 1'b0) begin
			clockdiv <= {24{1'b0}};
			intclock <= 1'b0;
		end else begin
			if (clockdiv <= DELAY) begin
				clockdiv <= clockdiv + 1;
			end
			else begin
				clockdiv <= {24{1'b0}};
				intclock <= ~intclock;
			end
		end
	end

	assign debkey_o = state == state3 ? 1'b1 : 1'b0;

endmodule
