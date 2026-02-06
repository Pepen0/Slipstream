#pragma once

#include <stdbool.h>
#include <stdint.h>

void sensors_init(void);
bool sensors_read_position(float *left_m, float *right_m);
bool sensors_read_limits(bool *left_limit, bool *right_limit);
bool sensors_read_adc(uint16_t *left_raw, uint16_t *right_raw);
