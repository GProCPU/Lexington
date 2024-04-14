#ifndef __FIFO_H
#define __FIFO_H

#include <stdint.h>
#include <stdbool.h>


template<typename T, uint32_t SIZE>
class fifo {

    public:

        fifo() {
            front = arr;
            back  = arr;
            count = 0;
        }

        inline uint32_t get_count() { return count; }
        inline bool is_empty() { return count == 0; }
        inline bool is_full() { return count == SIZE; }

        inline void clear() {
            front = arr;
            back  = arr;
            count = 0;
        }

        inline void insert(T item) {
            *front = item;
            front++;
            count++;
        }

        inline T remove() {
            T item = *back;
            back++;
            count--;
            return item;
        }

        inline T peek() {
            return *back;
        }

    private:

        T arr[SIZE];
        T* front;       // points empty space (insert at front)
        T* back;        // points to valid item (remove from back)
        uint32_t count;

};


#endif // __FIFO_H
