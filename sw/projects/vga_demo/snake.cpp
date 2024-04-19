#include "snake.h"
#include "unistd.h"


Snake::state_t Snake::state;
Snake::xyd_t Snake::head;
int32_t Snake::next_dir;
fifo<Snake::xyd_t, Snake::MAX_SIZE> Snake::body;
uint32_t Snake::step_period; // delay between steps in milliseconds (inverse speed)
uint32_t Snake::prev_step_millis;
uint32_t Snake::prev_btn_press_millis;
Snake::xy_t Snake::food;
Snake::xy_t Snake::bug;
uint32_t Snake::bug_points;


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
    vga_fill_screen(BG_COLOR);
    state = PAUSE;

    // Level 1
    // border
    vga_draw_h_line(PADDING_L-1, PADDING_T-1, VGA_WIDTH-PADDING_H, VGA_WHITE);
    vga_draw_h_line(PADDING_L-1, VGA_HEIGHT-PADDING_B-2, VGA_WIDTH-PADDING_H, VGA_WHITE);
    vga_draw_v_line(PADDING_L-1, PADDING_T-1, VGA_HEIGHT-PADDING_V, VGA_WHITE);
    vga_draw_v_line(VGA_WIDTH-PADDING_R-2, PADDING_T-1, VGA_HEIGHT-PADDING_V, VGA_WHITE);

    // starting position
    head.x = ((int32_t) (VGA_WIDTH/2) / SCALED_TILE_SIZE) * SCALED_TILE_SIZE;
    head.y = ((int32_t) (VGA_HEIGHT/2) / SCALED_TILE_SIZE) * SCALED_TILE_SIZE;
    head.dir = RIGHT;
    body.clear();

    // Draw snake in starting position
    body.clear();
    xyd_t curr = head;

    // tail
    curr.x -= 2 * SCALED_TILE_SIZE;
    body.insert(curr);
    vga_draw_bitmap<0, false, false>(
        curr.x, curr.y,
        SNAKE_TAIL_BMP,
        TILE_SIZE, TILE_SIZE,
        TILE_SCALAR
    );

    // body
    curr.x += SCALED_TILE_SIZE;
    body.insert(curr);
    vga_draw_bitmap<0, false, false>(
        curr.x, curr.y,
        SNAKE_BODY_BMP,
        TILE_SIZE, TILE_SIZE,
        TILE_SCALAR
    );

    // head
    body.insert(head);
    vga_draw_bitmap<0, false, false>(
        head.x, head.y,
        SNAKE_HEAD_BMP,
        TILE_SIZE, TILE_SIZE,
        TILE_SCALAR
    );

    // spawn_food();
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
        if (UP == btn && DOWN != head.dir) {
            next_dir = UP;
        }
        else if (RIGHT == btn && LEFT != head.dir) {
            next_dir = RIGHT;
        }
        else if (DOWN == btn && UP != head.dir) {
            next_dir = DOWN;
        }
        else if (LEFT == btn && RIGHT != head.dir) {
            next_dir = LEFT;
        }
        else {
            next_dir = head.dir;
        }
    }
}


