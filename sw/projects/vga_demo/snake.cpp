#include "snake.h"


const Snake::xy_t Snake::NULL_XY = {.x=-1, .y=-1};

Snake::state_t Snake::state;
Snake::xy_t Snake::head;
int32_t Snake::dir;
int32_t Snake::next_dir;
fifo<Snake::xy_t, Snake::MAX_SIZE> Snake::body;
int32_t Snake::step_period; // delay between steps in milliseconds (inverse speed)
int32_t Snake::prev_step_millis;
int32_t Snake::prev_btn_press_millis;
Snake::xy_t Snake::food;
Snake::xy_t Snake::bug;
int32_t Snake::bug_points;


void Snake::init() {
    prev_btn_press_millis = 0;
    init_menu();
}

void Snake::main_loop() {
    switch (state) {
        case MENU:
            menu();
            break;
        case PAUSE:
            pause();
            break;
        case RUN:
            run();
            break;
        default:
            break;
    }
}


void Snake::init_menu() {
    state = MENU;
}


void Snake::init_level(int32_t id) {
    // Level 0
    vga_fill_screen(BG_COLOR);
    state = PAUSE;
    head.x = ((int32_t) VGA_WIDTH / SCALED_TILE_SIZE) * SCALED_TILE_SIZE;
    head.y = ((int32_t) VGA_HEIGHT / SCALED_TILE_SIZE) * SCALED_TILE_SIZE;
    dir = RIGHT;
    body.clear();

    // Draw snake in starting position
    body.clear();
    xy_t curr = head;

    // tail
    curr.x -= 2 * SCALED_TILE_SIZE;
    body.insert(curr);
    vga_draw_bitmap<RIGHT, false, false>(
        curr.x, curr.y,
        SNAKE_TAIL_BMP,
        SCALED_TILE_SIZE, SCALED_TILE_SIZE
    );

    // body
    curr.x += SCALED_TILE_SIZE;
    body.insert(curr);
    vga_draw_bitmap<RIGHT, false, false>(
        curr.x, curr.y,
        SNAKE_BODY_BMP,
        SCALED_TILE_SIZE, SCALED_TILE_SIZE
    );

    // head
    body.insert(head);
    // vga_draw_bitmap<RIGHT, false, false>(
    //     head.x, head.y,
    //     HEAD_BMP,
    //     SCALED_TILE_SIZE, SCALED_TILE_SIZE
    // );
    vga_draw_bitmap(
        head.x, head.y,
        SNAKE_HEAD_BMP,
        SCALED_TILE_SIZE, SCALED_TILE_SIZE)
    ;

    spawn_food();
}




void Snake::menu() {
    // srand(millis());
    init_level(0);
    step_period = 750;
}


void Snake::pause() {
    int32_t btn = read_btns();
    if (btn != NO_BTN) {
        // Start
        state = RUN;
        prev_step_millis = millis();
        if (UP == btn && DOWN != dir) {
            next_dir = UP;
        }
        else if (RIGHT == btn && LEFT != dir) {
            next_dir = RIGHT;
        }
        else if (DOWN == btn && UP != dir) {
            next_dir = DOWN;
        }
        else if (LEFT == btn && RIGHT != dir) {
            next_dir = LEFT;
        }
        else {
            next_dir = dir;
        }
    }
}


void Snake::run() {
    int32_t btn = read_btns();
    if (btn != NO_BTN) {
        /*if (SELECT == btn) {
            state = PAUSE;
        }
        else */if (UP == btn && DOWN != dir) {
            next_dir = UP;
        }
        else if (RIGHT == btn && LEFT != dir) {
            next_dir = RIGHT;
        }
        else if (DOWN == btn && UP != dir) {
            next_dir = DOWN;
        }
        else if (LEFT == btn && RIGHT != dir) {
            next_dir = LEFT;
        }
    }
}




void Snake::spawn_food() {
    //TODO
}


void Snake::spawn_bug() {
    //TODO
}


// int32_t Snake::read_btns() {
//     int32_t rval = NO_BTN;
//     uint32_t curr_millis = millis();
//     if (curr_millis >= prev_btn_press_millis + DEBOUNCE_PERIOD) {
//         /*if (gpio_read(GPIO_BTN, GPIO_BTN_C)) {
//             rval = SELECT;
//         }
//         else*/ if (gpio_read(GPIO_BTN, GPIO_BTN_U)) {
//             rval = UP;
//         }
//         else if (gpio_read(GPIO_BTN, GPIO_BTN_R)) {
//             rval = RIGHT;
//         }
//         else if (gpio_read(GPIO_BTN, GPIO_BTN_D)) {
//             rval = DOWN;
//         }
//         else if (gpio_read(GPIO_BTN, GPIO_BTN_L)) {
//             rval = LEFT;
//         }
//     }
//     return rval;
// }
static inline bool btns_rising_edge(uint32_t curr, uint32_t prev, uint32_t pin) {
    return ((curr >> pin) & 0b1u) && !((prev >> pin) & 0b1u);
}
int32_t Snake::read_btns() {
    static uint32_t prev_btns = 0;

    int32_t rval = NO_BTN;
    uint32_t curr_millis = millis();
    if (curr_millis >= prev_btn_press_millis + DEBOUNCE_PERIOD) {
        uint32_t btns = GPIO_BTN->IDATA;
        /*if (btns_rising_edge(btns, prev_btns, GPIO_BTN_C)) {
            rval = SELECT;
        }
        else*/ if (btns_rising_edge(btns, prev_btns, GPIO_BTN_U)) {
            rval = UP;
        }
        else if (btns_rising_edge(btns, prev_btns, GPIO_BTN_R)) {
            rval = RIGHT;
        }
        else if (btns_rising_edge(btns, prev_btns, GPIO_BTN_D)) {
            rval = DOWN;
        }
        else if (btns_rising_edge(btns, prev_btns, GPIO_BTN_L)) {
            rval = LEFT;
        }
        prev_btns = btns;
    }
    return rval;
}
