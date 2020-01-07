/* UCOSII Headers */
#include "includes.h"

/* Local Headers */
#include "ipc.h"
#include "sem.h"
#include "err.h"
#include "vga.h"
#include "piano_conf.h"
#include "piano_songs.h"

/* Standard Headers */
#include <stdio.h>
#include <stdlib.h>

#define HWREG(x) *((volatile INT32U *)(x))

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    scankey_stk[TASK_STACKSIZE];
OS_STK    gamemanager_stk[TASK_STACKSIZE];
OS_STK    statemanager_stk[TASK_STACKSIZE];
OS_STK    display_stk[TASK_STACKSIZE];

/* Definition of Task Priorities. The lower the value, the higher the priority*/
#define SCAN_KEY_PRIORITY 0
#define GAME_MANAGER_PRIORITY 3
#define STATE_MANAGER_PRIORITY 2
#define DISPLAY_PRIORITY 1

/* 
 * Event flags for the game states:
 *  MENU_MAIN
 *  MENU_ABOUT
 *  MENU_HELP
 *  PLAY
 *  PAUSE
 *  END
 */
OS_FLAG_GRP *game_states;

/* Masks to set the bits of each state */
#define MENU_MAIN (OS_FLAGS)(1 << 0)
#define MENU_ABOUT (OS_FLAGS)(1 << 1)
#define MENU_HELP (OS_FLAGS)(1 << 2)
#define PLAY (OS_FLAGS)(1 << 3)
#define PAUSE (OS_FLAGS)(1 << 4)
#define END (OS_FLAGS)(1 << 5)

/* Menu Buttons. Number represents the location of the screen */
/* for example, the play button is the 1st option, so it gets a 1. The back */
/* button is the only button on the screen when it appears, so it gets a 1 */
/* The help button is the 2nd button, so it is assigned two */
#define MENU_BUTTON_PLAY 1
#define MENU_BUTTON_BACK 1
#define MENU_BUTTON_HELP 2
#define MENU_BUTTON_ABOUT 3
#define END_BUTTON_RESTART 1
#define END_BUTTON_QUIT 2

#define MENU_MAIN_TEXT  VGA_text(27, 10, "Welcome to Piano Tiles");\
                        VGA_text(36, 25, "Play");\
                        VGA_text(36, 27, "Help");\
                        VGA_text(36, 29, "About");\
                        VGA_text(13, 50, "Use the keys to navigate. KEY1:DOWN, KEY0:UP, KEY2:SELECT");\
                        /* Place the cursor on play to start */\
                        VGA_box(135, 99, 167, 105, 0x67FB);

/* Semaphores */
OS_EVENT *keysem; /* KEY[3:0] mailbox */
OS_EVENT *slidersem; /*SW[17:0] mailbox */
OS_EVENT *playablesem;
 
/* Mailboxes */
/* Contains the data from KEY3:0 */
int keyread;
/* Contains the data from SW[17:0] */
int sliderread;
/* mailbox to send when keys are over the white line */
int playable;
 
/* Globals */
/* The current score. */
INT8U score = 0;
/* How many piano tiles are left to play in the game */
INT32U tiles_left = SONG_LENGTH;
/* keep track of how far into the song we are */
int progress = 0;
/* keep track of the number of games completed */
int games_completed = 0;
/* Keep track of consecutive songs completed */
/* The cursor position in the menu. It's value depends on what screen it's in */
/* But is always less than or equal to the number of menu options. There are */
/* 3 options in the main menu, so cursor will either be 1, 2, or 3 */
int cursor;
/* These are the patterns for each song that determines where the tiles fall */
/* from the screen */
int song1_cpattern[SONG_LENGTH];
int song1_tpattern[SONG_LENGTH];

int initEvent(void) {

  INT8U err;

  /* The game is initially MENU_MAIN */
  game_states = OSFlagCreate(MENU_MAIN, &err);
  if(err != OS_NO_ERR) {
    fprintf(stderr, "Error while creating event flags group\n");
    return -1;
  }
  return 0;
}

void de2_115_init(void) {

  HWREG(SLIDER_SWITCHES_BASE) = 0x00000;
  HWREG(HEX3_HEX0_BASE) = 0x00000000;
  HWREG(HEX7_HEX4_BASE) = 0x00000000;
  HWREG(PUSHBUTTONS_BASE) = 0x00;
}

