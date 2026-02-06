#pragma once

#include <stdint.h>

#ifndef FW_VERSION_MAJOR
#define FW_VERSION_MAJOR 0u
#endif

#ifndef FW_VERSION_MINOR
#define FW_VERSION_MINOR 1u
#endif

#ifndef FW_VERSION_PATCH
#define FW_VERSION_PATCH 0u
#endif

#ifndef FW_VERSION_BUILD
#define FW_VERSION_BUILD 0u
#endif

#ifndef FW_BUILD_ID
#define FW_BUILD_ID 0u
#endif

#define FW_VERSION_PACK(major, minor, patch, build) \
  ((((uint32_t)(major) & 0xFFu) << 24) |            \
   (((uint32_t)(minor) & 0xFFu) << 16) |            \
   (((uint32_t)(patch) & 0xFFu) << 8) |             \
   ((uint32_t)(build) & 0xFFu))

#define FW_VERSION FW_VERSION_PACK(FW_VERSION_MAJOR, FW_VERSION_MINOR, FW_VERSION_PATCH, FW_VERSION_BUILD)
