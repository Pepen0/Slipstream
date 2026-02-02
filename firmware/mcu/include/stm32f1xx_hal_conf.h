#pragma once

#define HAL_MODULE_ENABLED
#define HAL_RCC_MODULE_ENABLED
#define HAL_GPIO_MODULE_ENABLED
#define HAL_FLASH_MODULE_ENABLED
#define HAL_PCD_MODULE_ENABLED
#define HAL_PCD_EX_MODULE_ENABLED
#define HAL_IWDG_MODULE_ENABLED
#define HAL_CORTEX_MODULE_ENABLED

#define HSE_VALUE 8000000U
#define HSI_VALUE 8000000U
#define LSI_VALUE 40000U
#define HSE_STARTUP_TIMEOUT 100U

#define VDD_VALUE 3300U
#define TICK_INT_PRIORITY 0U
#define USE_RTOS 0U
#define PREFETCH_ENABLE 1U

#include "stm32f1xx_hal_rcc.h"
#include "stm32f1xx_hal_gpio.h"
#include "stm32f1xx_hal_flash.h"
#include "stm32f1xx_hal_pcd.h"
#include "stm32f1xx_hal_pcd_ex.h"
#include "stm32f1xx_hal_iwdg.h"
#include "stm32f1xx_hal_cortex.h"
#include "stm32f1xx_hal.h"

#define assert_param(expr) ((void)0)