/* Initialise semaphores for mailbox and keys */
/* param val
 *   The value for the semaphore (binary or counting)
 * param initial
 *   The value to intialise the semaphores with
 */
void initSems(int val, int initial) {

  keysem = OSSemCreate(val);
  slidersem = OSSemCreate(val);
  playablesem = OSSemCreate(val);
  INT8U semerr;
  
  if(1 == initial) {
    return;
  }
  else {
    down(keysem, 0, &semerr);
    if(OS_ERR_NONE != semerr) {
      fprintf(stderr, "Could not acquire keysem in send()\n");
    }
    down(slidersem, 0, &semerr);
    if(OS_ERR_NONE != semerr) {
      fprintf(stderr, "Could not acquire slidersem in send()\n");
    }
  }
}

/* Place the game in it's initial state */
void initGame() {

  cursor = MENU_BUTTON_PLAY;
  /* Create song data */
  int i;
  for(i = 0; i < SONG_LENGTH; i++) {
    song1_cpattern[i] = (rand() % 4);
    song1_tpattern[i] = (rand() % 10);
  }
  return;
}

/* Reset the game to it's initial state */
void reset_game() {

  initGame();
  score = 0;
  tiles_left = SONG_LENGTH;
  progress = 0;
}

/* 
 * Records the values of pushbuttons in slider switches and sends 
 * them to the keyread mailbox
 * param pdata
 *  Not used
 */ 
void scankey_task(void *pdata) {

  INT8U keydata = 0;
  INT32U sliderdata = 0;
  /* flag to tell whether the key was pressed or not. This disables */
  /* press and hold */
  int pressed = 0;
  while(1) {
    /* Blocking delay to stop press and hold */
    while(1) {
      if(0 == HWREG(PUSHBUTTONS_BASE)) {
        pressed = 0;
      } 
      if(0 != HWREG(PUSHBUTTONS_BASE) && 0 == pressed) {
        /* key pressed, must release to get here again */
        pressed = 1;
        keydata = HWREG(PUSHBUTTONS_BASE);
        send(&keyread, keysem,  keydata);
      }
      /* Get the slider switch value */
      sliderdata = HWREG(SLIDER_SWITCHES_BASE);
      send(&sliderread, slidersem, sliderdata);
      /* Delay here to give the other tasks a chance to see the value of */
      /* keyread and sliderread */
      OSTimeDly(1);
      /* Reset keyread global back to zero */
      keydata = 0;
      send(&keyread, keysem, keydata);
    }
  }
}

/* 
 * Enforces all the game rules such as when you win, if a tile was played
 * at the right spot.
 */
void gamemanager_task(void *pdata) {

  INT8U keyval;
  INT8U playableval;
  INT8U err;

  while(1) {
    OSFlagAccept(game_states, PLAY, OS_FLAG_WAIT_SET_ALL, &err);
    checkFlagAccept(err);
    if(OS_NO_ERR == err) {
      keyval = receive(keyread, keysem);
      /* playable is set by the song that's playing in piano_songs.c */
      playableval = receive(playable, playablesem);
      if(0 == playableval && 0x1 == keyval) {
        score++;
      }
      else if(1 == playableval && 0x2 == keyval) {
        score++;
      }
      else if(2 == playableval && 0x4 == keyval) {
        score++;
      }
      else if(3 == playableval && 0x8 == keyval) {
        score++;
      }
      OSTimeDly(1);
    }
  }
}

/*
 * Controls the game state
 */
