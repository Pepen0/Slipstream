#pragma once

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void safety_init(void);
void safety_force_stop(void);
void safety_set_pwm_enabled(bool enable);
bool safety_is_pwm_enabled(void);

bool safety_read_estop_pin(void);
void safety_on_estop_irq(void);
bool safety_estop_irq_pending(void);
void safety_clear_estop_irq(void);

#ifdef __cplusplus
}
#endif
