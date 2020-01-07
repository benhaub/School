/* Local Headers */
#include "vga.h"
#include "piano_conf.h"
#include "piano_songs.h"
#include "ipc.h"
/* Standard Headers */
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

typedef struct {
  int x0_t;
  int x1_t;
  int y0_t;
  int y1_t;
}SongData;

/* 2-D array to store positions of all the tiles */
SongData song_data[4][10];
/* external globals from piano_game.c */
extern int playable0;
extern int playable1;
extern int playable2;
extern int playable3;
extern int tiles_left;
extern int progress;
extern OS_EVENT *playablesem;
extern int playable;
extern int games_completed;

/*
 * Displays the tile pattern for song one. The coordinates are for the
 * starting position of the tile as it falls down the screen. The patterns
 * are pre-generated at the start of the game in game_init(). playable is
 * a variable that is set to one whenever the tile can be played.
 */
void play_song(int tile_pattern[], int column_pattern[]) {

  /* random colour for each tile generated */
  int tile_colour;
  int t;
  int c;

  int i = 0;

  /* This loop allows for more movement per call, therefore generating */
  /* smoother and faster tile speeds. The minus 6 is just an adjustment*/
  /* to improve performance. */
  for(i = 0; i < TILE_SPEED - 6; i++) {
    /* get the next progress numbers from the array */
    t = tile_pattern[progress];
    c = column_pattern[progress];

    /* Update the tile coordinates */
    /* x0 controls which column the tile appears in, the rest are always the */
    /* same. */
    switch(c) {
      case 0: song_data[c][t].x0_t = 230;
              break;
      case 1: song_data[c][t].x0_t = 170;
              break;
      case 2: song_data[c][t].x0_t = 90;
              break;
      case 3: song_data[c][t].x0_t = 30;
              break;
      default: fprintf(stderr, "Invalid song data generated. Column is invalid."
                      " Value is: %d\n", c);
               exit(1);
    }
    song_data[c][t].y0_t = song_data[c][t].y0_t + TILE_SPEED;
    song_data[c][t].y1_t = song_data[c][t].y0_t + 33;
    song_data[c][t].x1_t =  song_data[c][t].x0_t + 20;
    
    /* Generate any colour execept for black (0x0000) */
    tile_colour = (rand() % 0xEFFF) + 0x1;
    /* Draw the box with updated coordinates */
    VGA_box(song_data[c][t].x0_t, song_data[c][t].y0_t, song_data[c][t].x1_t,
        song_data[c][t].y1_t, tile_colour);
    /* Clear off the top sliver of the box as it moves down the screen */
    /* at TILE_SPEED. */
    VGA_box(song_data[c][t].x0_t, song_data[c][t].y0_t, song_data[c][t].x1_t,
        song_data[c][t].y0_t + TILE_SPEED, 0x0000);
    /* Re-draw the white play line when the tile is over top of it */
    if(song_data[c][t].y0_t - (PIXELLENGTH - 10) >= 0) {
      VGA_box(0, PIXELLENGTH - PLAY_LINE, PIXELWIDTH - 5, PIXELLENGTH - PLAY_LINE, 0xFFFF);
    }
    /* Controls when to generate a new tile on the screen. This */
    /* says "when the tile reaches the length of the screen, reset the y */
    /* coordinate back to the top of the screen and play the next tile in */
    /* the song_data". The subtraction from pixel length aligns the tiles with */
    /* The white line so that when they cross it they are playable. */
    if(abs(song_data[c][t].y0_t - (PIXELLENGTH - PLAYABLE_TOLERANCE)) < 20 ) {
      /* Set the playable flags when the tile is over the white line */
      switch(c) {
        case 0: 
                tiles_left--;
                send(&playable, playablesem, 0);
                break;
        case 1:
                tiles_left--;
                send(&playable, playablesem, 1);
                break;
        case 2:
                tiles_left--;
                send(&playable, playablesem, 2);
                break;
        case 3:
                tiles_left--;
                send(&playable, playablesem,  3);
                break;
        default:fprintf(stderr, "Invalid column of value %d detected\n", c);
                exit(1);
      }
      /* Clear off the top sliver of the box as it moves down the screen */
      VGA_box(song_data[c][t].x0_t, song_data[c][t].y0_t, song_data[c][t].x1_t,
        song_data[c][t].y0_t + TILE_SPEED*5, 0x0000);
      /* Re-draw the white play line when the tile is over top of it */
      VGA_box(0, PIXELLENGTH - PLAY_LINE, PIXELWIDTH - 5, PIXELLENGTH - PLAY_LINE, 0xFFFF);
      /* Reset coordinates back to the top of the screen */
      song_data[c][t].y0_t = 0;
      progress++;
    }
    else {
      /* Otherwise, the tile is not playable */ 
      send(&playable, playablesem, NOT_PLAYABLE);
    }
    /* When all the notes have been played, restart the song */
    if(progress >= SONG_LENGTH - 1) {
      progress = 0;
      games_completed++;
      tiles_left = SONG_LENGTH;
    }
  }
}
