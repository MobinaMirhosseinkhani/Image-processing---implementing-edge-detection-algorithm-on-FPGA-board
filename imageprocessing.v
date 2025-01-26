module image_processor(
    input wire clk,
    input wire rst_n,
    input wire [15:0] pixel_in,
    input wire data_valid_in,
    output reg [15:0] pixel_out,
    output reg data_valid_out,
    input wire [2:0] threshold
);

    // Parameters for RGB565 to grayscale conversion
    parameter R_COEF = 8'd77;  // 0.299 * 256
    parameter G_COEF = 8'd150; // 0.587 * 256
    parameter B_COEF = 8'd29;  // 0.114 * 256

    // Internal registers
    reg [7:0] line_buffer [639:0];
    reg [9:0] pixel_x = 0;
    reg [8:0] pixel_y = 0;
    reg [7:0] prev_gray, curr_gray;
    
    // RGB565 to Grayscale conversion
    wire [7:0] gray;
    wire [15:0] red, green, blue;
    
    // Extract RGB components from RGB565
    assign red   = {pixel_in[15:11], 3'b0};    // Convert 5 bits to 8 bits
    assign green = {pixel_in[10:5], 2'b0};     // Convert 6 bits to 8 bits
    assign blue  = {pixel_in[4:0], 3'b0};      // Convert 5 bits to 8 bits
    
    // Calculate grayscale value
    assign gray = (red * R_COEF + green * G_COEF + blue * B_COEF) >> 8;

    // Edge detection threshold
    wire [7:0] edge_value;
    assign edge_value = (curr_gray > prev_gray) ? 
                       (curr_gray - prev_gray) : 
                       (prev_gray - curr_gray);

    // Pixel processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_x <= 0;
            pixel_y <= 0;
            prev_gray <= 0;
            curr_gray <= 0;
            pixel_out <= 0;
            data_valid_out <= 0;
        end
        else begin
            if (data_valid_in) begin
                // Update gray values
                prev_gray <= curr_gray;
                curr_gray <= gray;

                // Edge detection logic
                if (edge_value > {5'b00000, threshold}) begin
                    pixel_out <= 16'hFFFF;  // White for edge
                end 
                else begin
                    pixel_out <= 16'h0000;  // Black for non-edge
                end

                // Update pixel position
                if (pixel_x == 639) begin
                    pixel_x <= 0;
                    if (pixel_y == 479)
                        pixel_y <= 0;
                    else
                        pixel_y <= pixel_y + 1;
                end
                else begin
                    pixel_x <= pixel_x + 1;
                end

                // Store pixel in line buffer
                line_buffer[pixel_x] <= gray;
                
                data_valid_out <= 1;
            end
            else begin
                data_valid_out <= 0;
            end
        end
    end

    // Additional features for future enhancement (currently commented out)
    /*
    // Vertical edge detection
    wire [7:0] vert_edge;
    reg [7:0] above_pixel;
    assign vert_edge = (curr_gray > above_pixel) ? 
                      (curr_gray - above_pixel) : 
                      (above_pixel - curr_gray);
    */

endmodule