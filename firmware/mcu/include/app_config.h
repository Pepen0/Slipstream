#pragma once

#include "stm32f1xx_hal.h"

// Safety timing
#define APP_HEARTBEAT_TIMEOUT_MS 100u
#define APP_WATCHDOG_TIMEOUT_MS 200u

// LED status
#define LED_GPIO_PORT GPIOC
#define LED_GPIO_CLK_ENABLE() __HAL_RCC_GPIOC_CLK_ENABLE()
#define LED_PIN GPIO_PIN_13

// E-Stop input (active low with pull-up)
#define ESTOP_GPIO_PORT GPIOA
#define ESTOP_GPIO_CLK_ENABLE() __HAL_RCC_GPIOA_CLK_ENABLE()
#define ESTOP_PIN GPIO_PIN_0
#define ESTOP_ACTIVE_STATE GPIO_PIN_RESET

// PWM enable (gate) output
#define PWM_EN_GPIO_PORT GPIOB
#define PWM_EN_GPIO_CLK_ENABLE() __HAL_RCC_GPIOB_CLK_ENABLE()
#define PWM_EN_PIN GPIO_PIN_12
#define PWM_EN_ACTIVE_STATE GPIO_PIN_SET

// USB CDC RX buffer
#define USB_RX_BUFFER_SIZE 256u

// Packet settings
#define APP_PROTOCOL_MAX_PAYLOAD 64u
