#include "lexington.h"

#define SNAKE_COLOR     VGA_CYAN

#define UNIT_SIZE       16
#define X_MIN           (1*UNIT_SIZE)
#define X_MAX           (VGA_WIDTH-(2*UNIT_SIZE))
#define Y_MIN           (1*UNIT_SIZE)
#define Y_MAX           (VGA_HEIGHT-(2*UNIT_SIZE))

#define UP      0
#define RIGHT   1
#define DOWN    2
#define LEFT    3

int main() {

    // Clear screen
    vga_fill_rect(0,0, VGA_WIDTH, VGA_HEIGHT, VGA_BLACK);

    int32_t snake_x = ((VGA_WIDTH/UNIT_SIZE) / 2) * UNIT_SIZE;
    int32_t snake_y = ((VGA_HEIGHT/UNIT_SIZE) / 2) * UNIT_SIZE;
    int32_t snake_x_back = snake_x-UNIT_SIZE;
    int32_t snake_y_back = snake_y;
    uint32_t speed = 1000;
    int8_t dir = RIGHT;

    time_init(TIME_INIT_10MHz);
    for (uint32_t i=0; i<16; i++) {
        gpio_mode(GPIO_LED, i, OUTPUT);
    }
    gpio_mode(GPIO_BTN, GPIO_BTN_U, INPUT);
    gpio_mode(GPIO_BTN, GPIO_BTN_R, INPUT);
    gpio_mode(GPIO_BTN, GPIO_BTN_D, INPUT);
    gpio_mode(GPIO_BTN, GPIO_BTN_L, INPUT);


    // Top border
    vga_fill_rect(4, 4, VGA_WIDTH-10, 5, VGA_WHITE);
    // Bottom border
    vga_fill_rect(4, VGA_HEIGHT-11, VGA_WIDTH-10, 5, VGA_WHITE);
    // Left border
    vga_fill_rect(4, 4, 5, VGA_HEIGHT-10, VGA_WHITE);
    // Right border
    vga_fill_rect(VGA_WIDTH-11, 4, 5, VGA_HEIGHT-10, VGA_WHITE);

    // Draw snake
    vga_fill_rect(snake_x*UNIT_SIZE, snake_y*UNIT_SIZE, UNIT_SIZE, UNIT_SIZE, SNAKE_COLOR);


    // Game loop
    while (true) {

        // Read buttons and move
        if (gpio_read(GPIO_BTN, GPIO_BTN_U) && (DOWN != dir)) {
            dir = UP;
        }
        else if (gpio_read(GPIO_BTN, GPIO_BTN_R) && (LEFT != dir)) {
            dir = RIGHT;
        }
        else if (gpio_read(GPIO_BTN, GPIO_BTN_D) && (UP != dir)) {
            dir = DOWN;
        }
        else if (gpio_read(GPIO_BTN, GPIO_BTN_L) && (RIGHT != dir)) {
            dir = LEFT;
        }

        // Move
        switch (dir) {

            case UP:
                if (snake_y > Y_MIN) {\
                    snake_y -= UNIT_SIZE;
                    vga_fill_rect(snake_x, snake_y,
                                UNIT_SIZE, UNIT_SIZE,
                                SNAKE_COLOR);
                    vga_fill_rect(snake_x_back, snake_y_back,
                                UNIT_SIZE, UNIT_SIZE,
                                VGA_BLACK);
                    snake_y_back -= UNIT_SIZE;
                }
                break;

            case RIGHT:
                if (snake_x < X_MAX) {
                    snake_x += UNIT_SIZE;
                    vga_fill_rect(snake_x, snake_y,
                                UNIT_SIZE, UNIT_SIZE,
                                SNAKE_COLOR);
                    vga_fill_rect(snake_x_back, snake_y_back,
                                UNIT_SIZE, UNIT_SIZE,
                                VGA_BLACK);
                    snake_x_back += UNIT_SIZE;
                }
                break;

            case DOWN:
                if (snake_y < Y_MAX) {
                    snake_y += UNIT_SIZE;
                    vga_fill_rect(snake_x, snake_y,
                                UNIT_SIZE, UNIT_SIZE,
                                SNAKE_COLOR);
                    vga_fill_rect(snake_x_back, snake_y_back,
                                UNIT_SIZE, UNIT_SIZE,
                                VGA_BLACK);
                    snake_y_back += UNIT_SIZE;
                }
                break;

            case LEFT:
                if (snake_x > X_MIN) {
                    snake_x -= UNIT_SIZE;
                    vga_fill_rect(snake_x, snake_y,
                                UNIT_SIZE, UNIT_SIZE,
                                SNAKE_COLOR);
                    vga_fill_rect(snake_x_back, snake_y_back,
                                UNIT_SIZE, UNIT_SIZE,
                                VGA_BLACK);
                    snake_x_back -= UNIT_SIZE;
                }
                break;

            default:
                // do nothing
                break;

        }

        delay(speed);

    }

    // while (1) {
    //     for (uint32_t i=0; i<15; i++) {
    //         gpio_write(GPIOA, i, HIGH);
    //         delay(BLINK_DELAY);
    //         gpio_write(GPIOA, i, LOW);
    //     }
    //     for (uint32_t i=15; i>0; i--) {
    //         gpio_write(GPIOA, i, HIGH);
    //         delay(BLINK_DELAY);
    //         gpio_write(GPIOA, i, LOW);
    //     }
    // }

}
