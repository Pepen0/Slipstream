#include "stm32f1xx_hal.h"
#include "app_config.h"
#include "safety.h"

extern PCD_HandleTypeDef hpcd_USB_FS;

void SysTick_Handler(void) {
  HAL_IncTick();
}

void EXTI0_IRQHandler(void) {
  HAL_GPIO_EXTI_IRQHandler(ESTOP_PIN);
}

void USB_LP_CAN1_RX0_IRQHandler(void) {
  HAL_PCD_IRQHandler(&hpcd_USB_FS);
}

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
  if (GPIO_Pin == ESTOP_PIN) {
    safety_on_estop_irq();
  }
}
