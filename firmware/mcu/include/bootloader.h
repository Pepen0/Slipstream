#pragma once

#include <stdbool.h>

bool bootloader_dfu_requested(void);
void bootloader_request_dfu(void);
void bootloader_enter_dfu(void);
