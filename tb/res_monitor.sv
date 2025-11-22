
module res_monitor #(
    parameter int          DATA_WIDTH   = 256,                    // Data width (max 256)
    parameter string       MONITOR_NAME = "RES_MONITOR"           // Custom monitor identifier
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  res_valid,
    input  logic [DATA_WIDTH-1:0] res_data
);

    // Queue to store received response data
    logic [DATA_WIDTH-1:0] data_queue[$];

    // Capture data on valid signal
    reg res_valid_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            res_valid_d1 <= 1'b0;
        else
            res_valid_d1 <= res_valid;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_queue.delete();  // Clear queue on reset
        end else if (res_valid && !res_valid_d1) begin
            data_queue.push_back(res_data);
        end
    end

    // Print all captured data at simulation end
    final begin
        automatic int count = 0;
        $display("==========================================");
        $display(" %s: Simulation ended. Dumping captured response data.", MONITOR_NAME);
        $display(" Data width: %0d bits", DATA_WIDTH);
        $display(" Total responses captured: %0d", data_queue.size());
        $display("==========================================");

        if (data_queue.size() == 0) begin
            $display(" [%s] [WARNING] No res_valid signals detected!", MONITOR_NAME);
        end else begin
            foreach (data_queue[i]) begin
                count++;
                $display(" [%s] [%0d] data = 0x%h ", 
                         MONITOR_NAME, count, data_queue[i]);
            end
        end

        $display("==========================================");
    end

endmodule




//==========================================================================
// Dual-Response Monitor
//   - Captures two independent (valid,data) streams
//   - At simulation end prints them aligned in two columns
//   - Missing entries are shown as "none"
//==========================================================================
module dual_res_monitor #(
    parameter int          DATA_WIDTH0   = 256,                     // Max width for both ports
    parameter int          DATA_WIDTH1   = 256,                     // Max width for both ports
    parameter string       MONITOR_NAME = "DUAL_RES_MON"           // Identifier for log
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // ----- Stream 0 -------------------------------------------------------
    input  logic                  res_valid_0,
    input  logic [DATA_WIDTH0-1:0] res_data_0,

    // ----- Stream 1 -------------------------------------------------------
    input  logic                  res_valid_1,
    input  logic [DATA_WIDTH1-1:0] res_data_1
);

    // Queues that hold the captured data
    logic [DATA_WIDTH0-1:0] queue_0[$];
    logic [DATA_WIDTH1-1:0] queue_1[$];
    logic res_valid_0_d1;
    logic res_valid_1_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            begin
                res_valid_0_d1 <= 1'b0;
                res_valid_1_d1 <= 1'b0;
            end
        else 
            begin
                res_valid_0_d1 <= res_valid_0;
                res_valid_1_d1 <= res_valid_1;
            end
    end
    //------------------------------------------------------------------
    // Capture data for stream 0
    //------------------------------------------------------------------
   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            queue_0.delete();
        else if (res_valid_0 && (!res_valid_0_d1))
            queue_0.push_back(res_data_0);
    end

    //------------------------------------------------------------------
    // Capture data for stream 1
    //------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            queue_1.delete();
        else if (res_valid_1&& (!res_valid_1_d1))
            queue_1.push_back(res_data_1);
    end

    //------------------------------------------------------------------
    // End-of-simulation dump : side-by-side print
    //------------------------------------------------------------------
    final begin
         int i      = 0;

        $display("============================================================");
        $display(" [%s]: Simulation finished - Dual response dump", MONITOR_NAME);
        $display(" Stream 0 captured : %0d entries", queue_0.size());
        $display(" Stream 1 captured : %0d entries", queue_1.size());
        $display("------------------------------------------------------------");
        $display("   # |    STREAM_0 (hex)          |    STREAM_1 (hex)          ");
        $display("------------------------------------------------------------");

        if (queue_0.size() == 0 || queue_1.size() == 0) begin
            $display(" [%s] [WARNING] No res_valid signals detected!", MONITOR_NAME);
        end else begin
            foreach (queue_1[i]) begin
                if(queue_0[i] == queue_1[i])
                begin
                    $display(" PASS: [%s] data0 = 0x%h,data1 = 0x%h ", MONITOR_NAME, queue_0[i],queue_1[i]);
                end
                else
                begin
                    $display(" FAILED: [%s] data0 = 0x%h,data1 = 0x%h ", MONITOR_NAME, queue_0[i],queue_1[i]);
                end
                         
            end
        end

        $display("============================================================");
    end

endmodule