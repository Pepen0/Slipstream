#pragma once

#include "usbd_def.h"

#define USBD_VID 0x0483
#define USBD_PID 0x5740
#define USBD_LANGID_STRING 0x409
#define USBD_MANUFACTURER_STRING "Slipstream"
#define USBD_PRODUCT_STRING "Slipstream MCU CDC"
#define USBD_SERIAL_STRING "000000000001"
#define USBD_CONFIGURATION_STRING "CDC Config"
#define USBD_INTERFACE_STRING "CDC Interface"

extern USBD_DescriptorsTypeDef FS_Desc;

