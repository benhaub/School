#ifndef __SEM_H__
#define __SEM_H__

/* UCOSII Headers */
#include "includes.h"

void down(OS_EVENT *, INT16U, INT8U *);
INT8U up(OS_EVENT *);

#endif /*__SEM_H__*/