void statemanager_task(void *pdata) {

  INT8U err;
  INT8U sliderval;
  INT8U keyval;
  INT8U playableval;

  while(1) {
    keyval = receive(keyread, keysem);
    sliderval = receive(sliderread, slidersem);
    playableval = receive(playable, playablesem);
    /* Main Menu */
    OSFlagAccept(game_states, MENU_MAIN, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(4 == keyval && cursor == MENU_BUTTON_PLAY) {
        OSFlagPost(game_states, MENU_MAIN, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, PLAY, OS_FLAG_SET, &err);
        checkFlagPost(err);
        goto Delay;
      }
      else if(4 == keyval && cursor == MENU_BUTTON_HELP) {
        OSFlagPost(game_states, MENU_MAIN, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, MENU_HELP, OS_FLAG_SET, &err);
        checkFlagPost(err);
        goto Delay;
      }
      else if(4 == keyval && cursor == MENU_BUTTON_ABOUT) {
        OSFlagPost(game_states, MENU_MAIN, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, MENU_ABOUT, OS_FLAG_SET, &err);
        checkFlagPost(err);
        goto Delay;
      }
    }
    /* Help Menu */
    OSFlagAccept(game_states, MENU_HELP, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(4 == keyval) {
        OSFlagPost(game_states, MENU_HELP, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, MENU_MAIN, OS_FLAG_SET, &err);
        checkFlagPost(err);
        goto Delay;
      }
    }
    /* About Menu */
    OSFlagAccept(game_states, MENU_ABOUT, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(4 == keyval) {
        OSFlagPost(game_states, MENU_ABOUT, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, MENU_MAIN, OS_FLAG_SET, &err);
        checkFlagPost(err);
        goto Delay;
      }
    }
    /* Pause */
    OSFlagAccept(game_states, PLAY, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(1 == (sliderval & 0x1)) {
        OSFlagPost(game_states, PLAY, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, PAUSE, OS_FLAG_SET, &err);
        checkFlagPost(err);
        goto Delay;
      }
    }
    /* Play */
    OSFlagAccept(game_states, PAUSE, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(0 == (sliderval & 0x1)) {
        OSFlagPost(game_states, PAUSE, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, PLAY, OS_FLAG_SET, &err);
        checkFlagPost(err);
        goto Delay;
      }
    }
    /* End */
    OSFlagAccept(game_states, PLAY, OS_FLAG_WAIT_SET_ALL, &err);
    checkFlagAccept(err);
    if(OS_NO_ERR == err) {
      /* Check if the game has been lost due to pressing the incorrect key */
      if(0 == playableval && 0x1 != keyval) {
        OSFlagPost(game_states, PLAY, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, END, OS_FLAG_SET, &err);
        checkFlagPost(err);
      }
      else if(1 == playableval && 0x2 != keyval) {
        OSFlagPost(game_states, PLAY, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, END, OS_FLAG_SET, &err);
        checkFlagPost(err);
      }
      else if(2 == playableval && 0x4 != keyval) {
        OSFlagPost(game_states, PLAY, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, END, OS_FLAG_SET, &err);
        checkFlagPost(err);
      }
      else if(3 == playableval && 0x8 != keyval) {
        OSFlagPost(game_states, PLAY, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, END, OS_FLAG_SET, &err);
        checkFlagPost(err);
      }
      goto Delay;
    }
    /* Game over menu, we can either restart or quit to the main menu */
    OSFlagAccept(game_states, END, OS_FLAG_WAIT_SET_ALL, &err);
    checkFlagAccept(err);
    if(OS_NO_ERR == err) {
      if(4 == keyval && cursor == END_BUTTON_RESTART) {
        OSFlagPost(game_states, END, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, PLAY, OS_FLAG_SET, &err);
        checkFlagPost(err);
        reset_game();
      }
      else if(4 == keyval && cursor == END_BUTTON_QUIT) {
        OSFlagPost(game_states, END, OS_FLAG_CLR, &err);
        checkFlagPost(err);
        OSFlagPost(game_states, MENU_MAIN, OS_FLAG_SET, &err);
        checkFlagPost(err);
      }
      goto Delay;
    }
    Delay:
    OSTimeDly(1);
  }
}

/* 
 * Displays all the menus and the game screen depending on the state.
 * Also controls where the cursor is located.
 */
