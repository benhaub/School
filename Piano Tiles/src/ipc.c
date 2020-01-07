/* IPC for UCOSII */

/* Standard Headers */
#include <stdio.h>
/* UCOSII Headers */
#include "includes.h"
#include "sem.h"

/*
 * Send data to the mailbox of your choice
 * param mailbox
 *  pointer to the mailbox where data is being sent
 * param sem
 *  The semaphore for the mailbox
 * param data
 *  pointer to data being sent
 * returns 0 on success, 1 on error
 */
int send(int *mailbox, OS_EVENT *sem, INT8U data) {

  INT8U semerr; 

  down(sem, 0, &semerr);
  if(OS_ERR_NONE != semerr) {
    fprintf(stderr, "Could not acquire sem in send()\n");
    return 1;
  }
  *mailbox = data;
  if(OS_ERR_NONE != up(sem)) {
    fprintf(stderr, "Could not release mailboxSem_time_time in send()\n");
    return 1;
  }
  return 0;
}

/* Retrieve data from a mailbox.
 * param mailbox
 *  The mailbox where the data held is desired
 * param sem
 *  The semaphore for the mailbox
 * returns the value from the mailbox. prints messages to stderr on error
 */
INT8U receive(int mailbox, OS_EVENT *sem) {
 
  INT8U semerr;
  INT8U mailbox_data;

  down(sem, 0, &semerr);
  if(OS_ERR_NONE != semerr) {
    fprintf(stderr, "Could not acquire sem in send()\n");
  }
  mailbox_data = mailbox; 
  if(OS_ERR_NONE != up(sem)) {
    fprintf(stderr, "Could not release mailboxSem_time_time in send()\n");
  }
  return mailbox_data;
}
