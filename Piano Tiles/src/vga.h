#ifndef __VGA_H__
#define __VGA_H__
/* UCOSII Headers */

/* HAL Headers */
#include "system.h"

#define VGAREG_CHAR(x) *((volatile char *)(x))
#define VGAREG_PIXEL(x) *((volatile short *)(x))

/* VGA Colours */
#define RGB_BLACK         0x0000
#define RGB_WHITE         0xFFFF
#define RGB_BLUE          0x187F
#define RGB_INTEL_BLUE    0x71C5

/* Screen */
#define PIXELWIDTH 320
#define PIXELLENGTH 240

void VGA_text(int, int, char *);
void VGA_box(int, int, int, int, short);
void VGA_pixel(int, int, short);
void VGA_clear_pixel(void);
void VGA_clear_char(void);


#endif
