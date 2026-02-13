#include "stm32f1xx_hal.h"
#include <string.h>
#include "app_config.h"
#include "actuators.h"
#include "control_loop.h"
#include "mcu_command.h"
#include "mcu_core.h"
#include "mcu_diagnostics.h"
#include "mcu_faults.h"
#include "mcu_jog.h"
#include "mcu_profile.h"
#include "mcu_profile_storage.h"
#include "mcu_ptt.h"
#include "mcu_maintenance.h"
#include "mcu_status.h"
#include "protocol.h"
#include "sensors.h"
#include "usb_cdc.h"
#include "led.h"
#include "safety.h"
#include "bootloader.h"
#include "firmware_version.h"
#include "wheel_ptt.h"

IWDG_HandleTypeDef hiwdg;

static void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_IWDG_Init(void);

static float clampf(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

static void apply_profile_to_control(control_config_t *cfg,
                                     const control_config_t *base_cfg,
                                     const mcu_profile_params_t *params) {
  if (!cfg || !base_cfg || !params) {
    return;
  }
  const float center = 0.5f * (base_cfg->pos_min_m + base_cfg->pos_max_m);
  float half_range = 0.5f * (base_cfg->pos_max_m - base_cfg->pos_min_m) * params->motion_range;
  if (half_range < 0.001f) {
    half_range = 0.001f;
  }

  cfg->torque_limit = base_cfg->torque_limit * params->force_intensity;
  cfg->pid.out_min = -cfg->torque_limit;
  cfg->pid.out_max = cfg->torque_limit;
  cfg->pid.integrator_min = -cfg->torque_limit;
  cfg->pid.integrator_max = cfg->torque_limit;

  cfg->pos_min_m = center - half_range;
  cfg->pos_max_m = center + half_range;
  cfg->homing_target_m = cfg->pos_min_m;
}

void Error_Handler(void) {
  __disable_irq();
  while (1) {
  }
}

int main(void) {
  HAL_Init();
  SystemClock_Config();
  MX_GPIO_Init();

  if (bootloader_dfu_requested()) {
    bootloader_enter_dfu();
  }

  MX_IWDG_Init();

  led_init();
  safety_init();
  sensors_init();
  actuators_init();
  wheel_ptt_init();
  usb_cdc_init();

  mcu_core_t core;
  mcu_core_init(&core, HAL_GetTick(), APP_HEARTBEAT_TIMEOUT_MS, APP_TORQUE_DECAY_MS,
                APP_UPDATE_REQUEST_TIMEOUT_MS, APP_UPDATE_ARM_TIMEOUT_MS,
                APP_UPDATE_DFU_DELAY_MS);

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
  const control_config_t ctrl_cfg_base = ctrl_cfg;

  mcu_profile_manager_t profiles = {0};
  mcu_profile_manager_init(&profiles, mcu_profile_storage_read, mcu_profile_storage_write, NULL);
  mcu_profile_params_t active_profile = {0};
  if (!mcu_profile_active_params(&profiles, &active_profile)) {
    mcu_profile_default_params(&active_profile);
  }
  apply_profile_to_control(&ctrl_cfg, &ctrl_cfg_base, &active_profile);

  control_state_t ctrl = {0};
  control_init(&ctrl, &ctrl_cfg);
#if APP_HOMING_ENABLED
  control_start_homing(&ctrl, HAL_GetTick());
#endif

  mcu_jog_state_t jog = {0};
  mcu_jog_init(&jog);
  mcu_ptt_state_t ptt = {0};
  mcu_ptt_init(&ptt, APP_WHEEL_PTT_DEBOUNCE_MS, wheel_ptt_raw_pressed());

  protocol_frame_t frame;
  uint32_t status_seq = 0;
  uint32_t diag_seq = 0;
  uint32_t ptt_seq = 0;
  uint32_t last_status_ms = 0;
  uint32_t last_control_ms = 0;
  uint32_t control_period_ms = (1000u / APP_CONTROL_LOOP_HZ);
  if (control_period_ms == 0) {
    control_period_ms = 1;
  }
  uint32_t last_cmd_rx_ms = 0;
  uint64_t last_cmd_host_ns = 0;
  uint8_t status_buf[sizeof(protocol_header_t) + sizeof(mcu_status_t) + sizeof(uint16_t)] = {0};
  uint8_t diag_buf[sizeof(protocol_header_t) + sizeof(mcu_diag_response_t) + sizeof(uint16_t)] = {0};
  uint8_t ptt_buf[sizeof(protocol_header_t) + sizeof(mcu_ptt_event_t) + sizeof(uint16_t)] = {0};

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
        if (mcu_core_update_state(&core) != MCU_UPDATE_STATE_IDLE) {
          continue;
        }
        if (frame.header.length >= sizeof(mcu_command_t)) {
          mcu_command_t cmd;
          memcpy(&cmd, frame.payload, sizeof(mcu_command_t));
          control_set_setpoints(&ctrl, cmd.left_m, cmd.right_m);
          last_cmd_rx_ms = now;
          last_cmd_host_ns = cmd.host_timestamp_ns;
        } else {
          mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
        }
      } else if (frame.header.type == PROTOCOL_TYPE_JOG) {
        if (mcu_core_update_state(&core) != MCU_UPDATE_STATE_IDLE) {
          continue;
        }
        if (frame.header.length >= sizeof(mcu_jog_command_t)) {
          mcu_jog_command_t jog_cmd;
          memcpy(&jog_cmd, frame.payload, sizeof(mcu_jog_command_t));
          bool ok = mcu_jog_start(&jog, &jog_cmd, now,
                                  APP_JOG_DEFAULT_DURATION_MS, APP_JOG_MAX_DURATION_MS);
          if (!ok) {
            mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
          }
        } else {
          mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
        }
      } else if (frame.header.type == PROTOCOL_TYPE_MAINTENANCE) {
        mcu_maintenance_command_t maint = {0};
        if (!mcu_maintenance_decode(frame.payload, frame.header.length, &maint)) {
          mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
          continue;
        }
        switch (maint.opcode) {
          case MCU_MAINTENANCE_OP_UPDATE_REQUEST:
            mcu_core_request_update(&core, maint.token, now);
            break;
          case MCU_MAINTENANCE_OP_UPDATE_ARM:
            mcu_core_arm_update(&core, maint.token, now);
            break;
          case MCU_MAINTENANCE_OP_UPDATE_ABORT:
            mcu_core_abort_update(&core, MCU_UPDATE_RESULT_ABORT_HOST);
            break;
          case MCU_MAINTENANCE_OP_SET_TUNING:
            if (!maint.has_tuning_values ||
                !mcu_profile_set_tuning(&profiles, maint.car_type,
                                        maint.force_intensity, maint.motion_range)) {
              mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
              break;
            }
            if (profiles.active_car_type == maint.car_type) {
              mcu_profile_active_params(&profiles, &active_profile);
              apply_profile_to_control(&ctrl_cfg, &ctrl_cfg_base, &active_profile);
            }
            break;
          case MCU_MAINTENANCE_OP_SAVE_PROFILE:
            profiles.storage_loaded = mcu_profile_save_car_type(&profiles, maint.car_type);
            if (!profiles.storage_loaded) {
              mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
            }
            break;
          case MCU_MAINTENANCE_OP_SWITCH_PROFILE:
            if (!mcu_profile_switch_active(&profiles, maint.car_type)) {
              mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
              break;
            }
            if (mcu_profile_active_params(&profiles, &active_profile)) {
              apply_profile_to_control(&ctrl_cfg, &ctrl_cfg_base, &active_profile);
            }
            break;
          case MCU_MAINTENANCE_OP_LOAD_PROFILE:
            profiles.storage_loaded = mcu_profile_load(&profiles);
            if (!profiles.storage_loaded ||
                !mcu_profile_switch_active(&profiles, maint.car_type)) {
              mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
              break;
            }
            if (mcu_profile_active_params(&profiles, &active_profile)) {
              apply_profile_to_control(&ctrl_cfg, &ctrl_cfg_base, &active_profile);
            }
            break;
          case MCU_MAINTENANCE_OP_NONE:
          default:
            mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
            break;
        }
      } else if (frame.header.type == PROTOCOL_TYPE_DIAGNOSTIC) {
        if (frame.header.length >= sizeof(mcu_diag_request_t)) {
          mcu_diag_request_t req;
          memcpy(&req, frame.payload, sizeof(mcu_diag_request_t));
          if (req.magic == MCU_DIAG_MAGIC && req.opcode == MCU_DIAG_OP_REQUEST) {
            mcu_diag_response_t resp = {0};
            resp.magic = MCU_DIAG_MAGIC;
            resp.opcode = MCU_DIAG_OP_RESPONSE;
            resp.token = req.token;
            resp.uptime_ms = now;

            float left_pos = 0.0f;
            float right_pos = 0.0f;
            sensors_read_position(&left_pos, &right_pos);
            resp.left_pos_m = left_pos;
            resp.right_pos_m = right_pos;

            uint16_t left_adc = 0;
            uint16_t right_adc = 0;
            sensors_read_adc(&left_adc, &right_adc);
            resp.left_adc_raw = left_adc;
            resp.right_adc_raw = right_adc;

            bool left_limit = false;
            bool right_limit = false;
            sensors_read_limits(&left_limit, &right_limit);
            resp.left_limit = left_limit ? 1u : 0u;
            resp.right_limit = right_limit ? 1u : 0u;

            float applied_left = 0.0f;
            float applied_right = 0.0f;
            actuators_get_torque(&applied_left, &applied_right);
            resp.left_cmd = applied_left;
            resp.right_cmd = applied_right;
            resp.torque_scale = mcu_core_torque_scale(&core, now);

            size_t out_len = protocol_build_frame(PROTOCOL_TYPE_DIAGNOSTIC, diag_seq++,
                                                  (const uint8_t *)&resp, sizeof(resp),
                                                  diag_buf, sizeof(diag_buf));
            if (out_len > 0) {
              usb_cdc_write(diag_buf, out_len);
            }
          }
        } else {
          mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, now);
        }
      }
    }

    mcu_core_tick(&core, now);

    bool ptt_raw = wheel_ptt_raw_pressed();
    if (!mcu_core_allow_ptt(&core)) {
      mcu_ptt_resync(&ptt, ptt_raw, now);
    } else {
      mcu_ptt_event_type_t ptt_event = mcu_ptt_update(&ptt, ptt_raw, now);
      if (ptt_event != MCU_PTT_EVENT_NONE && usb_ok) {
        mcu_ptt_event_t event = {0};
        event.magic = MCU_PTT_EVENT_MAGIC;
        event.event = (uint8_t)ptt_event;
        event.source = MCU_PTT_SOURCE_STEERING_WHEEL;
        event.uptime_ms = now;
        event.pressed = mcu_ptt_is_pressed(&ptt) ? 1u : 0u;
        size_t out_len = protocol_build_frame(PROTOCOL_TYPE_INPUT_EVENT, ptt_seq++,
                                              (const uint8_t *)&event, sizeof(event),
                                              ptt_buf, sizeof(ptt_buf));
        if (out_len > 0) {
          usb_cdc_write(ptt_buf, out_len);
        }
      }
    }

    if (mcu_core_update_ready(&core, now)) {
      safety_force_stop();
      actuators_set_torque(0.0f, 0.0f);
      bootloader_request_dfu();
    }

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

      float applied_left = control_left_command(&ctrl);
      float applied_right = control_right_command(&ctrl);
      bool jog_active = mcu_jog_update(&jog, now);
      if (jog_active && allow_control && mcu_core_state(&core) != MCU_STATE_FAULT) {
        float jog_left = clampf(mcu_jog_left(&jog), -ctrl_cfg.torque_limit, ctrl_cfg.torque_limit);
        float jog_right = clampf(mcu_jog_right(&jog), -ctrl_cfg.torque_limit, ctrl_cfg.torque_limit);
        applied_left = jog_left * torque_scale;
        applied_right = jog_right * torque_scale;
      }

      if (!allow_control || mcu_core_state(&core) == MCU_STATE_FAULT) {
        mcu_jog_stop(&jog);
        applied_left = 0.0f;
        applied_right = 0.0f;
      }

      actuators_set_torque(applied_left, applied_right);
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
      case MCU_STATE_MAINTENANCE:
        led_state = LED_STATE_MAINTENANCE;
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
      if (mcu_ptt_is_pressed(&ptt)) status.flags |= MCU_STATUS_FLAG_PTT_HELD;
      status.fault_code = mcu_core_fault(&core);
      status.fw_version = FW_VERSION;
      status.fw_build = FW_BUILD_ID;
      status.update_state = (uint8_t)mcu_core_update_state(&core);
      status.update_result = (uint8_t)mcu_core_update_result(&core);
      status.active_car_type = profiles.active_car_type;
      status.profile_flags = 0u;
      if (mcu_profile_active_valid(&profiles)) {
        status.profile_flags |= MCU_STATUS_PROFILE_FLAG_ACTIVE_VALID;
      }
      if (profiles.storage_loaded) {
        status.profile_flags |= MCU_STATUS_PROFILE_FLAG_STORAGE_LOADED;
      }
      status.status_reserved = 0;

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
