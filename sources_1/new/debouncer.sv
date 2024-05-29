module debouncer(
    input logic  raw,
    input logic  clk,
    output logic enabled,
    output logic disabled
    );

    logic debounced;
    logic debounced_prev;
    logic [15:0] counter;

    initial begin
        debounced = 0;
        debounced_prev = 0;
        counter = 0;
    end

    always @ (posedge clk) begin
        if (counter == 12500) begin
            counter <= 0;
            debounced <= raw;
        end else begin
            counter <= counter + 1;
        end
        debounced_prev <= debounced;
    end

    assign enabled = debounced && !debounced_prev;
    assign disabled = !debounced && debounced_prev;

endmodule