void display_task(void *pdata) {

  INT8U err;
  int keyval;
  int sliderval;
  /* The state flags prevent the vga from constantly re-displaying. They */
  /* are also used for initializing states. */
  int stateflag_mm = 1; /* main menu state flag */
  int stateflag_help = 1;
  int stateflag_about = 1;
  int stateflag_play = 1;
  int stateflag_go = 1; /* game over state flag */
  /* Cursor position. Ititilaised to one to avoid compiler warnings */
  int x0_c = 1;
  int y0_c = 1;
  int x1_c = 1;
  int y1_c = 1;

  /* Strings for displays score, tiles left and games completed */
  char score_display[4] = {0, 0, 0, 0};
  char tiles_left_display[4] = {0, 0, 0, 0};
  char games_completed_display[3] = {'0', '0', 0};

  while(1) { 
    /* Get the key value so we can check if the up or down key has been */
    /* selected. */
    keyval = receive(keyread, keysem);
    sliderval = receive(sliderread, slidersem);
    OSFlagAccept(game_states, MENU_MAIN, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_ERR_NONE == err) {
      /* State initialization */
      if(stateflag_mm) {
        stateflag_mm = 0;
        x0_c = 135;
        y0_c = 99;
        x1_c = 167;
        y1_c = 105;
        cursor = MENU_BUTTON_PLAY;
        VGA_clear_pixel();
        VGA_clear_char();
        MENU_MAIN_TEXT;
      }
      /* Move the cursor up when KEY0 is pressed */
      else if(1 == keyval && cursor > 1) {
        /* Clear the cursor */
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x0000);
        y0_c -= 7;
        y1_c -= 7;
        cursor--;
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x67FB);
      }
      else if(2 == keyval && cursor < 3) {
        /* Move the cursor down when KEY1 is pressed */
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x0000);
        y0_c += 7;
        y1_c += 7;
        cursor++;
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x67FB);
      }
    }
    else if(OS_FLAG_ERR_NOT_RDY == err) {
      stateflag_mm = 1;
    } 
    /* Display the Help Menu */
    OSFlagAccept(game_states, MENU_HELP, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      /* Back button was pressed, go back to main menu */
      if(4 == keyval) {
        /* Delay and let the state manager take us back to the main menu */
        goto Delay; 
      }
      if(stateflag_help) {
        x0_c = 270;
        y0_c = 198;
        x1_c = 302;
        y1_c = 204;
        cursor = MENU_BUTTON_BACK;
        VGA_clear_pixel();
        VGA_clear_char();
        VGA_text(33, 10, "Help Menu");
        VGA_text(15, 15, "Tiles will fall down from the top of the screen");
        VGA_text(15, 17, "in a column that corresponds to the KEYS on the");
        VGA_text(15, 19, "DE2-115. You must press the correct key when the");
        VGA_text(15, 21, "tile is over the white line near the bottom of the");
        VGA_text(15, 23, "screen to play the note. You get 1 point for playing");
        VGA_text(15, 25, "each note correctly. Missed notes will end the game");
        VGA_text(15, 27, "You can flip switch 0 to it's up position to pause");
        VGA_text(15, 29, "the game while playing, and flip it to its down");
        VGA_text(15, 31, "position to resume the game.");
        VGA_text(70, 50, "Back");
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x67FB);
        stateflag_help = 0;
      }
    }
    else if(OS_FLAG_ERR_NOT_RDY == err) {
      stateflag_help = 1;
    }
    /* Display the About menu */
    OSFlagAccept(game_states, MENU_ABOUT, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(4 == keyval) {
        goto Delay;
      }
      if(stateflag_about) {
        x0_c = 270;
        y0_c = 198;
        x1_c = 302;
        y1_c = 204;
        cursor = MENU_BUTTON_BACK;
        VGA_clear_pixel();
        VGA_clear_char();
        VGA_text(15, 15, "Piano Tiles was developed by Ben Haubrich for the");
        VGA_text(15, 17, "CME 332 final project at the University of Saskatchewan");
        VGA_text(15, 19, "Version 1.0. Last Updated: April 2nd, 2019");
        VGA_text(70, 50, "Back");
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x67FB);
        stateflag_about = 0;
      }
    }
    else if(OS_FLAG_ERR_NOT_RDY == err) {
      stateflag_about = 1;
    }
    /* Play screen */
    OSFlagAccept(game_states, PLAY, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      /* The mask is so that the other slide switches have no effect on the */
      /* game */
      if(1 == (sliderval & 0x1)) {
        goto Delay;
      }
      /* Update the score values */
      score_display[0] = (score / 100) + 48;
      score_display[1] = ((score % 100) / 10) + 48;
      score_display[2] = (score % 10) + 48;
      tiles_left_display[0] = (tiles_left / 100) + 48;
      tiles_left_display[1] = ((tiles_left % 100) / 10) + 48;
      tiles_left_display[2] = (tiles_left % 10) + 48;
      if(SONG_LENGTH - 1 == progress) {
        games_completed_display[0] = (games_completed / 10) + 48;
        games_completed_display[1] = (games_completed % 10) + 48;
      }
      if(stateflag_play) {
        VGA_clear_char();
        VGA_clear_pixel();
        stateflag_play = 0;
        /* Draw the columns for each note */
        VGA_box(70, 0, 70, PIXELLENGTH, 0xFFFF);
        VGA_text(6, 5, "KEY4");
        VGA_box(140, 0, 140, PIXELLENGTH, 0xFFFF);
        VGA_text(25, 5, "KEY3");
        VGA_box(210, 0, 210, PIXELLENGTH, 0xFFFF);
        VGA_text(42, 5, "KEY2");
        VGA_box(280, 0, 280, PIXELLENGTH, 0xFFFF);
        VGA_text(60, 5, "KEY1");
        VGA_text(71, 5, "Tiles");
        VGA_text(71, 6, "Left:");
        VGA_text(71, 10, "Score:");
        VGA_text(71, 14, "Games");
        VGA_text(71, 15, "Completed:");
        /* Draw the line where you must play notes */
        VGA_box(0, PIXELLENGTH - PLAY_LINE, PIXELWIDTH - 5, PIXELLENGTH - PLAY_LINE, 0xFFFF); 
      }
      play_song(song1_tpattern, song1_cpattern);
      VGA_text(71, 7, tiles_left_display);
      VGA_text(71, 11, score_display);
      VGA_text(71, 16, games_completed_display);
    }
    else if(OS_FLAG_ERR_NOT_RDY == err) {
      stateflag_play = 1;
    }
    /* Pause screen */
    OSFlagAccept(game_states, PAUSE, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(1 == (sliderval & 0x1)) {
        VGA_text(37, 30, "PAUSED");
      }
    }
    /* Game over screen */
    OSFlagAccept(game_states, END, OS_FLAG_WAIT_SET_ALL, &err);
    if(OS_NO_ERR == err) {
      if(stateflag_go) {
        stateflag_go = 0;
        x0_c = 145;
        y0_c = 107;
        x1_c = 184;
        y1_c = 113;
        VGA_text(37, 25, "GAME OVER");
        VGA_text(37, 27, "Restart");
        VGA_text(37, 29, "Quit");
        cursor = END_BUTTON_RESTART;
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x67FB); 
      }
      /* Move the cursor up when KEY0 is pressed */
      else if(1 == keyval && cursor > 1) {
        /* Clear the cursor */
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x0000);
        y0_c -= 7;
        y1_c -= 7;
        cursor--;
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x67FB);
      }
      else if(2 == keyval && cursor < 2) {
        /* Move the cursor down when KEY1 is pressed */
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x0000);
        y0_c += 7;
        y1_c += 7;
        cursor++;
        VGA_box(x0_c, y0_c, x1_c, y1_c, 0x67FB);
      }
    }
    else if(OS_FLAG_ERR_NOT_RDY == err) {
      stateflag_go = 1;
    }
    Delay:
    OSTimeDly(1);
  }
}

