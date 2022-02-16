//
//  tzdata.h
//
//  Created by Norbert Thies on 07.02.2022
//  Copyright © 2022 Norbert Thies. All rights reserved.
//

#ifndef tzdata_h
#define tzdata_h

#include "sysdef.h"

typedef struct tzdata_s {
  const char *tz_std_name;	/* name of standard timezone */
  const char *tz_dst_name;	/* name when daylight saving is in effect */
  int         tz_std_offset;	/* standard offset to UTC */
  int         tz_dst_offset;	/* daylight saving offset to UTC */
} tzdata_t;

BeginCLinkage

const tzdata_t *tz_get();

EndCLinkage

#endif /* tzdata_h */
