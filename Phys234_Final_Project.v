`timescale 1ns / 1ps
module top(
			input [7:0] sw,
			output [7:0] ld,
			input clk, // The 50 MHz clock
			input reset // This can be btn0
			);
			wire [7:0] progaddr;
			wire [11:0] prog;
			
			pro u1 (.clk(clk),.progaddr(progaddr),.progdata(prog),.datain(sw),.dataout(ld),.reset(reset));
			MemProg u2 (.addr(progaddr), .prog(prog));
endmodule

module MemProg(input [7:0] addr, output reg [11:0] prog);
	always @ (*)
		case(addr)		
			0: prog<=12'b000000000000;
			1: prog<=12'b100010000100;
			2: prog<=12'b100010010101;
			3: prog<=12'b100110100000;
			4: prog<=12'b110010001010;
			5: prog<=12'b010100001110;
			6: prog<=12'b110010011010;
			7: prog<=12'b010100010000;
			8: prog<=12'b110110001001;
			9: prog<=12'b011000001100;
			10: prog<=12'b101010001001;
			11: prog<=12'b000100000100;
			12: prog<=12'b101010011000;
			13: prog<=12'b000100000100;
			14: prog<=12'b100001101001;
			15: prog<=12'b001100000000;
			16: prog<=12'b100001101000;
			default prog<=12'b001100000000;
		endcase
endmodule

module pro(clk, progaddr, progdata, datain, dataout, reset);
	input clk;
	output reg [7:0] progaddr;
	input [11:0] progdata;
	input [7:0] datain;
	output [7:0] dataout;
	input reset;
	
	wire [7:0] inst = progdata [7:0];
	wire [3:0] rm = progdata [7:4];
	wire [3:0] rn = progdata [3:0];
	
	wire goto = (progdata[11:8]==4'b0001);
	wire stop = (progdata[11:8]==4'b0011);
	
	wire ej0 = (progdata[11:8]==4'b0100);
	wire ej1 = (progdata[11:8]==4'b0101);
	wire cj0 = (progdata[11:8]==4'b0110);
	wire cj1 = (progdata[11:8]==4'b0111);
	
	wire move = (progdata[11:8]==4'b1000);
	wire give = (progdata[11:8]==4'b1001);
	wire sub = (progdata[11:8]==4'b1010);
	wire add = (progdata[11:8]==4'b1011);
	
	wire eq = (progdata[11:8]==4'b1100);
	wire cmp = (progdata[11:8]==4'b1101);

	reg [3:0] rg[0:15];
		
	wire eqjflag = (ej0 & ~rg[2][0]) | (ej1 & rg[2][0]);
	wire cmpjflag = (cj0 & ~rg[3][0]) | (cj1 & rg[3][0]);
	
	always @ (posedge clk or posedge reset)	
		begin
			if(reset) progaddr <= 0;
			else if(goto|eqjflag|cmpjflag) progaddr <= inst;
			else if(~stop) progaddr <= progaddr +1;
		end
			 
	assign dataout[3:0] = rg[6];
	assign dataout[7:4] = rg[7];

	wire [3:0] rmv;
	wire [3:0] arithv;
	wire [3:0] addv;
	wire [3:0] subv;
	wire eqv = (rg[rm]==rg[rn]);
	wire cmpv = (rg[rm]>rg[rn]);
	wire carryflag = (rg[rm]+rg[rn]>15);
	
	assign rmv = move ? rg[rn] : 4'bz;
	assign rmv = give ? rn : 4'bz;	
	assign subv = cmpv ? (rg[rm]-rg[rn]) : (rg[rn]-rg[rm]);
	assign addv = carryflag ? (rg[rm]+rg[rn]-16) : (rg[rm]+rg[rn]);
	assign arithv = sub ? subv : 4'bz;
	assign arithv = add ? addv : 4'bz;			
											
	always @ (negedge clk)
		begin
			if(move|give) rg[rm]<=rmv;
			if(eq) rg[2]<={3'b000, eqv};
			if(cmp) rg[3]<={3'b000, cmpv};
			if(sub|add) rg[rm]<=arithv;
			if(add) rg[1]<={3'b000, carryflag};
			rg[4] <= datain[3:0];
			rg[5] <= datain[7:4];
		end
endmodule