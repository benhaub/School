/* Configuration for Piano Game */
#ifndef __PIANO_CONF_H__
#define __PIANO_CONF_H__

/* TODO: Adjust tile speed during gameplay. Can only use 9 or 11*/
#define TILE_SPEED 9
#define SONG_LENGTH 25
/* Defines how tolerant the game is to key presses and distance from play */
/* line. Anything greater than a value of 10 will introduce bugs. Lowering */
/* this value will make the game harder since you will have to have more */
/* precise key presses. */
#define PLAYABLE_TOLERANCE 10
/* Control where the white play line appears */
#define PLAY_LINE 20

#endif /*__PIANO_CONF_H__*/
