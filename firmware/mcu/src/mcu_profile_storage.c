#include "mcu_profile_storage.h"

#include <string.h>

#include "app_config.h"

#if defined(STM32F103xB) && defined(USE_HAL_DRIVER)
#include "stm32f1xx_hal.h"

bool mcu_profile_storage_read(void *ctx, uint8_t *out, size_t len) {
  (void)ctx;
  if (!out || len == 0 || len > APP_PROFILE_FLASH_PAGE_SIZE) {
    return false;
  }
  const uint8_t *flash_ptr = (const uint8_t *)APP_PROFILE_FLASH_ADDR;
  memcpy(out, flash_ptr, len);
  return true;
}

bool mcu_profile_storage_write(void *ctx, const uint8_t *data, size_t len) {
  (void)ctx;
  if (!data || len == 0 || len > APP_PROFILE_FLASH_PAGE_SIZE) {
    return false;
  }

  uint8_t page[APP_PROFILE_FLASH_PAGE_SIZE];
  memset(page, 0xFF, sizeof(page));
  memcpy(page, data, len);

  HAL_FLASH_Unlock();

  FLASH_EraseInitTypeDef erase = {0};
  erase.TypeErase = FLASH_TYPEERASE_PAGES;
  erase.PageAddress = APP_PROFILE_FLASH_ADDR;
  erase.NbPages = 1;
  uint32_t page_error = 0;
  HAL_StatusTypeDef status = HAL_FLASHEx_Erase(&erase, &page_error);
  if (status != HAL_OK) {
    HAL_FLASH_Lock();
    return false;
  }

  for (uint32_t offset = 0; offset < APP_PROFILE_FLASH_PAGE_SIZE; offset += 2u) {
    uint16_t halfword = (uint16_t)page[offset] |
                        ((uint16_t)page[offset + 1u] << 8);
    status = HAL_FLASH_Program(FLASH_TYPEPROGRAM_HALFWORD,
                               APP_PROFILE_FLASH_ADDR + offset,
                               halfword);
    if (status != HAL_OK) {
      HAL_FLASH_Lock();
      return false;
    }
  }

  HAL_FLASH_Lock();
  return true;
}

#else

static uint8_t s_profile_flash[APP_PROFILE_FLASH_PAGE_SIZE];
static bool s_profile_flash_init = false;

static void ensure_flash_init(void) {
  if (s_profile_flash_init) {
    return;
  }
  memset(s_profile_flash, 0xFF, sizeof(s_profile_flash));
  s_profile_flash_init = true;
}

bool mcu_profile_storage_read(void *ctx, uint8_t *out, size_t len) {
  (void)ctx;
  if (!out || len == 0 || len > APP_PROFILE_FLASH_PAGE_SIZE) {
    return false;
  }
  ensure_flash_init();
  memcpy(out, s_profile_flash, len);
  return true;
}

bool mcu_profile_storage_write(void *ctx, const uint8_t *data, size_t len) {
  (void)ctx;
  if (!data || len == 0 || len > APP_PROFILE_FLASH_PAGE_SIZE) {
    return false;
  }
  ensure_flash_init();
  memset(s_profile_flash, 0xFF, sizeof(s_profile_flash));
  memcpy(s_profile_flash, data, len);
  return true;
}

#endif