int main() {

  de2_115_init();
  initSems(1, 1);
  initEvent();
  initGame();

if(OS_ERR_NONE != OSTaskCreateExt(scankey_task,
                  NULL,
                  (void *)&scankey_stk[TASK_STACKSIZE-1],
                  SCAN_KEY_PRIORITY,
                  SCAN_KEY_PRIORITY,
                  scankey_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0))
{
  fprintf(stderr, "Error while creating ScanKey\n");
}

if(OS_ERR_NONE != OSTaskCreateExt(gamemanager_task,
                  NULL,
                  (void *)&gamemanager_stk[TASK_STACKSIZE-1],
                  GAME_MANAGER_PRIORITY,
                  GAME_MANAGER_PRIORITY,
                  gamemanager_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0))
{
  fprintf(stderr, "Error while creating gamemanager\n");
}

if(OS_ERR_NONE != OSTaskCreateExt(statemanager_task,
                  NULL,
                  (void *)&statemanager_stk[TASK_STACKSIZE-1],
                  STATE_MANAGER_PRIORITY,
                  STATE_MANAGER_PRIORITY,
                  statemanager_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0))
{
  fprintf(stderr, "Error while creating statemanager\n");
}

if(OS_ERR_NONE != OSTaskCreateExt(display_task,
                  NULL,
                  (void *)&display_stk[TASK_STACKSIZE-1],
                  DISPLAY_PRIORITY,
                  DISPLAY_PRIORITY,
                  display_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0))
{
  fprintf(stderr, "Error while creating display manager\n");
}
  OSStart();

  return 0;
}
