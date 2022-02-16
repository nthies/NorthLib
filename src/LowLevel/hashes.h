//
//  hashes.h
//
//  Created by Norbert Thies on 05.09.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

#ifndef hashes_h
#define hashes_h

#include "sysdef.h"

BeginCLinkage

char *data_toHex(const void *data, size_t len);
char *hash_md5(const void *data, size_t len);
char *hash_sha1(const void *data, size_t len);
char *hash_sha256(const void *data, size_t len);

EndCLinkage

#endif /* hashes_h */
