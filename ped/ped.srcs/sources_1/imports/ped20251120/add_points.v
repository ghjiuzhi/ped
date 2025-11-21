module add_points #(
    parameter FIELD_SIZE = 253
)(
    // input
    input                           i_clk,
    input                           i_rst_n,
    input                           i_vld,
    input [FIELD_SIZE-1:0]          i_a_x,
    input [FIELD_SIZE-1:0]          i_a_y,
    input                           i_a_mode, // 0:constant, 1:private
    input [FIELD_SIZE-1:0]          i_b_x,
    input [FIELD_SIZE-1:0]          i_b_y,
    input                           i_b_mode,
    input                           i_ok,

    // output
    output reg                      o_res_vld,
    output reg [FIELD_SIZE-1:0]     o_res_x,
    output reg [FIELD_SIZE-1:0]     o_res_y,
    output reg                      o_lvs1_vld,
    output reg [FIELD_SIZE-1:0]     o_lvs1,
    output reg                      o_lvs2_vld,
    output reg [FIELD_SIZE-1:0]     o_lvs2,
    output reg                      o_lvs3_vld,
    output reg [FIELD_SIZE-1:0]     o_lvs3,
    output reg                      o_lvs4_vld,
    output reg [FIELD_SIZE-1:0]     o_lvs4
);
    // -------------------- parameter -------------------- 
    // FSM
    localparam IDLE_STATE           =        8'b0000_0000; 
    localparam SAVE_STATE           =        8'b0000_0001;     // 01
    localparam LVS1_STATE           =        8'b0000_0010;     // 02
    localparam X1Y2_STATE           =        8'b0000_0011;     // 03
    localparam X2Y1_STATE           =        8'b0000_0100;     // 04
    localparam WAIT1_STATE          =        8'b0000_0101;     // 05
    localparam LVS1_OUT_STATE       =        8'b0000_0110;     // 06
    localparam AX1Y2_STATE          =        8'b0000_0111;     // 07
    localparam X12Y12_STATE         =        8'b0000_1000;     // 08
    localparam WAIT2_STATE          =        8'b0000_1001;     // 09
    localparam AX1Y2_OUT_STATE      =        8'b0000_1010;     // 0a
    localparam DXY_STATE            =        8'b0000_1011;     // 0b
    localparam WAIT3_STATE          =        8'b0000_1100;     // 0c
    localparam INV1_STATE           =        8'b0000_1101;     // 0d
    localparam WAIT4_STATE          =        8'b0000_1110;     // 0e
    localparam INV2_STATE           =        8'b0000_1111;     // 0f
    localparam WAIT5_STATE          =        8'b0001_0000;     // 10
    localparam INV_END_STATE        =        8'b0001_0001;     // 11
    localparam WAIT6_STATE          =        8'b0001_0010;     // 12
    localparam END_STATE            =        8'b0001_0011;     // 13


    // EWARDS
    localparam EDWARDS_A            =        253'd8444461749428370424248824938781546531375899335154063827935233455917409239040;
    localparam EDWARDS_D            =        253'd3021;

    // -------------------- reg & wire -------------------- 
    // FSM
    reg [7:0]                   state, next_state;

    reg [1:0]                   lvs_ouput_mode;           // 0:0lvs  1:3lvs  2:6lvs
    // input reg
    reg [FIELD_SIZE-1:0]        x1, y1, x2, y2;
    // counter
    reg [3:0]                   cnt;
    // tmp reg
    reg [FIELD_SIZE-1:0]        tmp1;

    // add
    wire [FIELD_SIZE-1:0]       add_in0, add_in1, add_out;
    wire                        add_func;

    // mul
    wire                        mul_vld, mul_rslt_vld;
    wire [FIELD_SIZE-1:0]       mul_a, mul_b, mul_rslt;

    // inv
    wire                        inv_start, inv_done;
    wire [FIELD_SIZE-1:0]       inv_a, inv_z;
    wire [FIELD_SIZE+3-1:0]     inv_z_full;



    // -------------------- Instantiation -------------------- 
    modadd_sub  u_modadd_sub (
        .field          (1'b1),
        .in0            (add_in0),
        .in1            (add_in1),
        .func           (add_func),
        .out            (add_out)
    );
    KOM_Bar_MM dut (
        .clk            (i_clk),
        .rstn           (i_rst_n),
        .i_vld          (mul_vld),
        .i_a            ({3'b0, mul_a}),
        .i_b            ({3'b0, mul_b}),
        .o_rslt_vld     (mul_rslt_vld),
        .o_rslt         (mul_rslt)
    );
    Inverse_fast uut (
        .clk            (i_clk),
        .rstn           (i_rst_n),
        .Initl          (1'b0),
        .start          (inv_start),
        .a              ({3'b0, inv_a}),
        .np             (1'b0),
        .done           (inv_done),
        .z              (inv_z_full)
    );

    // add
    assign add_func  =   (state == X12Y12_STATE || state == INV1_STATE)      ?  1'b1     : 1'b0;
    assign add_in0   =   (state == SAVE_STATE)      ?  x1       : 
                         (state == LVS1_STATE)      ?  x2       : 
                         (state == X12Y12_STATE)    ?  o_lvs1   :  
                         (state == AX1Y2_OUT_STATE) ?  o_res_y  :  
                         (state == INV1_STATE)      ?   'b1     :  
                         (state == INV2_STATE)      ?   'b1     :  
                         (state == INV_END_STATE)   ?  o_lvs2   :  'b0;
    assign add_in1   =   (state == SAVE_STATE)      ?  y1       : 
                         (state == LVS1_STATE)      ?  y2       :  
                         (state == X12Y12_STATE)    ?  mul_rslt :  
                         (state == AX1Y2_OUT_STATE) ?  mul_rslt :  
                         (state == INV1_STATE)      ?  mul_rslt :  
                         (state == INV2_STATE)      ?  o_res_x  :  
                         (state == INV_END_STATE)   ?  o_lvs3   :  'b0;

    // mul
    assign mul_vld   =   (state == LVS1_STATE || state == X1Y2_STATE || state == X2Y1_STATE ||  state == AX1Y2_STATE || state == X12Y12_STATE || state == DXY_STATE || state == INV2_STATE || state == INV_END_STATE ) ? 1'b1 : 1'b0;
    assign mul_a     =   (state == LVS1_STATE)      ?  tmp1     : 
                         (state == X1Y2_STATE)      ?  x1       : 
                         (state == X2Y1_STATE)      ?  x2       : 
                         (state == AX1Y2_STATE)     ?  EDWARDS_A: 
                         (state == X12Y12_STATE)    ?  tmp1     : 
                         (state == DXY_STATE)       ?  EDWARDS_D:  
                         (state == INV2_STATE)      ?  o_res_y  : 
                         (state == INV_END_STATE)   ?  add_out  :  'b0;
    assign mul_b     =   (state == LVS1_STATE)      ?  add_out  : 
                         (state == X1Y2_STATE)      ?  y2       : 
                         (state == X2Y1_STATE)      ?  y1       : 
                         (state == AX1Y2_STATE)     ?  mul_rslt : 
                         (state == X12Y12_STATE)    ?  mul_rslt : 
                         (state == DXY_STATE)       ?  mul_rslt :  
                         (state == INV2_STATE)      ?  inv_z    :  
                         (state == INV_END_STATE)   ?  inv_z    :  'b0;

    // inv
    assign inv_start =   (state == INV1_STATE || state == INV2_STATE)    ?  1'b1     : 1'b0;
    assign inv_a     =   (state == INV1_STATE)      ?  add_out  :  
                         (state == INV2_STATE)      ?  add_out  :  'b0;
    assign inv_z     =   inv_z_full[252:0];                             // need low 253 bits

    // -------------------- FSM -------------------- 
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            state <= IDLE_STATE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            // IDLE
            IDLE_STATE: begin
                if (i_vld) begin
                    if      ( i_a_mode == 0 && i_a_x == 253'b0 && i_a_y == 253'b1)
                        next_state = IDLE_STATE;
                    else if ( i_b_mode == 0 && i_b_x == 253'b0 && i_b_y == 253'b1)
                        next_state = IDLE_STATE;
                    else
                        next_state = SAVE_STATE;
                end
                else begin
                    next_state = IDLE_STATE;
                end
            end

            // BEGIN to work
            // -a*x1 + y1
            SAVE_STATE: begin
                next_state = LVS1_STATE;
            end

            // (x2+y2) * (-a*x1 + y1)
            LVS1_STATE: begin
                next_state = X1Y2_STATE;
            end

            // x1*y2
            X1Y2_STATE: begin
                next_state = X2Y1_STATE;
            end

            // x2*y1
            X2Y1_STATE: begin
                next_state = WAIT1_STATE;
            end

            // wait for mul result
            WAIT1_STATE: begin
                if (cnt == 8)
                    next_state = LVS1_OUT_STATE;
                else
                    next_state = WAIT1_STATE;
            end

            // save lsv1
            LVS1_OUT_STATE: begin
                next_state = AX1Y2_STATE;
            end

            // a*x1*y2
            AX1Y2_STATE: begin
                next_state = X12Y12_STATE;
            end

            // x1*x2*y1*y2  save lvs3
            X12Y12_STATE: begin
                next_state = WAIT2_STATE;
            end

            // wait for reult
            WAIT2_STATE: begin
                if (cnt == 9)
                    next_state = AX1Y2_OUT_STATE;
                else
                    next_state = WAIT2_STATE;
            end

            // save a*x1*y2
            AX1Y2_OUT_STATE: begin
                next_state = DXY_STATE;
            end

            // d*x1*x2*y1*y2  save lvs4=x1*x2*y1*y2  
            DXY_STATE: begin
                next_state = WAIT3_STATE;
            end

            // wait for reult
            WAIT3_STATE: begin
                if (cnt == 10)
                    next_state = INV1_STATE;
                else
                    next_state = WAIT3_STATE;
            end

            // (1 - d*x1*x2*y1*y2)^-1  save 
            INV1_STATE: begin
                next_state = WAIT4_STATE;
            end

            // wait for reult
            WAIT4_STATE: begin
                if (inv_done)
                    next_state = INV2_STATE;
                else
                    next_state = WAIT4_STATE;
            end

            // (1 + d*x1*x2*y1*y2)^-1 save
            INV2_STATE: begin
                next_state = WAIT5_STATE;
            end

            // wait for reult
            WAIT5_STATE: begin
                if (inv_done)
                    next_state = INV_END_STATE;
                else
                    next_state = WAIT5_STATE;
            end

            // inv2 are done
            INV_END_STATE: begin
                next_state = WAIT6_STATE;
            end

            // wait for reult
            WAIT6_STATE: begin
                if (cnt == 10)
                    next_state = END_STATE;
                else
                    next_state = WAIT6_STATE;
            end

            // END
            END_STATE: begin
                if (i_ok)
                    next_state = IDLE_STATE;
                else
                    next_state = END_STATE;
            end

            default: next_state = IDLE_STATE;
        endcase
    end

    // x1, y1, x2, y2;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            x1        <=      'b0;
            y1        <=      'b0;
            x2        <=      'b0;
            y2        <=      'b0;
        end
        else begin
            case (state)
                // IDLE
                IDLE_STATE: begin
                    if (i_vld) begin
                        if      ( i_a_mode == 0 && i_a_x == 253'b0 && i_a_y == 253'b1 )
                            ;
                        else if ( i_b_mode == 0 && i_b_x == 253'b0 && i_b_y == 253'b1 )
                            ;
                        else begin 
                            if ( i_b_mode == 0 ) begin
                                x1        <=      i_a_x;
                                y1        <=      i_a_y;
                                x2        <=      i_b_x;
                                y2        <=      i_b_y;
                            end
                            else begin
                                x1        <=      i_b_x;
                                y1        <=      i_b_y;
                                x2        <=      i_a_x;
                                y2        <=      i_a_y;
                            end
                        end
                    end
                    else begin
                        x1        <=      x1;
                        y1        <=      y1;
                        x2        <=      x2;
                        y2        <=      y2;
                    end
                end

                default: begin
                        x1        <=      x1;
                        y1        <=      y1;
                        x2        <=      x2;
                        y2        <=      y2;
                end
            endcase
        end
    end

    // cnt
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            cnt <= 'b0;
        end
        else begin
            case (state)
                // Reset in advance
                X2Y1_STATE: begin
                    cnt <= 0;
                end
                // Wait for 8 period
                WAIT1_STATE: begin
                    cnt <= cnt + 1;
                end
                
                // Reset in advance
                X12Y12_STATE: begin
                    cnt <= 0;
                end
                // Wait for 9 period
                WAIT2_STATE: begin
                    cnt <= cnt + 1;
                end
                
                // Reset in advance
                DXY_STATE: begin
                    cnt <= 0;
                end
                // Wait for 10 period
                WAIT3_STATE: begin
                    cnt <= cnt + 1;
                end
                
                // Reset in advance
                INV2_STATE: begin
                    cnt <= 0;
                end
                // Wait for 10 period
                WAIT5_STATE: begin
                    cnt <= cnt + 1;
                end
                
                // Reset in advance
                INV_END_STATE: begin
                    cnt <= 0;
                end
                // Wait for 10 period
                WAIT6_STATE: begin
                    cnt <= cnt + 1;
                end

                default: cnt <= 0;
            endcase
        end
    end

    // tmp_reg1
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            tmp1 <= 'b0;
        end
        else begin
            case (state)
                // IDLE
//                IDLE_STATE: begin
//                    ;
//                end

                // SAVE (-a*x1 + y1)
                SAVE_STATE: begin
                    tmp1 <= add_out;
                end

                // SAVE (x1*y2)
                AX1Y2_STATE: begin
                    tmp1 <= mul_rslt;
                end

                default: tmp1 <= tmp1;
            endcase
        end
    end


    // lvs_ouput_mode
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            lvs_ouput_mode <= 2'b0;
        end
        else begin
            case (state)
                // IDLE
                IDLE_STATE: begin
                    if (i_vld) begin
                        if (i_a_mode == 0 && i_b_mode == 0) begin
                            lvs_ouput_mode <= 2'b0;
                        end
                        else if (i_a_mode == 1 && i_b_mode == 1) begin
                            lvs_ouput_mode <= 2'b1;
                        end
                        else begin
                            lvs_ouput_mode <= 2'b10;
                        end
                    end
                    else begin
                        lvs_ouput_mode <= 2'b0;
                    end
                end

                default: lvs_ouput_mode <= lvs_ouput_mode;
                // end of this part need to be 0
            endcase
        end
    end

    // lvs1
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_lvs1_vld  <=   1'b0;
            o_lvs1      <=    'b0;
        end
        else begin
            case (state)
                IDLE_STATE: begin
                    o_lvs1_vld  <=   1'b0;
                    o_lvs1      <=    'b0;
                end

                // lvs1
                LVS1_OUT_STATE: begin
                    o_lvs1_vld  <=   1'b1;
                    o_lvs1      <=   mul_rslt;
                end

                default: begin
                    o_lvs1_vld  <=   o_lvs1_vld;
                    o_lvs1      <=   o_lvs1;
                end
            endcase
        end
    end

    // lvs2
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_lvs2_vld  <=    1'b0;
            o_lvs2      <=     'b0;
        end
        else begin
            case (state)
                IDLE_STATE: begin
                    o_lvs2_vld  <=   1'b0;
                    o_lvs2      <=    'b0;
                end

                // lvs2
                AX1Y2_STATE: begin
                    o_lvs2_vld  <=    1'b1;
                    o_lvs2      <=    mul_rslt;
                end
                default: begin
                    o_lvs2_vld  <=    o_lvs2_vld;
                    o_lvs2      <=    o_lvs2;
                end
            endcase
        end
    end

    // lvs3
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_lvs3_vld  <=    1'b0;
            o_lvs3      <=     'b0;
        end
        else begin
            case (state)
                IDLE_STATE: begin
                    o_lvs3_vld  <=   1'b0;
                    o_lvs3      <=    'b0;
                end
                // lvs3
                X12Y12_STATE: begin
                    o_lvs3_vld  <=    1'b1;
                    o_lvs3      <=    mul_rslt;
                end
                default: begin
                    o_lvs3_vld  <=    o_lvs3_vld;
                    o_lvs3      <=    o_lvs3;
                end
            endcase
        end
    end

    // lvs4
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_lvs4_vld  <=    1'b0;
            o_lvs4      <=     'b0;
        end
        else begin
            case (state)
                IDLE_STATE: begin
                    o_lvs4_vld  <=   1'b0;
                    o_lvs4      <=    'b0;
                end
                // lvs4
                DXY_STATE: begin
                    o_lvs4_vld  <=    1'b1;
                    o_lvs4      <=    mul_rslt;
                end
                default: begin
                    o_lvs4_vld  <=    o_lvs4_vld;
                    o_lvs4      <=    o_lvs4;
                end
            endcase
        end
    end


    // o_res & o_res_vld
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_res_vld <= 'b0;
            o_res_x   <= 'b0;
            o_res_y   <= 'b0;
        end
        else begin
            case (state)
                // IDLE
                IDLE_STATE: begin
                    if (i_vld) begin
                        if      ( i_a_mode == 0 && i_a_x == 253'b0 && i_a_y == 253'b1) begin
                            o_res_vld <= 'b1;
                            o_res_x   <= i_b_x;
                            o_res_y   <= i_b_y;
                        end
                        else if ( i_b_mode == 0 && i_b_x == 253'b0 && i_b_y == 253'b1) begin
                            o_res_vld <= 'b1;
                            o_res_x   <= i_a_x;
                            o_res_y   <= i_a_y;
                        end
                        else begin
                            o_res_vld <= 'b0;
                            o_res_x   <= 'b0;
                            o_res_y   <= 'b0;
                        end
                    end
                    else begin
                        o_res_vld <= 'b0;
                        o_res_x   <= 'b0;
                        o_res_y   <= 'b0;
                    end
                end

                // tmp save
                X12Y12_STATE: begin
                    o_res_vld <= 'b0;
                    o_res_x   <= o_res_x;
                    o_res_y   <= add_out;
                end

                // tmp save
                AX1Y2_OUT_STATE: begin
                    o_res_vld <= 'b0;
                    o_res_x   <= o_res_x;
                    o_res_y   <= add_out;
                end

                // tmp save
                INV1_STATE: begin
                    o_res_vld <= 'b0;
                    o_res_x   <= mul_rslt;
                    o_res_y   <= o_res_y;
                end

                // x_res
                WAIT5_STATE: begin
                    if (cnt == 10) begin
                        o_res_vld <= 'b0;
                        o_res_x   <= o_res_x;
                        o_res_y   <= mul_rslt;
                    end
                end

                // y_res
                INV_END_STATE: begin
                    o_res_vld <= 'b0;
                    o_res_x   <= o_res_x;
                    o_res_y   <= o_res_y;
                end

                // x_res
                END_STATE: begin
                    o_res_vld <= 'b1;
                    o_res_x   <= mul_rslt;
                    o_res_y   <= o_res_y;
                end

                default: begin
                    o_res_vld <= 'b0;
                    o_res_x   <= o_res_x;
                    o_res_y   <= o_res_y;
                end

            endcase
        end
    end


endmodule
