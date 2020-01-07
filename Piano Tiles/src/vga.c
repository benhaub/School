/* DE2-115 VGA */

/* Local Headers */
#include "vga.h"
/* Standard Headers */
#include <string.h>

/******************************************************************************
subroutine to send a string of text to the VGA monitor
*******************************************************************************/
void VGA_text(int x, int y, char * text_ptr) {

  int offset;
  volatile char * character_buffer = (char *) 0x09000000;
    /* assume that the text string fits on one line */
    offset = (y << 7) + x;
  while ( *(text_ptr) )
  {
    *(character_buffer + offset) = *(text_ptr);
    // write to the character buffer
    ++text_ptr;
    ++offset;
  }
}

/******************************************************************************
Draw a filled rectangle on the VGA monitor
*******************************************************************************/
void VGA_box(int x1, int y1, int x2, int y2, short pixel_color) {
  
  int offset, row, col;
  volatile short * pixel_buffer = (short *) 0x08000000;
    /* assume that the box coordinates are valid */
    for (row = y1; row <= y2; row++)
    {
      col = x1;
      while (col <= x2)
      {
        offset = (row << 9) + col;
        *(pixel_buffer + offset) = pixel_color;
        // compute halfword address, set pixel
        ++col;
      }
    }
}

/******************************************************************************
  Set a single pixel on the VGA monitor
 *******************************************************************************/
void VGA_pixel(int x, int y, short pixel_color) {
  
  int offset;
  volatile short * pixel_buffer = (short *) 0x08000000;
  offset = ((y << 9) + x);
  *(pixel_buffer + offset) = pixel_color;
}

/*******************************************************************************
 * Clear screen - Set entire screen to black on the VGA monitor
 *******************************************************************************/
void VGA_clear_pixel() {
  int x, y;
  for (x = 0; x < PIXELWIDTH; x++) {
    for (y = 0; y < PIXELLENGTH; y++) {
      VGA_pixel(x, y, 0);
    }
  }
}

/******************************************************************************
 * Clear all text from the screen
 *  param y
 *    The line to clear the text from
 * ****************************************************************************/
void VGA_clear_char() {
 
  char clear[PIXELWIDTH];
  int i;
  memset(clear, ' ', sizeof(char)*PIXELWIDTH);
  for(i = 0; i < PIXELLENGTH; i++) {
    VGA_text(0, i, clear);
  }
}
