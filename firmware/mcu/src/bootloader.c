#include "bootloader.h"
#include "app_config.h"
#include "stm32f1xx_hal.h"

#define DFU_MAGIC 0xB007u

static void bootloader_enable_backup_access(void) {
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_RCC_BKP_CLK_ENABLE();
  HAL_PWR_EnableBkUpAccess();
}

bool bootloader_dfu_requested(void) {
  bootloader_enable_backup_access();
  if (BKP->DR1 == DFU_MAGIC) {
    BKP->DR1 = 0;
    return true;
  }
  return false;
}

void bootloader_request_dfu(void) {
  bootloader_enable_backup_access();
  BKP->DR1 = DFU_MAGIC;
  __DSB();
  NVIC_SystemReset();
}

typedef void (*boot_jump_t)(void);

void bootloader_enter_dfu(void) {
  __disable_irq();
  HAL_RCC_DeInit();
  HAL_DeInit();

  SysTick->CTRL = 0;
  SysTick->LOAD = 0;
  SysTick->VAL = 0;

  uint32_t sys_mem_addr = APP_DFU_BOOTLOADER_ADDR;
  uint32_t msp = *(__IO uint32_t *)sys_mem_addr;
  uint32_t reset = *(__IO uint32_t *)(sys_mem_addr + 4u);
  __set_MSP(msp);
  boot_jump_t jump = (boot_jump_t)reset;
  jump();
  while (1) {
  }
}
