`include "common_define.vh"

module ped64_no_rom#(
    parameter INPUT_SIZE = 32,
    parameter FIELD_SIZE = 253
)(
    // input
    input                           i_clk,
    input                           i_rst_n,
    input                           i_vld,
    input [INPUT_SIZE-1:0]          i_a,
    input [2:0]                     i_mode,      // 000=U8, 001=U16, 010=U32, 100=I8, 101=I16, 110=I32 
    input                           i_res_rdy,
    input                           i_lvs_rdy,

    // output
    output reg                      o_res_vld,
    output reg [FIELD_SIZE-1:0]     o_res,
    output reg                      o_lvs_vld,
    output reg [FIELD_SIZE-1:0]     o_lvs,       // all leaves in field
    output reg                      o_rdy,
    output reg                      o_last,       // last leaves
    //  ul cfg interface
    output ul_req,
    output reg [32-1:0] ul_addr,
    input ul_valid,
    input [256-1:0] ul_cfg_data_chx
    );

    // -------------------- parameter -------------------- 
    // FSM
    localparam IDLE_STATE           =        8'b0000_0000; 
    localparam SAVE_STATE           =        8'b0000_0001;     // 01
    localparam JUDGE_STATE          =        8'b0000_0010;     // 02
    localparam RAM1_STATE           =        8'b0000_0011;     // 03
    localparam RAM2_STATE           =        8'b0000_0100;     // 04
    localparam CAL_START_STATE      =        8'b0000_0101;     // 05
    localparam CAL_STATE            =        8'b0000_0110;     // 06
    localparam WAIT_STATE           =        8'b0000_0111;     // 07
    localparam END_STATE            =        8'b0000_1000;     // 08

    // PADDING
    localparam PADDING_HEAD         =       2'b00;           // head

    localparam PADDING_MODEI8       =       8'h4;             // variant : I8  - 0x4
    localparam PADDING_MODEI16      =       8'h5;             //           I16 - 0x5
    localparam PADDING_MODEI32      =       8'h6;             //           I32 - 0x6
    localparam PADDING_MODEU8       =       8'h9;             //           U8  - 0x9
    localparam PADDING_MODEU16      =       8'hA;             //           U16 - 0xA
    localparam PADDING_MODEU32      =       8'hB;             //           U32 - 0xB
    
    localparam PADDING_SIZEI8       =      16'h8;             // size    : I8  - 0d8
    localparam PADDING_SIZEI16      =      16'h10;            //           I16 - 0d16
    localparam PADDING_SIZEI32      =      16'h20;            //           I32 - 0d32
    localparam PADDING_SIZEU8       =      16'h8;             //           U8  - 0d8
    localparam PADDING_SIZEU16      =      16'h10;            //           U16 - 0d16
    localparam PADDING_SIZEU32      =      16'h20;            //           U32 - 0d32


    // -------------------- reg & wire -------------------- 
    // FSM
    reg [7:0]                   state, next_state;
    
    // save input
    reg [64-1:0]                padding;

    // add_points
    reg [FIELD_SIZE-1:0]        res_x;
    reg [FIELD_SIZE-1:0]        res_y;
    reg [FIELD_SIZE-1:0]        add_x;
    reg [FIELD_SIZE-1:0]        add_y;
    reg [FIELD_SIZE-1:0]        lvs;
    reg                         add_vld, i_a_mode, i_b_mode, i_ok;

    wire                        add_res_vld, o_lvs1_vld, o_lvs2_vld, o_lvs3_vld, o_lvs4_vld;
    wire [FIELD_SIZE-1:0]       o_res_x, o_res_y, o_lvs1, o_lvs2, o_lvs3, o_lvs4;
    //rom
    reg                         rom_rd_en;
    reg[8-1:0]                  rom_rd_addr;
    wire[256-1:0]               rom_rd_data;

    // cnt
    reg [8-1:0]                 cnt;   // \u53ea\u80fd\u662f 8 \u4f4d\uff0c\u548cdata\u5730\u5740\u5bf9\u5e94
    reg [2:0]                   lvs_out_cnt;
    reg [10:0]                  lvs_cnt;

    // tmp
    wire tmp_paddingcnt = padding[cnt];
    wire tmp_paddingcnt1 = padding[cnt+1];
    // Instantiate the add_points
    add_points #(
        .FIELD_SIZE(FIELD_SIZE)
    ) dut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_vld(add_vld),
        .i_a_x(res_x),
        .i_a_y(res_y),
        .i_a_mode(i_a_mode),
        .i_b_x(add_x),
        .i_b_y(add_y),
        .i_b_mode(i_b_mode),
        .i_ok(i_ok),
        .o_res_vld(add_res_vld),
        .o_res_x(o_res_x),
        .o_res_y(o_res_y),
        .o_lvs1_vld(o_lvs1_vld),
        .o_lvs1(o_lvs1),
        .o_lvs2_vld(o_lvs2_vld),
        .o_lvs2(o_lvs2),
        .o_lvs3_vld(o_lvs3_vld),
        .o_lvs3(o_lvs3),
        .o_lvs4_vld(o_lvs4_vld),
        .o_lvs4(o_lvs4)
    );
    // Instantiate the add_points
    /*
    ped64_rom #(
        .ADDR_WIDTH(8),         // 2^5 = 32 entries
        .DATA_WIDTH(256)        // \u6bcf\u4e2a\u6570\u636e 256bit
    ) u_ped64_rom (
        .i_clk      (i_clk),            // \u65f6\u949f\u8f93\u5165
        .i_rd_en    (rom_rd_en),    // \u8bfb\u4f7f\u80fd
        .i_rd_addr  (rom_rd_addr),// \u5730\u5740\u8f93\u5165
        .o_rd_data  (rom_rd_data) // \u6570\u636e\u8f93\u51fa
    );*/
// -------------------- ul logic -------------------- // // modify by xianwei
    reg rom_rd_en_delay1;
    wire [32-1:0] ul_addr_nxt;
assign ul_req = !rom_rd_en_delay1 && rom_rd_en;
assign ul_addr_nxt = {`PED64_ID,8'h00,rom_rd_addr};
reg bypass_rom;
reg [256-1:0] ul_cfg_data_chx_lat;

