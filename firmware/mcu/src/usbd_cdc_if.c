#include "usbd_cdc_if.h"
#include "usbd_cdc.h"
#include "usb_device.h"
#include "usb_cdc.h"

#define APP_RX_DATA_SIZE  256
#define APP_TX_DATA_SIZE  256

static uint8_t UserRxBufferFS[APP_RX_DATA_SIZE];
static uint8_t UserTxBufferFS[APP_TX_DATA_SIZE];

USBD_CDC_ItfTypeDef USBD_Interface_fops_FS = {
  CDC_Init_FS,
  CDC_DeInit_FS,
  CDC_Control_FS,
  CDC_Receive_FS
};

int8_t CDC_Init_FS(void) {
  USBD_CDC_SetTxBuffer(&hUsbDeviceFS, UserTxBufferFS, 0);
  USBD_CDC_SetRxBuffer(&hUsbDeviceFS, UserRxBufferFS);
  return (int8_t)USBD_OK;
}

int8_t CDC_DeInit_FS(void) {
  return (int8_t)USBD_OK;
}

int8_t CDC_Control_FS(uint8_t cmd, uint8_t *pbuf, uint16_t length) {
  (void)cmd;
  (void)pbuf;
  (void)length;
  return (int8_t)USBD_OK;
}

int8_t CDC_Receive_FS(uint8_t *buf, uint32_t *len) {
  if (len && *len > 0) {
    usb_cdc_on_rx(buf, *len);
  }
  USBD_CDC_SetRxBuffer(&hUsbDeviceFS, UserRxBufferFS);
  USBD_CDC_ReceivePacket(&hUsbDeviceFS);
  return (int8_t)USBD_OK;
}

uint8_t CDC_Transmit_FS(uint8_t *buf, uint16_t len) {
  if (hUsbDeviceFS.dev_state != USBD_STATE_CONFIGURED) {
    return (uint8_t)USBD_FAIL;
  }
  USBD_CDC_HandleTypeDef *hcdc = (USBD_CDC_HandleTypeDef *)hUsbDeviceFS.pClassData;
  if (hcdc == NULL || hcdc->TxState != 0) {
    return (uint8_t)USBD_BUSY;
  }
  USBD_CDC_SetTxBuffer(&hUsbDeviceFS, buf, len);
  return (uint8_t)USBD_CDC_TransmitPacket(&hUsbDeviceFS);
}
