#pragma once

void actuators_init(void);
void actuators_set_torque(float left, float right);
void actuators_get_torque(float *left, float *right);