always @(posedge i_clk or negedge i_rst_n) 
begin:DELAY1_DFFS
    if(~i_rst_n)
        begin
            rom_rd_en_delay1 <= 1'b0;
            ul_cfg_data_chx_lat <= 256'd0;
        end
    else
        begin
            rom_rd_en_delay1 <= rom_rd_en;
            ul_cfg_data_chx_lat <= ul_cfg_data_chx;
        end
end

always @(posedge i_clk or negedge i_rst_n) 
begin:BYP_ROM_RD_PHASE
    if(~i_rst_n)
        bypass_rom <= 1'b0;
    else if(state == RAM2_STATE)
        bypass_rom <= 1'b0;
    else if(state == JUDGE_STATE && (!padding[cnt+1]))
        bypass_rom <= 1;
end

always @(posedge i_clk or negedge i_rst_n) 
begin:LAT_ADDR
    if(~i_rst_n)
        ul_addr <= 32'd0;
    else if(ul_req)
        ul_addr <= ul_addr_nxt;
end

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
                    next_state = SAVE_STATE;
                end
                else begin
                    next_state = IDLE_STATE;
                end
            end

            // save & padding state
            SAVE_STATE: begin
                next_state = JUDGE_STATE;
            end


            // get data from RAM
            JUDGE_STATE: begin
                if(cnt == 63)begin
                    next_state = END_STATE;
                end
                else 
                    next_state = RAM1_STATE;
            end
            // get x from RAM
            RAM1_STATE: begin
                next_state = (ul_valid || bypass_rom) ? RAM2_STATE : state;
            end
            // get y from RAM
            RAM2_STATE: begin
                next_state = CAL_START_STATE;
            end
            
            // use add_points to calculate
            CAL_START_STATE: begin
                next_state = CAL_STATE;
            end
            // use add_points to calculate
            CAL_STATE: begin
                if (add_res_vld) begin
                    next_state = WAIT_STATE;
                end
                else begin
                    next_state = CAL_STATE;
                end
            end

            // wait for lvs
            WAIT_STATE: begin
                if (i_a_mode == 1 && i_b_mode == 1) begin
                    if (lvs_out_cnt == 5 && add_res_vld ==1 && i_lvs_rdy == 1 && o_lvs_vld == 1)begin
                        next_state = JUDGE_STATE;
                    end
                    else begin
                        next_state = WAIT_STATE;
                    end
                end
                else if (i_a_mode ^ i_b_mode == 1) begin
                    if (i_a_mode == 0 && res_x == 'b0 && res_y == 'b1) begin
                        next_state = JUDGE_STATE;
                    end
                    else if (i_b_mode == 0 && add_x == 'b0 && add_y == 'b1) begin
                        next_state = JUDGE_STATE;
                    end
                    else if (lvs_out_cnt == 2 && add_res_vld ==1 && i_lvs_rdy == 1 && o_lvs_vld == 1)begin
                        next_state = JUDGE_STATE;
                    end
                    else begin
                        next_state = WAIT_STATE;
                    end
                end
                else begin
                    next_state = JUDGE_STATE;
                end
            end

            // end wait for res
            END_STATE: begin
                if (i_res_rdy) begin
                    next_state = IDLE_STATE;
                end
                else begin
                    next_state = END_STATE;
                end
            end
            
            default : begin
                next_state = IDLE_STATE;
            end
        endcase
    end

    // padding
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            padding <= 'b0;
        end
        else begin
            case (state)
                // IDLE
                IDLE_STATE: begin
                    if (i_vld) begin
                        if (i_mode == 3'b000) begin  // U8
                            padding   <=   {30'b0, i_a[7:0], PADDING_SIZEU8, PADDING_MODEU8, PADDING_HEAD};
                        end
                        else if (i_mode == 3'b001) begin  // U16
                            padding   <=   {22'b0, i_a[15:0], PADDING_SIZEU16, PADDING_MODEU16, PADDING_HEAD};
                        end
                        else if (i_mode == 3'b010) begin  // U32
                            padding   <=   {6'b0, i_a[31:0], PADDING_SIZEU32, PADDING_MODEU32, PADDING_HEAD};
                        end
                        
                        else if (i_mode == 3'b100) begin  // I8
                            padding   <=   {30'b0, i_a[7:0], PADDING_SIZEI8, PADDING_MODEI8, PADDING_HEAD};
                        end
                        else if (i_mode == 3'b101) begin  // I16
                            padding   <=   {22'b0, i_a[15:0], PADDING_SIZEI16, PADDING_MODEI16, PADDING_HEAD};
                        end
                        else if (i_mode == 3'b110) begin  // I32
                            padding   <=   {6'b0, i_a[31:0], PADDING_SIZEI32, PADDING_MODEI32, PADDING_HEAD};
                        end
                    end
                    else begin
                        padding   <=   64'b0;
                    end
                end

                default: padding <= padding;
            endcase
        end
    end

    // cnt 
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n)
                cnt <= 'b0 ;                                
            else begin
                case (state)
                    IDLE_STATE: begin
                        cnt <= 0;
                    end
                    JUDGE_STATE: begin
                        cnt <= cnt + 1;
                    end
                    default:  cnt <= cnt;
                endcase
            end                                  
        end     
    
    // add_vld
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n) begin
                add_vld <= 'b0;
            end                                   
            else begin
                case (state)
                    CAL_START_STATE: begin
                            add_vld <= 'b1;
                        end
                    default: begin
                        add_vld <= 'b0;
                    end
                endcase
            end
        end

    // i_ok
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n) begin
                i_ok <= 'b0;
            end                                   
            else begin
                case (state)
                    JUDGE_STATE: begin
                        i_ok <= 'b1;
                    end
                    default: begin
                        i_ok <= 'b0;
                    end
                endcase
            end
        end
    
    // o_res_vld && o_res
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n) begin
                o_res_vld <= 'b0;
                o_res     <= 'b0;
            end                                   
            else begin
                case (state)
                    IDLE_STATE: begin
                        o_res_vld <= 'b0;
                        o_res     <= 'b0;
                    end
                    JUDGE_STATE: begin
                        if (cnt == 63) begin
                            o_res_vld <= 'b1;
                            o_res     <= res_x;
                        end
                        else begin
                            o_res_vld <= 'b0;
                            o_res     <= o_res;
                        end
                    end
                    END_STATE: begin
                        if (i_res_rdy) begin
                            o_res_vld <= 'b0;
                            o_res     <= 'b0;
                        end
                        else begin
                            o_res_vld <= 'b1;
                            o_res     <= o_res;
                        end
                    end
                    default: begin
                        o_res_vld <= 'b0;
                        o_res     <= o_res;
                    end
                endcase
            end
        end
    
    // o_rdy
    always @(posedge i_clk or negedge i_rst_n) begin                                        
        if(~i_rst_n) begin
            o_rdy <= 1'b0;
        end                                      
        else begin
            case (state)
                END_STATE,IDLE_STATE: begin
                    if (i_res_rdy) begin
                        o_rdy <= 1'b1;
                    end
                    else begin
                        o_rdy <= 1'b0;
                    end
                end 
                default: begin
                    o_rdy <= 1'b0;
                end
            endcase
        end            
    end                                          

    // res
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n) begin
                res_x <= 'b0;
                res_y <= 'b0;
                add_x <= 'b0;
                add_y <= 'b0;
            end                                   
            else begin
                case (state)
                    IDLE_STATE: begin
                        if (i_vld) begin
                            res_x <= 'b0;
                            res_y <= 'b1;
                            add_x <= 'b0;
                            add_y <= 'b0;
                        end
                        else begin
                            res_x <= res_x;
                            res_y <= res_y;
                            add_x <= add_x;
                            add_y <= add_y;
                        end
                    end

                    RAM2_STATE: begin
                        if (padding[cnt] == 1) begin
                            res_x <= res_x;
                            res_y <= res_y;
                            //add_x <= rom_rd_data[FIELD_SIZE-1:0];
                            add_x <= ul_cfg_data_chx_lat[FIELD_SIZE-1:0];// modify by xianwei
                            add_y <= add_y;
                        end
                        else begin
                            res_x <= res_x;
                            res_y <= res_y;
                            add_x <= 'b0;
                            add_y <= add_y;
                        end
                    end

                    CAL_START_STATE: begin
                        if (padding[cnt] == 1) begin
                            res_x <= res_x;
                            res_y <= res_y;
                            add_x <= add_x;
                            // add_y <= rom_rd_data[FIELD_SIZE-1:0];
                             add_y <= ul_cfg_data_chx_lat[FIELD_SIZE-1:0]; // modify by xianwei
                        end
                        else begin
                            res_x <= res_x;
                            res_y <= res_y;
                            add_x <= add_x;
                            add_y <= 'b1;
                        end
                    end
                    
                    CAL_STATE:begin
                        if (add_res_vld) begin
                            res_x <= o_res_x;
                            res_y <= o_res_y;
                            add_x <= add_x;
                            add_y <= add_y;
                        end
                    end
                
                default: begin
                    res_x <= res_x;
                    res_y <= res_y;
                    add_x <= add_x;
                    add_y <= add_y;
                end
                endcase
            end           
        end   

    // res_a_mode
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n) begin
                i_a_mode <= 'b0;
            end                                   
            else begin
                case (state)
                    IDLE_STATE: begin
                        i_a_mode <= 'b0;
                    end

                    CAL_START_STATE: begin
                        if (cnt == 27) begin
                            i_a_mode <= 'b1;
                        end
                        else begin
                            i_a_mode <= i_a_mode;
                        end
                    end

                    END_STATE: begin
                        i_a_mode <= 0;
                    end
                
                default: begin
                    i_a_mode <= i_a_mode;
                end
                endcase
            end           
        end   
    // res_b_mode
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n) begin
                i_b_mode <= 'b0;
            end                                   
            else begin
                case (state)
                    IDLE_STATE: begin
                        i_b_mode <= 'b0;
                    end

                    CAL_START_STATE: begin
                        case (padding[9:2])
                        
                        PADDING_MODEI8, PADDING_MODEU8: begin
                            if (cnt >= 26 && cnt <= 33) begin
                                i_b_mode <= 'b1;
                            end
                            else begin
                                i_b_mode <= 'b0;
                            end
                        end
                        
                        PADDING_MODEI16, PADDING_MODEU16: begin
                            if (cnt >= 26 && cnt <= 41) begin
                                i_b_mode <= 'b1;
                            end
                            else begin
                                i_b_mode <= 'b0;
                            end
                        end
                        
                        PADDING_MODEI32, PADDING_MODEU32: begin
                            if (cnt >= 26 && cnt <= 57) begin
                                i_b_mode <= 'b1;
                            end
                            else begin
                                i_b_mode <= 'b0;
                            end
                        end
                        default: begin
                            i_b_mode <= i_b_mode;
                        end
                        endcase
                    end
                
                default: begin
                    i_b_mode <= i_b_mode;
                end
                endcase
            end           
        end   
    
    // lvs
    always @(posedge i_clk or negedge i_rst_n) begin                                        
        if(~i_rst_n) begin
            o_lvs_vld  <=  1'b0;
            o_lvs      <=   'b0;
        end                                   
        else begin
            case (state)
                IDLE_STATE: begin
                    o_lvs_vld  <=  1'b0;
                    o_lvs      <=   'b0;
                end

                CAL_STATE, WAIT_STATE:begin
                    if (i_a_mode == 1 && i_b_mode == 1) begin
                        if (lvs_out_cnt == 0 && o_lvs1_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_lvs1;
                            end
                        end
                        else if (lvs_out_cnt == 1 && o_lvs2_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_lvs2;
                            end
                        end
                        else if (lvs_out_cnt == 2 && o_lvs3_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld ==1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_lvs3;
                            end
                        end
                        else if (lvs_out_cnt == 3 && o_lvs4_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld ==1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_lvs4;
                            end
                        end
                        else if (lvs_out_cnt == 4 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld ==1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_res_x;
                            end
                        end
                        else if (lvs_out_cnt == 5 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld ==1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_res_y;
                            end
                        end
                        else begin
                            o_lvs_vld  <=  1'b0;
                            o_lvs      <=   'b0;  // \u6539\u4e00\u4e0b
                        end
                    end

                    else if (i_a_mode ^ i_b_mode == 1) begin
                        if (lvs_out_cnt == 0 && o_lvs4_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld ==1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_lvs4;
                            end
                        end
                        else if (lvs_out_cnt == 1 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld ==1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_res_x;
                            end
                        end
                        else if (lvs_out_cnt == 2 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld ==1) begin
                                o_lvs_vld  <=  1'b0;
                                o_lvs      <=  'b0;
                            end
                            else begin
                                o_lvs_vld  <=  1'b1;
                                o_lvs      <=  o_res_y;
                            end
                        end
                    end
                    else begin
                        o_lvs_vld  <=  1'b0;
                        o_lvs      <=   'b0;
                    end
                end

                default: begin
                    o_lvs_vld  <=  1'b0;
                    o_lvs      <=  o_lvs;
                end
            endcase
        end   
    end        
    // lvs_out_cnt
    always @(posedge i_clk or negedge i_rst_n) begin                                        
        if(~i_rst_n) begin
            lvs_out_cnt  <=  'b0;
        end                                   
        else begin
            case (state)
                IDLE_STATE: begin
                    lvs_out_cnt  <=  'b0;
                end
                CAL_START_STATE: begin
                    lvs_out_cnt  <=  'b0;
                end
                CAL_STATE, WAIT_STATE:begin
                    if (i_a_mode == 1 && i_b_mode == 1) begin
                        if (lvs_out_cnt == 0 && o_lvs1_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else if (lvs_out_cnt == 1 && o_lvs2_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else if (lvs_out_cnt == 2 && o_lvs3_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else if (lvs_out_cnt == 3 && o_lvs4_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else if (lvs_out_cnt == 4 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else if (lvs_out_cnt == 5 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else begin
                            lvs_out_cnt <= lvs_out_cnt;
                        end

                    end
                    else if (i_a_mode ^ i_b_mode == 1) begin
                        if (lvs_out_cnt == 0 && o_lvs4_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else if (lvs_out_cnt == 1 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else if (lvs_out_cnt == 2 && add_res_vld ==1) begin
                            if(i_lvs_rdy && o_lvs_vld == 1) begin
                                lvs_out_cnt  <=  lvs_out_cnt+1;  
                            end
                            else begin
                                lvs_out_cnt <= lvs_out_cnt;
                            end
                        end
                        else begin
                            lvs_out_cnt <= lvs_out_cnt;
                        end
                    end
                    else begin
                        lvs_out_cnt <= lvs_out_cnt;
                    end
                end

                default: begin
                    lvs_out_cnt <= lvs_out_cnt;
                end
            endcase
        end   
    end     
    // o_last
    always @(posedge i_clk or negedge i_rst_n) begin                                        
        if(~i_rst_n) begin
            o_last <= 1'b0;
        end                                      
        else begin
            case (state)
                CAL_STATE, WAIT_STATE: begin
                    if (lvs_out_cnt == 5 && add_res_vld ==1) begin
                        if(i_lvs_rdy && o_lvs_vld ==1) begin
                            o_last <= 1'b0;
                        end
                        else begin
                            case (padding[9:2])
                            
                            PADDING_MODEI8, PADDING_MODEU8: begin
                                if (cnt == 33) begin
                                    o_last <= 'b1;
                                end
                                else begin
                                    o_last <= 'b0;
                                end
                            end
                            
                            PADDING_MODEI16, PADDING_MODEU16: begin
                                if (cnt == 41) begin
                                    o_last <= 'b1;
                                end
                                else begin
                                    o_last <= 'b0;
                                end
                            end
                            
                            PADDING_MODEI32, PADDING_MODEU32: begin
                                if (cnt == 57) begin
                                    o_last <= 'b1;
                                end
                                else begin
                                    o_last <= 'b0;
                                end
                            end

                            default: begin
                                o_last <= o_last;
                            end
                            endcase
                        end
                    end
                end
                default: o_last <= 1'b0;
            endcase
        end              
    end                                                                   

    // en
    always @(posedge i_clk or negedge i_rst_n)           
        begin                                        
            if(~i_rst_n) begin
                rom_rd_en <= 1'b0;
                rom_rd_addr <='b0;
            end                                        
            else begin
                case (state)
                    JUDGE_STATE: begin
                        if (padding[cnt+1] == 1) begin
                            rom_rd_en <= 1'b1;
                            rom_rd_addr <= 2*(cnt+1);
                        end
                    end 
                    RAM1_STATE: begin
                        if (padding[cnt] == 1) begin
                            rom_rd_en <= 1'b1;
                            rom_rd_addr <= 2*cnt+1;
                        end
                    end 
                    default: begin
                        rom_rd_en <= 1'b0;
                        rom_rd_addr <='b0;
                    end
                endcase
            end                                 
        end                                          


endmodule
