module main (input logic a, clock, reset_l, output logic out, stateout);

enum logic {B = 1'b0, C = 1'b1} state, nextState;
assign stateout = state;

always_ff@ (posedge clock, posedge reset_l)
	if(reset_l) begin
		state <= B;
	end else
		state <= nextState;

always_comb
	case(state)
		B: begin
			out = 0;
			nextState = (a) ? B:C;
		end

		C: begin
			out = 1;
			nextState = (a) ? B:C;
		end
	endcase

endmodule: main