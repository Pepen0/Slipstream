#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "ring_buffer.h"

#ifdef __cplusplus
extern "C" {
#endif

void usb_cdc_init(void);
bool usb_cdc_is_configured(void);
size_t usb_cdc_read(uint8_t *dst, size_t len);
size_t usb_cdc_write(const uint8_t *data, size_t len);

ring_buffer_t *usb_cdc_rx_buffer(void);
void usb_cdc_on_rx(const uint8_t *data, size_t len);

#ifdef __cplusplus
}
#endif
