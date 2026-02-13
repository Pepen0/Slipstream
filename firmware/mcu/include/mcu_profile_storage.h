#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

bool mcu_profile_storage_read(void *ctx, uint8_t *out, size_t len);
bool mcu_profile_storage_write(void *ctx, const uint8_t *data, size_t len);

#ifdef __cplusplus
}
#endif
