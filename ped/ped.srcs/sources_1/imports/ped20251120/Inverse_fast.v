//Revise Record

//2020/02/19 

//Author:zjq

//1. modified Adder_0_25 module.

//2. tested big number in Adder_0_25 but failed.

//3. eliminate redundant Adder_0_25 and Adder_0_5 modules. Since for u and v, calculate 0.5 time or 0.25 time can be implement by simply shifting.

//4. the initial value for x2 should be 0 rather than 2.

//5. when d == 2'b10, the condition should be u > {1'b0,v[255:1]} rather than v < {1'b0,u[255:1]} based on radix-4 Extended Euclidean Algorithm.

module Inverse_fast

#(

	parameter	N       		= 256'hFFFFFFFE_FFFFFFFF_FFFFFFFF_FFFFFFFF_7203DF6B_21C6052B_53BBF409_39D54123,

	parameter	P       		= 256'h12ab655e9a2ca55660b44d1e5c37b00159aa76fed00000010a11800000000001,

	parameter	N_plus			= 256'hFFFFFFFE_FFFFFFFF_FFFFFFFF_FFFFFFFF_7203DF6B_21C6052B_53BBF409_39D54124,

	parameter	P_plus      	= 256'h12ab655e9a2ca55660b44d1e5c37b00159aa76fed00000010a11800000000002,

	parameter	N_INV       	= 257'h10000000_10000000_00000000_00000000_08DFC209_4DE39FAD_4AC440BF_6C62ABED_D,

	parameter	P_INV       	= 257'h1_1d549aa1_65d35aa9_9f4bb2e1_a3c84ffe_a6558901_2ffffffe_f5ee7fff_ffffffff

	//parameter	delta			= 258'h2_fffffffc_ffffffff_fffffff_fffffffe_560B9E41_65520F81_FB33DC1B_AD7FC369

)

