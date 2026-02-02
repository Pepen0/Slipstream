#include "led.h"
#include "app_config.h"

static led_state_t current_state = LED_STATE_IDLE;
static uint32_t last_toggle_ms = 0;
static GPIO_PinState led_level = GPIO_PIN_RESET;

void led_init(void) {
  LED_GPIO_CLK_ENABLE();
  GPIO_InitTypeDef gpio = {0};
  gpio.Pin = LED_PIN;
  gpio.Mode = GPIO_MODE_OUTPUT_PP;
  gpio.Pull = GPIO_NOPULL;
  gpio.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LED_GPIO_PORT, &gpio);
  HAL_GPIO_WritePin(LED_GPIO_PORT, LED_PIN, GPIO_PIN_SET);
}

void led_set_state(led_state_t state) {
  current_state = state;
}

static uint32_t period_for_state(led_state_t state) {
  switch (state) {
    case LED_STATE_ACTIVE:
      return 0; // solid on
    case LED_STATE_FAULT:
      return 200; // fast blink
    case LED_STATE_IDLE:
    default:
      return 1000; // slow blink
  }
}

void led_tick(uint32_t now_ms) {
  uint32_t period = period_for_state(current_state);
  if (current_state == LED_STATE_ACTIVE) {
    HAL_GPIO_WritePin(LED_GPIO_PORT, LED_PIN, GPIO_PIN_RESET);
    return;
  }

  if (period == 0) {
    return;
  }

  if ((now_ms - last_toggle_ms) >= period) {
    last_toggle_ms = now_ms;
    led_level = (led_level == GPIO_PIN_RESET) ? GPIO_PIN_SET : GPIO_PIN_RESET;
    HAL_GPIO_WritePin(LED_GPIO_PORT, LED_PIN, led_level);
  }
}
