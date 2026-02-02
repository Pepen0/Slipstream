#pragma once

#include <stdint.h>
#include "usbd_cdc.h"

#ifdef __cplusplus
extern "C" {
#endif

int8_t CDC_Init_FS(void);
int8_t CDC_DeInit_FS(void);
int8_t CDC_Control_FS(uint8_t cmd, uint8_t *pbuf, uint16_t length);
int8_t CDC_Receive_FS(uint8_t *buf, uint32_t *len);
uint8_t CDC_Transmit_FS(uint8_t *buf, uint16_t len);

extern USBD_CDC_ItfTypeDef USBD_Interface_fops_FS;

#ifdef __cplusplus
}
#endif