(

	input						rstn,

	input						Initl,

	input 						clk,

	input 						start,

	input		[255:0]			a,

	input 						np,

	output reg 					done,

	output reg 	[255:0]			z

	);

	

	localparam IDLE = 1'b0;

	localparam BUSY = 1'b1;

	

	//wire [257:0]		test1;

	//wire [257:0]		test2;

	//wire [257:0]		test3;

	//wire [257:0]		test4;

	//assign test1 = delta + N_INV;

	//assign test2 = test1 + N_INV;

	//assign test3 = test2 + N_INV;

	//assign test4 = test3 + N_INV;

	wire [255:0]	p;

	//wire [255:0]	u_2,v_2,x1_2,x2_2;	//a/2

	//wire [255:0]	u_4,v_4,x1_4,x2_4;	//a/4

	wire [255:0]			x1_2,x2_2;	//a/2

	wire [255:0]			x1_4,x2_4;	//a/4

	wire [255:0]	u_v,v_u,x1_x2,x2_x1;	//a-b

	//wire [255:0]	u_v_4,v_u_4,x1_x2_4,x2_x1_4;//(a-b)/4

	wire [255:0]				x1_x2_4,x2_x1_4;

	wire [255:0]	u_2_v,v_2_u,x1_2_x2,x2_2_x1;//a/2-b

	wire [255:0]	u_v_2,v_u_2,x1_x2_2,x2_x1_2;//a-b/2

	//wire [255:0]	u_v_0_5,v_u_0_5,x1_x2_0_5,x2_x1_0_5;//(a-b)/2

	wire [255:0]					x1_x2_0_5,x2_x1_0_5;

	//wire [255:0]	u_2_v_2,v_2_u_2,x1_2_x2_2,x2_2_x1_2;//(a/2-b)/2

	wire [255:0]					x1_2_x2_2,x2_2_x1_2;

	//wire [255:0]	u_v_2_2,v_u_2_2,x1_x2_2_2,x2_x1_2_2;//(a-b/2)/2

	wire [255:0]					x1_x2_2_2,x2_x1_2_2;

	wire 			over;

	wire [1:0]		c,d;

	reg  [255:0]	u,v,x1,x2;

	reg				InverState, next_InverState;



	//a/2

	//Adder_0_5 #(N, P) add1(u,np,u_2);

	//Adder_0_5 #(N, P) add2(v,np,v_2);

	Adder_0_5 #(N, P) add3(x1,np,x1_2);

	Adder_0_5 #(N, P) add4(x2,np,x2_2);

	//a/4

	//Adder_0_25 #(N, P)add5(u,np,u_4);

	Adder_0_25 #(N, P)add6(x1,np,x1_4);

	//Adder_0_25 #(N, P)add7(v,np,v_4);

	Adder_0_25 #(N, P)add8(x2,np,x2_4);

	//a-b

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub1(1'b1,u,v,np,u_v);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub2(1'b1,v,u,np,v_u);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub3(1'b1,x1,x2,np,x1_x2);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub4(1'b1,x2,x1,np,x2_x1);

	//(a-b)/4

	//Adder_0_25 #(N, P)add9 (u_v,np,u_v_4);

	Adder_0_25 #(N, P)add10(x1_x2,np,x1_x2_4);

	//Adder_0_25 #(N, P)add11(v_u,np,v_u_4);

	Adder_0_25 #(N, P)add12(x2_x1,np,x2_x1_4);

	//a/2-b

	//Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub5(1'b1,u_2,v,np,u_2_v);

	//Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub6(1'b1,v_2,u,np,v_2_u);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub5(1'b1,{1'b0,u[255:1]},v,np,u_2_v);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub6(1'b1,{1'b0,v[255:1]},u,np,v_2_u);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub7(1'b1,x1_2,x2,np,x1_2_x2);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub8(1'b1,x2_2,x1,np,x2_2_x1);

	//a-b/2

	//Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub9 (1'b1,u,v_2,np,u_v_2);

	//Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub10(1'b1,v,u_2,np,v_u_2);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub9 (1'b1,u,{1'b0,v[255:1]},np,u_v_2);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub10(1'b1,v,{1'b0,u[255:1]},np,v_u_2);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub11(1'b1,x1,x2_2,np,x1_x2_2);

	Adder_mod #(N_plus, P_plus, N_INV, P_INV) sub12(1'b1,x2,x1_2,np,x2_x1_2);	

	//(a-b)/2

	//Adder_0_5 #(N, P)add13(u_v,np,u_v_0_5);

	//Adder_0_5 #(N, P)add14(v_u,np,v_u_0_5);

	Adder_0_5 #(N, P)add15(x1_x2,np,x1_x2_0_5);

	Adder_0_5 #(N, P)add16(x2_x1,np,x2_x1_0_5);

	//(a/2-b)/2

	//Adder_0_5 #(N, P)add17(u_2_v,np,u_2_v_2);

	//Adder_0_5 #(N, P)add18(v_2_u,np,v_2_u_2);

	Adder_0_5 #(N, P)add19(x1_2_x2,np,x1_2_x2_2);

	Adder_0_5 #(N, P)add20(x2_2_x1,np,x2_2_x1_2);

	//(a-b/2)/2

	//Adder_0_5 #(N, P)add21(u_v_2,np,u_v_2_2);

	//Adder_0_5 #(N, P)add22(v_u_2,np,v_u_2_2);

	Adder_0_5 #(N, P)add23(x1_x2_2,np,x1_x2_2_2);

	Adder_0_5 #(N, P)add24(x2_x1_2,np,x2_x1_2_2);



	assign p = np ? N : P;

	assign over = ((InverState == BUSY) && (v == 256'd0));

	assign c = u[1:0];

	assign d = v[1:0];

	//integer i;

	

	always @(posedge clk or negedge rstn) begin

		if (!rstn) begin

			InverState <= IDLE;

		end

		else if (Initl) begin

			InverState <= IDLE;

		end

		else begin

			InverState <= next_InverState;

		end

	end



	always @(*) begin

		case(InverState)

			IDLE: begin

				if(start) begin

					next_InverState = BUSY;

				end

				else begin

					next_InverState = IDLE;

				end

			end

			BUSY: begin

				if(over) begin

					next_InverState = IDLE;

				end

				else begin

					next_InverState = BUSY;

				end

			end

			default: begin

				next_InverState = IDLE;

			end

		endcase

	end



	// �����Σ�����߼���ʱ���߼���

	always @(posedge clk or negedge rstn) begin

		if (!rstn) begin

			// reset

			done <= 1'b0;

			z  <= 256'd0;

			u  <= 256'd0;

			v  <= 256'd0;

			x1 <= 256'd0;

			x2 <= 256'd0;

		end

		else if (Initl) begin

			done <= 1'b0;

			z  <= 256'd0;

			u  <= 256'd0;

			v  <= 256'd0;

			x1 <= 256'd0;

			x2 <= 256'd0;

		end

		else begin

			case(InverState)

				IDLE: begin

					if(start) begin

						done <= 1'b0;

						u <= a;

						v <= p;

						x1 <= 256'd1;

						x2 <= 256'd0;

					end

					else begin

						done <= done;

						u <= u;

						v <= v;

						x1 <= x1;

						x2 <= x2;

					end

				end

				BUSY: begin

					if(over) begin

						done <= 1'b1;

						z <= x1;

					end

					else begin

						if(c == 2'b00) begin

							u <= {2'b00,u[255:2]};

							x1 <= x1_4;

						end

						else if(d == 2'b00) begin

							v <= {2'b00,v[255:2]};

							x2 <= x2_4;

						end

						else if (c == d) begin

							if(u > v) begin

								u <= {2'b00,u_v[255:2]};

								x1 <= x1_x2_4;

							end

							else begin

								v <= {2'b00,v_u[255:2]};

								x2 <= x2_x1_4;

							end

						end

						else if (c == 2'b10) begin

							if( {1'b0,u[255:1]} > v) begin

								u <= {1'b0,u_2_v[255:1]};

								x1 <= x1_2_x2_2;

							end

							else begin

								u <= {1'b0,u[255:1]};

								x1 <= x1_2;

								v <= {1'b0,v_u_2[255:1]};

								x2 <= x2_x1_2_2;

							end

						end

						else if (d == 2'b10) begin

							if( u > {1'b0,v[255:1]} ) begin

								v <= {1'b0,v[255:1]};

								x2 <= x2_2;

								u <= {1'b0,u_v_2[255:1]};

								x1 <= x1_x2_2_2;

							end

							else begin

								v <= {1'b0,v_2_u[255:1]};

								x2 <= x2_2_x1_2;

							end

						end

						else begin

							if( u > v ) begin

								u <= {1'b0,u_v[255:1]};

								x1 <= x1_x2_0_5;

							end

							else begin

								v <= {1'b0,v_u[255:1]};

								x2 <= x2_x1_0_5;

							end

						end

					end

				end

				default: begin

                    done <= 1'b0;

                    z  <= 256'd0;

                    u  <= 256'd0;

                    v  <= 256'd0;

                    x1 <= 256'd0;

                    x2 <= 256'd0;

				end

			endcase

		end

	end



endmodule

