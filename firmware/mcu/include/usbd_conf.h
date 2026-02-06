#pragma once

#include "stm32f1xx_hal.h"

#define USBD_MAX_NUM_INTERFACES 1
#define USBD_MAX_NUM_CONFIGURATION 1
#define USBD_MAX_STR_DESC_SIZ 64
#define USBD_SUPPORT_USER_STRING 0
#define USBD_SELF_POWERED 1
#define USBD_DEBUG_LEVEL 0

#define USBD_LPM_ENABLED 0
#define USBD_DEV_CONNECTED 1

#define DEVICE_FS 0

void Error_Handler(void);

