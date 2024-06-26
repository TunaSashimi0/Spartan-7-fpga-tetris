module game_clock(
    input logic clk,
    input logic rst,
    input logic pause,
    output logic game_clk
    );

    logic [31:0] counter;
    always @ (posedge clk) begin
        if (!pause) begin
            if (rst) begin
                counter <= 0;
                game_clk <= 0;
            end else begin
                if (counter == 25000000) begin // 1 Hz
                    counter <= 0;
                    game_clk <= 1;
                end else begin
                    counter <= counter + 1;
                    game_clk <= 0;
                end
            end
        end
    end

endmodule
