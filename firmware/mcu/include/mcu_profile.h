#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MCU_PROFILE_MAX_CAR_TYPES 8u
#define MCU_PROFILE_DEFAULT_CAR_TYPE 0u
#define MCU_PROFILE_FORCE_INTENSITY_MIN 0.10f
#define MCU_PROFILE_FORCE_INTENSITY_MAX 1.00f
#define MCU_PROFILE_MOTION_RANGE_MIN 0.20f
#define MCU_PROFILE_MOTION_RANGE_MAX 1.00f
#define MCU_PROFILE_STORAGE_MAGIC 0x5052464Cu
#define MCU_PROFILE_STORAGE_VERSION 1u

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  float force_intensity;
  float motion_range;
} mcu_profile_params_t;

typedef bool (*mcu_profile_store_read_fn)(void *ctx, uint8_t *out, size_t len);
typedef bool (*mcu_profile_store_write_fn)(void *ctx, const uint8_t *data, size_t len);

typedef struct {
  uint8_t valid;
  uint8_t car_type;
  mcu_profile_params_t params;
} mcu_profile_entry_t;

typedef struct {
  mcu_profile_store_read_fn read_fn;
  mcu_profile_store_write_fn write_fn;
  void *storage_ctx;
  uint8_t active_car_type;
  mcu_profile_params_t active_params;
  mcu_profile_entry_t entries[MCU_PROFILE_MAX_CAR_TYPES];
  bool storage_loaded;
} mcu_profile_manager_t;

size_t mcu_profile_blob_size(void);
void mcu_profile_default_params(mcu_profile_params_t *out);
void mcu_profile_manager_init(mcu_profile_manager_t *manager,
                              mcu_profile_store_read_fn read_fn,
                              mcu_profile_store_write_fn write_fn,
                              void *storage_ctx);
bool mcu_profile_load(mcu_profile_manager_t *manager);
bool mcu_profile_persist(const mcu_profile_manager_t *manager);
bool mcu_profile_set_tuning(mcu_profile_manager_t *manager, uint8_t car_type,
                            float force_intensity, float motion_range);
bool mcu_profile_switch_active(mcu_profile_manager_t *manager, uint8_t car_type);
bool mcu_profile_save_car_type(mcu_profile_manager_t *manager, uint8_t car_type);
bool mcu_profile_get_params(const mcu_profile_manager_t *manager, uint8_t car_type,
                            mcu_profile_params_t *out);
bool mcu_profile_active_params(const mcu_profile_manager_t *manager,
                               mcu_profile_params_t *out);
bool mcu_profile_active_valid(const mcu_profile_manager_t *manager);

#ifdef __cplusplus
}
#endif
