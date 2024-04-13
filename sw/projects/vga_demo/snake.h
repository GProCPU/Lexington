#ifndef __H
#define __H

#include "lexington.h"
#include "fifo.h"


class Snake {

    public:

    // Constants and typedefs

        static const int32_t UP     = VGA_ROTATE_270;
        static const int32_t RIGHT  = VGA_ROTATE_0;
        static const int32_t DOWN   = VGA_ROTATE_90;
        static const int32_t LEFT   = VGA_ROTATE_180;
        static const int32_t SELECT = 1;
        static const int32_t NO_BTN = -1;

        static const uint32_t DEBOUNCE_PERIOD   = 10;

        static const int32_t TILE_SIZE          = 4;
        static const int32_t TILE_SCALAR        = 3;
        static const int32_t SCALED_TILE_SIZE   = (TILE_SIZE * TILE_SCALAR);
        static const int32_t NUM_BUGS           = 3;
        static const int32_t MAX_SIZE           = 32;

        static const int32_t PADDING_H = (VGA_WIDTH % TILE_SIZE);
        static const int32_t PADDING_V = (VGA_HEIGHT % TILE_SIZE);
        static const int32_t PADDING_L = ((int32_t) (PADDING_H/2));
        static const int32_t PADDING_R = (PADDING_H - PADDING_L);
        static const int32_t PADDING_T = ((int32_t) (PADDING_V/2));
        static const int32_t PADDING_B = (PADDING_V - PADDING_T);

        static const int32_t FG_COLOR = VGA_BLACK;

        #if defined(VGA_RGB332)
            static const int32_t BG_COLOR = 0x94u;
        #elif defined(VGA_RGB12)
            static const int32_t BG_COLOR = 0x9B0u;
        #endif

        typedef struct {
            int32_t x;
            int32_t y;
        } xy_t;
        static const xy_t NULL_XY;

        enum state_t {MENU, PAUSE, RUN};


    // Methods

        // public methods
        static void init();
        static void main_loop();

    private:

        // private init methods
        static void init_menu();
        static void init_level(int32_t id);

        // private loop methods
        static void menu();
        static void pause();
        static void run();

        // private utility methods
        static void spawn_food();
        static void spawn_bug();
        static int32_t read_btns();


    // Variables

        static state_t state;
        static xy_t head;
        static int32_t dir;
        static int32_t next_dir;
        static fifo<xy_t, MAX_SIZE> body;
        static int32_t step_period; // delay between steps in milliseconds (inverse speed)
        static int32_t prev_step_millis;
        static int32_t prev_btn_press_millis;
        static xy_t food;
        static xy_t bug;
        static int32_t bug_points;


}; // class Snake


#include "snake_bmp.h"


#endif // __H
