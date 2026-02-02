#include "usbd_desc.h"
#include "usbd_core.h"

#define USB_LEN_DEV_DESC 18
#define USB_LEN_LANGID_STR_DESC 4
#define USB_MAX_STR_DESC_SIZ 64

static uint8_t USBD_FS_DeviceDesc[USB_LEN_DEV_DESC] = {
  0x12,
  USB_DESC_TYPE_DEVICE,
  0x00, 0x02,
  0x02,
  0x00,
  0x00,
  USB_MAX_EP0_SIZE,
  LOBYTE(USBD_VID),
  HIBYTE(USBD_VID),
  LOBYTE(USBD_PID),
  HIBYTE(USBD_PID),
  0x00, 0x02,
  0x01,
  0x02,
  0x03,
  0x01
};

static uint8_t USBD_LangIDDesc[USB_LEN_LANGID_STR_DESC] = {
  USB_LEN_LANGID_STR_DESC,
  USB_DESC_TYPE_STRING,
  LOBYTE(USBD_LANGID_STRING),
  HIBYTE(USBD_LANGID_STRING)
};

static uint8_t USBD_StrDesc[USB_MAX_STR_DESC_SIZ];

uint8_t *USBD_FS_DeviceDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
  (void)speed;
  *length = sizeof(USBD_FS_DeviceDesc);
  return USBD_FS_DeviceDesc;
}

uint8_t *USBD_FS_LangIDStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
  (void)speed;
  *length = sizeof(USBD_LangIDDesc);
  return USBD_LangIDDesc;
}

uint8_t *USBD_FS_ManufacturerStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
  (void)speed;
  USBD_GetString((uint8_t *)USBD_MANUFACTURER_STRING, USBD_StrDesc, length);
  return USBD_StrDesc;
}

uint8_t *USBD_FS_ProductStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
  (void)speed;
  USBD_GetString((uint8_t *)USBD_PRODUCT_STRING, USBD_StrDesc, length);
  return USBD_StrDesc;
}

uint8_t *USBD_FS_SerialStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
  (void)speed;
  USBD_GetString((uint8_t *)USBD_SERIAL_STRING, USBD_StrDesc, length);
  return USBD_StrDesc;
}

uint8_t *USBD_FS_ConfigStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
  (void)speed;
  USBD_GetString((uint8_t *)USBD_CONFIGURATION_STRING, USBD_StrDesc, length);
  return USBD_StrDesc;
}

uint8_t *USBD_FS_InterfaceStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
  (void)speed;
  USBD_GetString((uint8_t *)USBD_INTERFACE_STRING, USBD_StrDesc, length);
  return USBD_StrDesc;
}

USBD_DescriptorsTypeDef FS_Desc = {
  USBD_FS_DeviceDescriptor,
  USBD_FS_LangIDStrDescriptor,
  USBD_FS_ManufacturerStrDescriptor,
  USBD_FS_ProductStrDescriptor,
  USBD_FS_SerialStrDescriptor,
  USBD_FS_ConfigStrDescriptor,
  USBD_FS_InterfaceStrDescriptor
};
