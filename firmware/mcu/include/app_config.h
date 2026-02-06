#pragma once

#include "stm32f1xx_hal.h"

// Safety timing
#define APP_HEARTBEAT_TIMEOUT_MS 100u
#define APP_WATCHDOG_TIMEOUT_MS 200u
#define APP_TORQUE_DECAY_MS 100u
#define APP_TORQUE_DECAY_WINDOW_MS 10u

// Status telemetry
#define APP_STATUS_PERIOD_MS 100u

// Firmware update / DFU
#define APP_UPDATE_REQUEST_TIMEOUT_MS 3000u
#define APP_UPDATE_ARM_TIMEOUT_MS 3000u
#define APP_UPDATE_DFU_DELAY_MS 200u
#define APP_DFU_BOOTLOADER_ADDR 0x1FFFF000u // STM32F1 system memory base

// Control loop (1 kHz)
#define APP_CONTROL_LOOP_HZ 1000u

// PID gains (placeholder values)
#define APP_PID_KP 2.0f
#define APP_PID_KI 0.4f
#define APP_PID_KD 0.02f

// Torque command clamp
#define APP_TORQUE_LIMIT 1.0f

// Position limits (meters)
#define APP_POS_MIN_M (-0.08f)
#define APP_POS_MAX_M (0.08f)

// Homing
#define APP_HOMING_ENABLED 1u
#define APP_HOMING_TIMEOUT_MS 5000u
#define APP_HOMING_TARGET_M APP_POS_MIN_M

// Setpoint deadband
#define APP_SETPOINT_DEADBAND_M 0.0005f

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
#ifndef APP_PROTOCOL_MAX_PAYLOAD
#define APP_PROTOCOL_MAX_PAYLOAD 64u
#endif
