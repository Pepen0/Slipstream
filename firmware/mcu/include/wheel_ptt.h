#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void wheel_ptt_init(void);
bool wheel_ptt_raw_pressed(void);

#ifdef __cplusplus
}
#endif
