


// clock divider to generate different clock rate than the onboard clock



module rateDivider(maxTime,clk,en);

    input [27:0] maxTime;

    input clk;

    output en;

    reg [27:0] timer = 0;

    always@(posedge clk) begin

        if (timer==maxTime) 

            timer <= 0;

        else

            timer <= timer + 1;

    end

    assign en  = (timer == maxTime) ? 1 : 0;

endmodule
