#include "lexington.h"
#include "snake.h"


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

    Snake::init();

    while (true) {
        led_main_loop();
        Snake::main_loop();
    }


    // // Clear screen
    // vga_fill_screen(SNAKE_BG_COLOR);

    // // Draw 


    // // Top border
    // vga_fill_rect(4, 4, VGA_WIDTH-10, 5, VGA_WHITE);
    // // Bottom border
    // vga_fill_rect(4, VGA_HEIGHT-11, VGA_WIDTH-10, 5, VGA_WHITE);
    // // Left border
    // vga_fill_rect(4, 4, 5, VGA_HEIGHT-10, VGA_WHITE);
    // // Right border
    // vga_fill_rect(VGA_WIDTH-11, 4, 5, VGA_HEIGHT-10, VGA_WHITE);

    // // Draw snake
    // vga_fill_rect(snake_x, snake_y, UNIT_SIZE, UNIT_SIZE, SNAKE_COLOR);


    // // Game loop
    // while (true) {

    //     prev_dir = dir;

    //     // Read buttons and move
    //     for (uint32_t i=0; i<speed; i+=50) {
    //         if (gpio_read(GPIO_BTN, GPIO_BTN_U) && (DOWN != dir)) {
    //             dir = UP;
    //         }
    //         else if (gpio_read(GPIO_BTN, GPIO_BTN_R) && (LEFT != dir)) {
    //             dir = RIGHT;
    //         }
    //         else if (gpio_read(GPIO_BTN, GPIO_BTN_D) && (UP != dir)) {
    //             dir = DOWN;
    //         }
    //         else if (gpio_read(GPIO_BTN, GPIO_BTN_L) && (RIGHT != dir)) {
    //             dir = LEFT;
    //         }
    //         delay(50);
    //     }

    //     // Move
    //     switch (dir) {
    //         case UP:
    //             if (snake_y > Y_MIN) {\
    //                 snake_y -= UNIT_SIZE;
    //                 vga_fill_rect(snake_x, snake_y,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);

    //             }
    //             break;
    //         case RIGHT:
    //             if (snake_x < X_MAX) {
    //                 snake_x += UNIT_SIZE;
    //                 vga_fill_rect(snake_x, snake_y,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);

    //             }
    //             break;
    //         case DOWN:
    //             if (snake_y < Y_MAX) {
    //                 snake_y += UNIT_SIZE;
    //                 vga_fill_rect(snake_x, snake_y,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);
    //             }
    //             break;
    //         case LEFT:
    //             if (snake_x > X_MIN) {
    //                 snake_x -= UNIT_SIZE;
    //                 vga_fill_rect(snake_x, snake_y,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);
    //             }
    //             break;
    //         default:
    //             // do nothing
    //             break;
    //     }
    //     switch (prev_dir) {
    //         case UP:
    //             if (snake_y > Y_MIN) {
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             VGA_BLACK);
    //                 snake_y_back -= UNIT_SIZE;
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);
    //             }
    //             break;
    //         case RIGHT:
    //             if (snake_x < X_MAX) {
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             VGA_BLACK);
    //                 snake_x_back += UNIT_SIZE;
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);
    //             }
    //             break;
    //         case DOWN:
    //             if (snake_y < Y_MAX) {
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             VGA_BLACK);
    //                 snake_y_back += UNIT_SIZE;
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);
    //             }
    //             break;
    //         case LEFT:
    //             if (snake_x > X_MIN) {
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             VGA_BLACK);
    //                 snake_x_back -= UNIT_SIZE;
    //                 vga_fill_rect(snake_x_back, snake_y_back,
    //                             UNIT_SIZE, UNIT_SIZE,
    //                             SNAKE_COLOR);
    //             }
    //             break;
    //         default:
    //             // do nothing
    //             break;
    //     }

    // }

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
