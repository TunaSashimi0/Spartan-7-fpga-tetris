module kb_debouncer(
    input logic  [7:0]raw,
    input logic  clk,
    output logic [7:0]enabled,
    output logic [7:0]disabled
    );

    logic [7:0]debounced;
    logic [7:0]debounced_prev;
    logic [15:0] counter;

    initial begin
        debounced = 8'b0;
        debounced_prev = 8'b0;
        counter = 0;
    end

    always @ (posedge clk) begin
        // 200 Hz
        if (counter > 250000) begin
            if (counter == 250006) begin 
                counter <= 0;
            end
            debounced <= raw;
        end else begin
            counter <= counter + 1;
            debounced <= 8'b0;
        end
    end

    assign enabled = debounced;
    assign disabled = !debounced;

endmodule