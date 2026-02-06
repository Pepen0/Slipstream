#include "safety.h"
#include "app_config.h"

static volatile bool estop_irq = false;
static bool pwm_enabled = false;

void safety_init(void) {
  ESTOP_GPIO_CLK_ENABLE();
  PWM_EN_GPIO_CLK_ENABLE();

  GPIO_InitTypeDef gpio = {0};
  gpio.Pin = ESTOP_PIN;
  gpio.Mode = GPIO_MODE_IT_FALLING;
  gpio.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(ESTOP_GPIO_PORT, &gpio);

  gpio.Pin = PWM_EN_PIN;
  gpio.Mode = GPIO_MODE_OUTPUT_PP;
  gpio.Pull = GPIO_NOPULL;
  gpio.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(PWM_EN_GPIO_PORT, &gpio);

  safety_force_stop();

  HAL_NVIC_SetPriority(EXTI0_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(EXTI0_IRQn);
}

void safety_force_stop(void) {
  pwm_enabled = false;
  HAL_GPIO_WritePin(PWM_EN_GPIO_PORT, PWM_EN_PIN,
                    (PWM_EN_ACTIVE_STATE == GPIO_PIN_SET) ? GPIO_PIN_RESET : GPIO_PIN_SET);
}

void safety_set_pwm_enabled(bool enable) {
  pwm_enabled = enable;
  GPIO_PinState level = enable ? PWM_EN_ACTIVE_STATE :
    ((PWM_EN_ACTIVE_STATE == GPIO_PIN_SET) ? GPIO_PIN_RESET : GPIO_PIN_SET);
  HAL_GPIO_WritePin(PWM_EN_GPIO_PORT, PWM_EN_PIN, level);
}

bool safety_is_pwm_enabled(void) {
  return pwm_enabled;
}

bool safety_read_estop_pin(void) {
  return (HAL_GPIO_ReadPin(ESTOP_GPIO_PORT, ESTOP_PIN) == ESTOP_ACTIVE_STATE);
}

void safety_on_estop_irq(void) {
  estop_irq = true;
  safety_force_stop();
}

bool safety_estop_irq_pending(void) {
  return estop_irq;
}

void safety_clear_estop_irq(void) {
  estop_irq = false;
}
