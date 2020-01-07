/* UCOSII Headers */
#include "includes.h"

/* make semaphore functions easier to understand */
/* by wrapping them in "up" and "down" functions. */
INT8U up(OS_EVENT *sem) {
  return OSSemPost(sem);
}
void down(OS_EVENT *sem, INT16U timeout, INT8U *err) {
  OSSemPend(sem, timeout, err);
}

