#include "mcu_profile.h"

#include <stddef.h>
#include <string.h>

#include "crc16.h"

#pragma pack(push, 1)
typedef struct {
  uint8_t valid;
  uint8_t car_type;
  uint16_t reserved;
  float force_intensity;
  float motion_range;
} mcu_profile_blob_entry_t;

typedef struct {
  uint32_t magic;
  uint8_t version;
  uint8_t active_car_type;
  uint16_t entry_count;
  mcu_profile_blob_entry_t entries[MCU_PROFILE_MAX_CAR_TYPES];
  uint16_t crc;
} mcu_profile_blob_t;
#pragma pack(pop)

static bool valid_car_type(uint8_t car_type) {
  return car_type < MCU_PROFILE_MAX_CAR_TYPES;
}

static float clampf(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

void mcu_profile_default_params(mcu_profile_params_t *out) {
  if (!out) {
    return;
  }
  out->force_intensity = 1.0f;
  out->motion_range = 1.0f;
}

static void normalize_params(mcu_profile_params_t *params) {
  if (!params) {
    return;
  }
  params->force_intensity = clampf(params->force_intensity,
                                   MCU_PROFILE_FORCE_INTENSITY_MIN,
                                   MCU_PROFILE_FORCE_INTENSITY_MAX);
  params->motion_range = clampf(params->motion_range,
                                MCU_PROFILE_MOTION_RANGE_MIN,
                                MCU_PROFILE_MOTION_RANGE_MAX);
}

static void reset_manager(mcu_profile_manager_t *manager) {
  if (!manager) {
    return;
  }
  mcu_profile_params_t defaults = {0};
  mcu_profile_default_params(&defaults);
  for (uint8_t i = 0; i < MCU_PROFILE_MAX_CAR_TYPES; ++i) {
    manager->entries[i].valid = 0u;
    manager->entries[i].car_type = i;
    manager->entries[i].params = defaults;
  }
  manager->entries[MCU_PROFILE_DEFAULT_CAR_TYPE].valid = 1u;
  manager->active_car_type = MCU_PROFILE_DEFAULT_CAR_TYPE;
  manager->active_params = defaults;
}

size_t mcu_profile_blob_size(void) {
  return sizeof(mcu_profile_blob_t);
}

static uint16_t blob_crc(const mcu_profile_blob_t *blob) {
  return crc16_ccitt((const uint8_t *)blob, offsetof(mcu_profile_blob_t, crc), 0xFFFFu);
}

static bool pack_blob(const mcu_profile_manager_t *manager, mcu_profile_blob_t *blob) {
  if (!manager || !blob) {
    return false;
  }
  memset(blob, 0, sizeof(*blob));
  blob->magic = MCU_PROFILE_STORAGE_MAGIC;
  blob->version = MCU_PROFILE_STORAGE_VERSION;
  blob->active_car_type = manager->active_car_type;
  blob->entry_count = MCU_PROFILE_MAX_CAR_TYPES;
  for (uint8_t i = 0; i < MCU_PROFILE_MAX_CAR_TYPES; ++i) {
    blob->entries[i].valid = manager->entries[i].valid;
    blob->entries[i].car_type = manager->entries[i].car_type;
    blob->entries[i].force_intensity = manager->entries[i].params.force_intensity;
    blob->entries[i].motion_range = manager->entries[i].params.motion_range;
  }
  blob->crc = blob_crc(blob);
  return true;
}

static bool unpack_blob(mcu_profile_manager_t *manager, const mcu_profile_blob_t *blob) {
  if (!manager || !blob) {
    return false;
  }
  if (blob->magic != MCU_PROFILE_STORAGE_MAGIC ||
      blob->version != MCU_PROFILE_STORAGE_VERSION ||
      blob->entry_count != MCU_PROFILE_MAX_CAR_TYPES) {
    return false;
  }
  if (blob->crc != blob_crc(blob)) {
    return false;
  }

  reset_manager(manager);
  for (uint8_t i = 0; i < MCU_PROFILE_MAX_CAR_TYPES; ++i) {
    const mcu_profile_blob_entry_t *src = &blob->entries[i];
    if (!valid_car_type(src->car_type)) {
      continue;
    }
    mcu_profile_entry_t *dst = &manager->entries[src->car_type];
    dst->valid = src->valid ? 1u : 0u;
    dst->car_type = src->car_type;
    dst->params.force_intensity = src->force_intensity;
    dst->params.motion_range = src->motion_range;
    normalize_params(&dst->params);
  }

  if (!valid_car_type(blob->active_car_type)) {
    manager->active_car_type = MCU_PROFILE_DEFAULT_CAR_TYPE;
  } else {
    manager->active_car_type = blob->active_car_type;
  }

  if (!manager->entries[manager->active_car_type].valid) {
    manager->entries[manager->active_car_type].valid = 1u;
    mcu_profile_default_params(&manager->entries[manager->active_car_type].params);
  }
  manager->active_params = manager->entries[manager->active_car_type].params;
  return true;
}

void mcu_profile_manager_init(mcu_profile_manager_t *manager,
                              mcu_profile_store_read_fn read_fn,
                              mcu_profile_store_write_fn write_fn,
                              void *storage_ctx) {
  if (!manager) {
    return;
  }
  memset(manager, 0, sizeof(*manager));
  manager->read_fn = read_fn;
  manager->write_fn = write_fn;
  manager->storage_ctx = storage_ctx;

  reset_manager(manager);
  manager->storage_loaded = mcu_profile_load(manager);
}

bool mcu_profile_load(mcu_profile_manager_t *manager) {
  if (!manager || !manager->read_fn) {
    return false;
  }
  mcu_profile_blob_t blob = {0};
  if (!manager->read_fn(manager->storage_ctx, (uint8_t *)&blob, sizeof(blob))) {
    return false;
  }
  return unpack_blob(manager, &blob);
}

bool mcu_profile_persist(const mcu_profile_manager_t *manager) {
  if (!manager || !manager->write_fn) {
    return false;
  }
  mcu_profile_blob_t blob = {0};
  if (!pack_blob(manager, &blob)) {
    return false;
  }
  return manager->write_fn(manager->storage_ctx, (const uint8_t *)&blob, sizeof(blob));
}

bool mcu_profile_set_tuning(mcu_profile_manager_t *manager, uint8_t car_type,
                            float force_intensity, float motion_range) {
  if (!manager || !valid_car_type(car_type)) {
    return false;
  }
  mcu_profile_entry_t *entry = &manager->entries[car_type];
  entry->valid = 1u;
  entry->car_type = car_type;
  entry->params.force_intensity = force_intensity;
  entry->params.motion_range = motion_range;
  normalize_params(&entry->params);

  if (manager->active_car_type == car_type) {
    manager->active_params = entry->params;
  }
  return true;
}

bool mcu_profile_switch_active(mcu_profile_manager_t *manager, uint8_t car_type) {
  if (!manager || !valid_car_type(car_type)) {
    return false;
  }
  mcu_profile_entry_t *entry = &manager->entries[car_type];
  if (!entry->valid) {
    entry->valid = 1u;
    entry->car_type = car_type;
    mcu_profile_default_params(&entry->params);
  }
  manager->active_car_type = car_type;
  manager->active_params = entry->params;
  return true;
}

bool mcu_profile_save_car_type(mcu_profile_manager_t *manager, uint8_t car_type) {
  if (!manager || !valid_car_type(car_type)) {
    return false;
  }
  mcu_profile_entry_t *entry = &manager->entries[car_type];
  if (!entry->valid) {
    entry->valid = 1u;
    entry->car_type = car_type;
    mcu_profile_default_params(&entry->params);
  }
  return mcu_profile_persist(manager);
}

bool mcu_profile_get_params(const mcu_profile_manager_t *manager, uint8_t car_type,
                            mcu_profile_params_t *out) {
  if (!manager || !out || !valid_car_type(car_type)) {
    return false;
  }
  const mcu_profile_entry_t *entry = &manager->entries[car_type];
  if (!entry->valid) {
    return false;
  }
  *out = entry->params;
  return true;
}

bool mcu_profile_active_params(const mcu_profile_manager_t *manager,
                               mcu_profile_params_t *out) {
  if (!manager || !out) {
    return false;
  }
  *out = manager->active_params;
  return true;
}

bool mcu_profile_active_valid(const mcu_profile_manager_t *manager) {
  if (!manager || !valid_car_type(manager->active_car_type)) {
    return false;
  }
  return manager->entries[manager->active_car_type].valid != 0u;
}
