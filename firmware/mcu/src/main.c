#include "stm32f1xx_hal.h"
#include <string.h>
#include "app_config.h"
#include "actuators.h"
#include "control_loop.h"
#include "mcu_command.h"
#include "mcu_core.h"
#include "mcu_faults.h"
#include "mcu_status.h"
#include "protocol.h"
#include "sensors.h"
#include "usb_cdc.h"
#include "led.h"
#include "safety.h"

IWDG_HandleTypeDef hiwdg;

static void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_IWDG_Init(void);

void Error_Handler(void) {
  __disable_irq();
  while (1) {
  }
}

int main(void) {
  HAL_Init();
  SystemClock_Config();
  MX_GPIO_Init();
  MX_IWDG_Init();

  led_init();
  safety_init();
  sensors_init();
  actuators_init();
  usb_cdc_init();

  mcu_core_t core;
  mcu_core_init(&core, HAL_GetTick(), APP_HEARTBEAT_TIMEOUT_MS, APP_TORQUE_DECAY_MS);

  control_config_t ctrl_cfg = {0};
  ctrl_cfg.pid.kp = APP_PID_KP;
  ctrl_cfg.pid.ki = APP_PID_KI;
  ctrl_cfg.pid.kd = APP_PID_KD;
  ctrl_cfg.pid.out_min = -APP_TORQUE_LIMIT;
  ctrl_cfg.pid.out_max = APP_TORQUE_LIMIT;
  ctrl_cfg.pid.integrator_min = -APP_TORQUE_LIMIT;
  ctrl_cfg.pid.integrator_max = APP_TORQUE_LIMIT;
  ctrl_cfg.torque_limit = APP_TORQUE_LIMIT;
  ctrl_cfg.pos_min_m = APP_POS_MIN_M;
  ctrl_cfg.pos_max_m = APP_POS_MAX_M;
  ctrl_cfg.homing_target_m = APP_HOMING_TARGET_M;
  ctrl_cfg.homing_timeout_ms = APP_HOMING_TIMEOUT_MS;
  ctrl_cfg.setpoint_deadband_m = APP_SETPOINT_DEADBAND_M;

  control_state_t ctrl = {0};
  control_init(&ctrl, &ctrl_cfg);
#if APP_HOMING_ENABLED
  control_start_homing(&ctrl, HAL_GetTick());
#endif

  protocol_frame_t frame;
  uint32_t status_seq = 0;
  uint32_t last_status_ms = 0;
  uint32_t last_control_ms = 0;
  uint32_t control_period_ms = (1000u / APP_CONTROL_LOOP_HZ);
  if (control_period_ms == 0) {
    control_period_ms = 1;
  }
  uint32_t last_cmd_rx_ms = 0;
  uint64_t last_cmd_host_ns = 0;
  uint8_t status_buf[sizeof(protocol_header_t) + sizeof(mcu_status_t) + sizeof(uint16_t)] = {0};

  while (1) {
    uint32_t now = HAL_GetTick();

    bool usb_ok = usb_cdc_is_configured();
    mcu_core_on_usb(&core, usb_ok, now);

    bool estop_active = safety_read_estop_pin();
    mcu_core_on_estop(&core, estop_active, now);

    ring_buffer_t *rb = usb_cdc_rx_buffer();
    while (protocol_try_parse(rb, &frame)) {
      if (frame.header.type == PROTOCOL_TYPE_HEARTBEAT) {
        mcu_core_on_heartbeat(&core, now);
      } else if (frame.header.type == PROTOCOL_TYPE_COMMAND) {
        if (frame.header.length >= sizeof(mcu_command_t)) {
          mcu_command_t cmd;
          memcpy(&cmd, frame.payload, sizeof(mcu_command_t));
          control_set_setpoints(&ctrl, cmd.left_m, cmd.right_m);
          last_cmd_rx_ms = now;
          last_cmd_host_ns = cmd.host_timestamp_ns;
        } else {
          mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
        }
      }
    }

    mcu_core_tick(&core, now);

    float torque_scale = mcu_core_torque_scale(&core, now);
    bool allow_control = mcu_core_should_energize(&core, now);

    if ((now - last_control_ms) >= control_period_ms) {
      last_control_ms = now;
      float left_pos = 0.0f;
      float right_pos = 0.0f;
      bool left_limit = false;
      bool right_limit = false;
      bool sensor_ok = sensors_read_position(&left_pos, &right_pos);
      (void)sensors_read_limits(&left_limit, &right_limit);
      if (!sensor_ok) {
        mcu_core_set_fault(&core, MCU_FAULT_SENSOR_RANGE, now);
      } else {
        control_tick(&ctrl, &ctrl_cfg, left_pos, right_pos, left_limit, right_limit, now,
                     allow_control ? torque_scale : 0.0f);
        if (control_fault(&ctrl) != MCU_FAULT_NONE) {
          mcu_core_set_fault(&core, control_fault(&ctrl), now);
        }
      }

      if (!allow_control || mcu_core_state(&core) == MCU_STATE_FAULT) {
        actuators_set_torque(0.0f, 0.0f);
      } else {
        actuators_set_torque(control_left_command(&ctrl), control_right_command(&ctrl));
      }
    }

    allow_control = mcu_core_should_energize(&core, now);
    torque_scale = mcu_core_torque_scale(&core, now);

    if (allow_control) {
      if (torque_scale >= 0.99f) {
        safety_set_pwm_enabled(true);
      } else {
        uint32_t window = APP_TORQUE_DECAY_WINDOW_MS;
        if (window == 0) {
          safety_set_pwm_enabled(false);
        } else {
          uint32_t phase = now % window;
          uint32_t on_time = (uint32_t)(torque_scale * (float)window);
          safety_set_pwm_enabled(phase < on_time);
        }
      }
    } else {
      safety_force_stop();
    }

    led_state_t led_state = LED_STATE_IDLE;
    switch (mcu_core_state(&core)) {
      case MCU_STATE_ACTIVE:
        led_state = LED_STATE_ACTIVE;
        break;
      case MCU_STATE_FAULT:
        led_state = LED_STATE_FAULT;
        break;
      case MCU_STATE_INIT:
      case MCU_STATE_IDLE:
      default:
        led_state = LED_STATE_IDLE;
        break;
    }
    led_set_state(led_state);
    led_tick(now);

    if (usb_ok && (now - last_status_ms) >= APP_STATUS_PERIOD_MS) {
      last_status_ms = now;
      mcu_status_t status = {0};
      status.uptime_ms = now;
      status.last_heartbeat_ms = core.last_heartbeat_ms;
      status.last_cmd_rx_ms = last_cmd_rx_ms;
      status.last_cmd_host_ns = last_cmd_host_ns;
      status.left_setpoint_m = ctrl.left.setpoint_m;
      status.right_setpoint_m = ctrl.right.setpoint_m;
      status.left_pos_m = ctrl.left_pos_m;
      status.right_pos_m = ctrl.right_pos_m;
      status.left_cmd = control_left_command(&ctrl);
      status.right_cmd = control_right_command(&ctrl);
      status.state = (uint8_t)mcu_core_state(&core);
      status.flags = 0;
      if (core.usb_connected) status.flags |= MCU_STATUS_FLAG_USB;
      if (core.estop_active) status.flags |= MCU_STATUS_FLAG_ESTOP;
      if (safety_is_pwm_enabled()) status.flags |= MCU_STATUS_FLAG_PWM;
      if (torque_scale < 1.0f && torque_scale > 0.0f) status.flags |= MCU_STATUS_FLAG_DECAY;
      if (ctrl.homing_active) status.flags |= MCU_STATUS_FLAG_HOMING;
      if (control_fault(&ctrl) == MCU_FAULT_NONE) status.flags |= MCU_STATUS_FLAG_SENSOR_OK;
      status.fault_code = mcu_core_fault(&core);

      size_t out_len = protocol_build_frame(PROTOCOL_TYPE_STATUS, status_seq++,
                                            (const uint8_t *)&status, sizeof(status),
                                            status_buf, sizeof(status_buf));
      if (out_len > 0) {
        usb_cdc_write(status_buf, out_len);
      }
    }

    HAL_IWDG_Refresh(&hiwdg);
  }
}

static void MX_GPIO_Init(void) {
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();
  __HAL_RCC_GPIOC_CLK_ENABLE();
}

static void MX_IWDG_Init(void) {
  hiwdg.Instance = IWDG;
  hiwdg.Init.Prescaler = IWDG_PRESCALER_64;
  hiwdg.Init.Reload = 125; // ~200ms with 40kHz LSI
  if (HAL_IWDG_Init(&hiwdg) != HAL_OK) {
    Error_Handler();
  }
}

static void SystemClock_Config(void) {
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
    Error_Handler();
  }

  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
                                RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK) {
    Error_Handler();
  }
}
