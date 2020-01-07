/* Check UCOSII kernel calls for errors */

/* Standard Headers */
#include <stdio.h>

/* UCOSII Headers */
#include "includes.h"

/*
 * Check OSFlagPend for errors
 */
void checkFlagPend(INT8U err) {

  switch(err) {
    case OS_ERR_PEND_ISR:       fprintf(stderr, "EISR\n");
    break;
    case OS_ERR_EVENT_TYPE:     fprintf(stderr, "EEVENT\n");
    break;
    case OS_FLAG_INVALID_PGRP:  fprintf(stderr, "EGRP\n");
    break;
    default: return;
  }
}

/*
 * Check OSFlagPost for errors
 */
void checkFlagPost(INT8U err) {

  switch(err) {
    case OS_FLAG_INVALID_PGRP:    fprintf(stderr, "EPGRP\n");
    break;
    case OS_ERR_EVENT_TYPE:       fprintf(stderr, "EEVENT\n");
    break;
    case OS_FLAG_INVALID_OPT:     fprintf(stderr, "EOPT\n");
    break;
    default: return;
  }
}

/*
 * Check OSFlagAccept for errors
 */
void checkFlagAccept(INT8U err) {

  switch(err) {
    case OS_FLAG_INVALID_PGRP:    fprintf(stderr, "EINVLD\n");
    case OS_ERR_EVENT_TYPE:       fprintf(stderr, "EEVENT\n");
    case OS_FLAG_ERR_WAIT_TYPE:   fprintf(stderr, "ETYPE\n");
  }
} 
