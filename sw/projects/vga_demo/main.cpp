#include "lexington.h"
#include "snake.h"


const rgb_t TEST_BMP[] = {
    VGA_GREEN,  VGA_WHITE,  VGA_RED,
    VGA_CYAN,   VGA_WHITE,  VGA_YELLOW
};
#define X_SIZE  3
#define Y_SIZE  2


void led_main_loop();


int main() {

    time_init(TIME_INIT_10MHz);
    for (uint32_t i=0; i<16; i++) {
        gpio_mode(GPIO_LED, i, OUTPUT);
        gpio_write(GPIO_LED, i, LOW);
    }
    gpio_write(GPIO_LED, 15, HIGH);
    gpio_mode(GPIO_BTN, GPIO_BTN_U, INPUT);
    gpio_mode(GPIO_BTN, GPIO_BTN_R, INPUT);
    gpio_mode(GPIO_BTN, GPIO_BTN_D, INPUT);
    gpio_mode(GPIO_BTN, GPIO_BTN_L, INPUT);


    // typedef void (*_vga_draw_t) (int32_t, int32_t, const rgb_t*, int32_t, int32_t, int32_t);
    // _vga_draw_t _vga_draw[4][4] {
    //     {
    //         vga_draw_bitmap<0, false, false>,
    //         vga_draw_bitmap<90, false, false>,
    //         vga_draw_bitmap<180, false, false>,
    //         vga_draw_bitmap<270, false, false>
    //     },
    //     {
    //         vga_draw_bitmap<0, true, false>,
    //         vga_draw_bitmap<90, true, false>,
    //         vga_draw_bitmap<180, true, false>,
    //         vga_draw_bitmap<270, true, false>
    //     },
    //     {
    //         vga_draw_bitmap<0, false, true>,
    //         vga_draw_bitmap<90, false, true>,
    //         vga_draw_bitmap<180, false, true>,
    //         vga_draw_bitmap<270, false, true>
    //     },
    //     {
    //         vga_draw_bitmap<0, true, true>,
    //         vga_draw_bitmap<90, true, true>,
    //         vga_draw_bitmap<180, true, true>,
    //         vga_draw_bitmap<270, true, true>
    //     }
    // };
    // for (int32_t col=0; col<4; col++) {
    //     for (int32_t row=0; row<4; row++) {
    //         int32_t x = 100 + (30*row);
    //         int32_t y = 50 + (30*col);
    //         int32_t x_size, y_size;
    //         if (0==col || 2==col) {
    //             x_size = X_SIZE;
    //             y_size = Y_SIZE;
    //         } else {
    //             x_size = Y_SIZE;
    //             y_size = X_SIZE;
    //         }
    //         vga_fill_rect(x, y, (2*x_size)+2, (2*y_size)+2, VGA_GRAY);
    //         _vga_draw[col][row](
    //             x+1, y+1,
    //             TEST_BMP,
    //             X_SIZE, Y_SIZE, 2
    //         );
    //         vga_draw_pixel(x, y, VGA_MAGENTA);
    //     }
    // }

    Snake::init();

    while (true) {
        led_main_loop();
        Snake::main_loop();
    }

}


void led_main_loop() {
    static const uint32_t BLINK_DELAY = 1000 / 15;
    static uint32_t prev_blink = 0;
    static uint32_t i = 1;
    static bool dir = false;

    uint32_t curr_millis = millis();
    if (curr_millis >= prev_blink + BLINK_DELAY) {
        prev_blink = curr_millis;
        if (dir) {
            // Right-to-left (ascending)
            gpio_write(GPIOA, i, LOW);
            i++;
            gpio_write(GPIOA, i, HIGH);
            if (15 == i) {
                dir = false;
            }
        } else {
            // Left-to-right (descending)
            gpio_write(GPIOA, i, LOW);
            i--;
            gpio_write(GPIOA, i, HIGH);
            if (0 == i) {
                dir = true;
            }
        }
    }
}
