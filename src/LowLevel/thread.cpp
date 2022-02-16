//
//  thread.cpp
//  NorthLib
//
//  Created by Norbert Thies on 30.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

#include "thread.h"

unsigned long thread_id(pthread_t thread) {
# if defined(__APPLE__)
    mach_port_t mtid = pthread_mach_thread_np(pthread_self());
    return (unsigned long) mtid;
# else
    pthread_id_np_t ptid;
    pthread_getunique_np(&thread, &ptid);
    return (unsigned long) ptid;
# endif
}

pthread_t thread_current() {
  return pthread_self();
}
