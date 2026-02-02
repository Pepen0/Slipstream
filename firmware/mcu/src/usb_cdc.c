#include "usb_cdc.h"
#include "app_config.h"
#include "usb_device.h"
#include "usbd_cdc_if.h"

static uint8_t rx_storage[USB_RX_BUFFER_SIZE];
static ring_buffer_t rx_rb;

void usb_cdc_init(void) {
  rb_init(&rx_rb, rx_storage, sizeof(rx_storage));
  MX_USB_DEVICE_Init();
}

bool usb_cdc_is_configured(void) {
  extern USBD_HandleTypeDef hUsbDeviceFS;
  return (hUsbDeviceFS.dev_state == USBD_STATE_CONFIGURED);
}

size_t usb_cdc_read(uint8_t *dst, size_t len) {
  return rb_read(&rx_rb, dst, len);
}

size_t usb_cdc_write(const uint8_t *data, size_t len) {
  if (!usb_cdc_is_configured()) {
    return 0;
  }
  if (CDC_Transmit_FS((uint8_t *)data, (uint16_t)len) == USBD_OK) {
    return len;
  }
  return 0;
}

ring_buffer_t *usb_cdc_rx_buffer(void) {
  return &rx_rb;
}

void usb_cdc_on_rx(const uint8_t *data, size_t len) {
  rb_write(&rx_rb, data, len);
}
