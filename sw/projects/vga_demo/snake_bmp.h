#ifndef __SNAKE_BMP_H
#define __SNAKE_BMP_H

#include "snake.h"

#define FG      (Snake::FG_COLOR)
#define BG      (Snake::BG_COLOR)


const rgb_t SNAKE_HEAD_BMP[] = {
    FG, BG, BG, BG,
    BG, FG, FG, BG,
    FG, FG, FG, BG,
    BG, BG, BG, BG
};

const rgb_t SNAKE_MOUTH_BMP[] = {
    FG, BG, FG, BG,
    BG, FG, BG, BG,
    FG, FG, BG, BG,
    BG, BG, FG, BG
};

const rgb_t SNAKE_BODY_BMP[] = {
    BG, BG, BG, BG,
    FG, FG, BG, FG,
    FG, BG, FG, FG,
    BG, BG, BG, BG
};

const rgb_t SNAKE_BODY_FULL_BMP[] = {
    BG, FG, FG, BG,
    FG, FG, BG, FG,
    FG, BG, FG, FG,
    BG, FG, FG, BG
};

const rgb_t SNAKE_BODY_TURN_BMP[] = {
    BG, FG, FG, BG,
    FG, BG, FG, BG,
    FG, FG, BG, BG,
    BG, BG, BG, BG
};

const rgb_t SNAKE_BODY_TURN_FULL_BMP[] = {
    FG, FG, FG, BG,
    FG, BG, FG, BG,
    FG, FG, BG, BG,
    BG, BG, BG, BG
};

const rgb_t SNAKE_TAIL_BMP[] = {
    BG, BG, BG, BG,
    BG, BG, BG, BG,
    BG, BG, FG, FG,
    FG, FG, FG, FG
};

const rgb_t SNAKE_FOOD_BMP[] = {
    BG, FG, BG, BG,
    FG, BG, FG, BG,
    BG, FG, BG, BG,
    BG, BG, BG, BG
};

const rgb_t SNAKE_BUGS_BMP[] = {
    // Spider
    BG, BG, FG, FG,
        FG, FG, BG, BG,
    FG, FG, FG, FG,
        FG, FG, FG, FG,
    FG, BG, FG, BG,
        BG, FG, BG, FG,
    FG, BG, FG, BG,
        BG, FG, BG, FG,
    // Big mouse
    BG, BG, BG, BG,
        FG, FG, BG, BG,
    FG, BG, BG, FG,
        FG, BG, FG, BG,
    FG, BG, FG, FG,
        FG, FG, FG, BG,
    BG, FG, FG, FG,
            FG, FG, FG, FG,
    // Little mouse
    BG, BG, FG, FG,
        BG, BG, BG, BG,
    BG, FG, BG, FG,
        FG, BG, FG, BG,
    FG, FG, FG, FG,
        FG, FG, FG, BG,
    BG, BG, FG, FG,
        FG, FG, BG, BG
    
};


#endif // __SNAKE_BMP_H