void Snake::run() {
    // read inputs
    int32_t btn = read_btns();
    if (btn != NO_BTN) {
        /*if (SELECT == btn) {
            state = PAUSE;
        }
        else */if (UP == btn && DOWN != head.dir) {
            next_dir = UP;
        }
        else if (RIGHT == btn && LEFT != head.dir) {
            next_dir = RIGHT;
        }
        else if (DOWN == btn && UP != head.dir) {
            next_dir = DOWN;
        }
        else if (LEFT == btn && RIGHT != head.dir) {
            next_dir = LEFT;
        }
    }
    // Move
    uint32_t curr_millis = millis();
    if (curr_millis >= prev_step_millis + step_period) {
        prev_step_millis = curr_millis;


        void (*_draw_bitmap) (int32_t, int32_t, const rgb_t*, int32_t, int32_t, int32_t);
        // Erase old tail
        vga_fill_rect(
            body.peek().x, body.peek().y,
            SCALED_TILE_SIZE, SCALED_TILE_SIZE,
            BG_COLOR
        );
        body.remove();
        // Draw new tail
        switch (body.peek().dir) {
            case UP:    _draw_bitmap = vga_draw_bitmap<UP, false, false>; break;
            case RIGHT: _draw_bitmap = vga_draw_bitmap<RIGHT, false, false>; break;
            case DOWN:  _draw_bitmap = vga_draw_bitmap<DOWN, false, true>; break;
            case LEFT:  _draw_bitmap = vga_draw_bitmap<LEFT, false, true>; break;
            default:    return; // error
        }
        _draw_bitmap(
            body.peek().dir, body.peek().dir,
            SNAKE_TAIL_BMP,
            TILE_SIZE, TILE_SIZE,
            TILE_SCALAR
        );
        // Replace current head with body
        if (next_dir == head.dir) {
            // Straight
            switch (head.dir) {
                case UP:    _draw_bitmap = vga_draw_bitmap<UP, false, false>; break;
                case RIGHT: _draw_bitmap = vga_draw_bitmap<RIGHT, false, false>; break;
                case DOWN:  _draw_bitmap = vga_draw_bitmap<DOWN, false, true>; break;
                case LEFT:  _draw_bitmap = vga_draw_bitmap<LEFT, false, true>; break;
                default:    return; // error
            }
            _draw_bitmap(
                head.x, head.y,
                SNAKE_BODY_BMP,
                TILE_SIZE, TILE_SIZE,
                TILE_SCALAR
            );
        } else {
            // Turn
            int32_t angle = head.dir + next_dir;
            if (angle >= 360) {
                angle -= 360;
            }
            if (angle == (RIGHT + UP)) {
                _draw_bitmap = vga_draw_bitmap<RIGHT, false, false>;
            } else {
                _draw_bitmap = vga_draw_bitmap<UP, false, false>;
            }
            _draw_bitmap(
                head.x, head.x,
                SNAKE_BODY_TURN_BMP,
                TILE_SIZE, TILE_SIZE,
                TILE_SCALAR
            );
        }
        // Draw new head
        head.dir = next_dir;
        int32_t tmp;
        switch (head.dir) {
            case UP:
                tmp = head.y - SCALED_TILE_SIZE;
                if (tmp < Y_MIN) {
                    // game over
                    return;
                }
                head.y = tmp;
                break;
            case RIGHT:
                tmp = head.x + SCALED_TILE_SIZE;
                if (tmp > X_MAX) {
                    // game over
                    return;
                }
                head.x = tmp;
                break;
            case DOWN:
                tmp = head.y + SCALED_TILE_SIZE;
                if (tmp > Y_MAX) {
                    // game over
                    return;
                }
                head.y = tmp;
                break;
            case LEFT:
                tmp = head.x - SCALED_TILE_SIZE;
                if (tmp < X_MIN) {
                    // game over
                    return;
                }
                head.x = tmp;
                break;
            default:
                return; // error
        }
        switch (head.dir) {
            case UP:    _draw_bitmap = vga_draw_bitmap<UP, false, false>; break;
            case RIGHT: _draw_bitmap = vga_draw_bitmap<RIGHT, false, false>; break;
            case DOWN:  _draw_bitmap = vga_draw_bitmap<DOWN, false, true>; break;
            case LEFT:  _draw_bitmap = vga_draw_bitmap<LEFT, false, true>; break;
            default:    return; // error
        }
        _draw_bitmap(
            head.x, head.y,
            SNAKE_HEAD_BMP,
            TILE_SIZE, TILE_SIZE,
            TILE_SCALAR
        );
        body.insert(head);

        // DEBUG: draw-arrow
        // _draw_bitmap(
        //     head.x, head.y,
        //     ARROW_BMP,
        //     TILE_SIZE, TILE_SIZE,
        //     TILE_SCALAR
        // );
        // state = PAUSE;
        // print("X=");
        // print_int32(head.x, 10);
        // print(" Y=");
        // print_int32(head.y, 10);
        // println("");
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
