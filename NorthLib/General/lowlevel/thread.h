//
//  thread.h
//  NorthLib
//
//  Created by Norbert Thies on 30.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

#ifndef thread_h
#define thread_h

#include <pthread.h>
#include "sysdef.h"

BeginCLinkage

unsigned long thread_id(pthread_t);
pthread_t thread_current();

EndCLinkage

#endif /* thread_h */
