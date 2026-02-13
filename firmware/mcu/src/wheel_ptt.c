#include "wheel_ptt.h"

#include "app_config.h"

void wheel_ptt_init(void) {
#if APP_WHEEL_PTT_ENABLED
  WHEEL_PTT_GPIO_CLK_ENABLE();

  GPIO_InitTypeDef gpio = {0};
  gpio.Pin = WHEEL_PTT_PIN;
  gpio.Mode = GPIO_MODE_INPUT;
  gpio.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(WHEEL_PTT_GPIO_PORT, &gpio);
#endif
}

bool wheel_ptt_raw_pressed(void) {
#if APP_WHEEL_PTT_ENABLED
  return (HAL_GPIO_ReadPin(WHEEL_PTT_GPIO_PORT, WHEEL_PTT_PIN) ==
          WHEEL_PTT_ACTIVE_STATE);
#else
  return false;
#endif
}
