#pragma once

#include <stdbool.h>

void sensors_init(void);
bool sensors_read_position(float *left_m, float *right_m);
bool sensors_read_limits(bool *left_limit, bool *right_limit);
