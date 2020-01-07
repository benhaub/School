#ifndef __IPC_H__
#define __IPC_H__

/* UCOSII Headers */
#include "includes.h"

int send(int *, OS_EVENT *, INT8U);
INT8U receive(int, OS_EVENT *);

#endif /*__IPC_H__*/
