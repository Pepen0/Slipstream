#include "stm32f1xx_hal.h"
#include "app_config.h"
#include "mcu_core.h"
#include "protocol.h"
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
  usb_cdc_init();

  mcu_core_t core;
  mcu_core_init(&core, HAL_GetTick(), APP_HEARTBEAT_TIMEOUT_MS);

  protocol_frame_t frame;

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
      }
    }

    mcu_core_tick(&core, now);

    if (mcu_core_should_energize(&core, now)) {
      safety_set_pwm_enabled(true);
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
