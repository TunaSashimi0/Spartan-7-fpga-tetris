module randomizer(
    input logic       clk,
    output logic [2:0] random
    );

    initial begin
        random = 1;
    end

    always @ (posedge clk) begin
        if (random == 7) begin
            random <= 1;
        end else begin
            random <= random + 1;
        end
    end

endmodule