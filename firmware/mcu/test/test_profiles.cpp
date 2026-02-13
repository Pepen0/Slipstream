#include <unity.h>

#include <cstring>

#include "mcu_maintenance.h"
#include "mcu_profile.h"

namespace {

struct FakeProfileStore {
  uint8_t bytes[256];
  bool has_data;
  bool fail_write;
};

static void reset_store(FakeProfileStore *store) {
  TEST_ASSERT_NOT_NULL(store);
  std::memset(store->bytes, 0xFF, sizeof(store->bytes));
  store->has_data = false;
  store->fail_write = false;
}

static bool fake_read(void *ctx, uint8_t *out, size_t len) {
  FakeProfileStore *store = static_cast<FakeProfileStore *>(ctx);
  if (!store || !out || len == 0 || len > sizeof(store->bytes) || !store->has_data) {
    return false;
  }
  std::memcpy(out, store->bytes, len);
  return true;
}

static bool fake_write(void *ctx, const uint8_t *data, size_t len) {
  FakeProfileStore *store = static_cast<FakeProfileStore *>(ctx);
  if (!store || !data || len == 0 || len > sizeof(store->bytes) || store->fail_write) {
    return false;
  }
  std::memset(store->bytes, 0xFF, sizeof(store->bytes));
  std::memcpy(store->bytes, data, len);
  store->has_data = true;
  return true;
}

} // namespace

void test_profile_defaults_when_storage_missing(void) {
  FakeProfileStore store = {0};
  reset_store(&store);

  mcu_profile_manager_t manager = {0};
  mcu_profile_manager_init(&manager, fake_read, fake_write, &store);

  mcu_profile_params_t active = {0};
  TEST_ASSERT_TRUE(mcu_profile_active_params(&manager, &active));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 1.0f, active.force_intensity);
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 1.0f, active.motion_range);
  TEST_ASSERT_EQUAL_UINT8(MCU_PROFILE_DEFAULT_CAR_TYPE, manager.active_car_type);
  TEST_ASSERT_TRUE(mcu_profile_active_valid(&manager));
  TEST_ASSERT_FALSE(manager.storage_loaded);
}

void test_profile_set_tuning_and_switch_applies_values(void) {
  FakeProfileStore store = {0};
  reset_store(&store);

  mcu_profile_manager_t manager = {0};
  mcu_profile_manager_init(&manager, fake_read, fake_write, &store);

  TEST_ASSERT_TRUE(mcu_profile_set_tuning(&manager, 3u, 0.55f, 0.65f));
  TEST_ASSERT_TRUE(mcu_profile_switch_active(&manager, 3u));
  mcu_profile_params_t active = {0};
  TEST_ASSERT_TRUE(mcu_profile_active_params(&manager, &active));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.55f, active.force_intensity);
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.65f, active.motion_range);

  TEST_ASSERT_TRUE(mcu_profile_set_tuning(&manager, 3u, 4.0f, 0.01f));
  TEST_ASSERT_TRUE(mcu_profile_active_params(&manager, &active));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, MCU_PROFILE_FORCE_INTENSITY_MAX, active.force_intensity);
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, MCU_PROFILE_MOTION_RANGE_MIN, active.motion_range);
}

void test_profile_save_and_reload_per_car_type(void) {
  FakeProfileStore store = {0};
  reset_store(&store);

  mcu_profile_manager_t first = {0};
  mcu_profile_manager_init(&first, fake_read, fake_write, &store);
  TEST_ASSERT_TRUE(mcu_profile_set_tuning(&first, 1u, 0.66f, 0.75f));
  TEST_ASSERT_TRUE(mcu_profile_set_tuning(&first, 5u, 0.33f, 0.45f));
  TEST_ASSERT_TRUE(mcu_profile_switch_active(&first, 5u));
  TEST_ASSERT_TRUE(mcu_profile_save_car_type(&first, 1u));
  TEST_ASSERT_TRUE(mcu_profile_save_car_type(&first, 5u));
  TEST_ASSERT_TRUE(store.has_data);

  mcu_profile_manager_t second = {0};
  mcu_profile_manager_init(&second, fake_read, fake_write, &store);
  TEST_ASSERT_TRUE(second.storage_loaded);
  TEST_ASSERT_EQUAL_UINT8(5u, second.active_car_type);

  mcu_profile_params_t active = {0};
  TEST_ASSERT_TRUE(mcu_profile_active_params(&second, &active));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.33f, active.force_intensity);
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.45f, active.motion_range);

  TEST_ASSERT_TRUE(mcu_profile_switch_active(&second, 1u));
  TEST_ASSERT_TRUE(mcu_profile_active_params(&second, &active));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.66f, active.force_intensity);
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.75f, active.motion_range);
}

void test_profile_save_failure_is_reported(void) {
  FakeProfileStore store = {0};
  reset_store(&store);
  store.fail_write = true;

  mcu_profile_manager_t manager = {0};
  mcu_profile_manager_init(&manager, fake_read, fake_write, &store);
  TEST_ASSERT_TRUE(mcu_profile_set_tuning(&manager, 2u, 0.5f, 0.7f));
  TEST_ASSERT_FALSE(mcu_profile_save_car_type(&manager, 2u));
}

void test_maintenance_decode_profile_commands(void) {
  mcu_maintenance_command_t decoded;
  std::memset(&decoded, 0, sizeof(decoded));

  mcu_maintenance_t switch_cmd = {0};
  switch_cmd.magic = MCU_MAINTENANCE_MAGIC;
  switch_cmd.opcode = MCU_MAINTENANCE_OP_SWITCH_PROFILE;
  switch_cmd.arg0 = 4u;
  switch_cmd.token = 0u;
  TEST_ASSERT_TRUE(mcu_maintenance_decode(reinterpret_cast<const uint8_t *>(&switch_cmd),
                                          sizeof(switch_cmd), &decoded));
  TEST_ASSERT_EQUAL_UINT8(MCU_MAINTENANCE_OP_SWITCH_PROFILE, decoded.opcode);
  TEST_ASSERT_EQUAL_UINT8(4u, decoded.car_type);
  TEST_ASSERT_FALSE(decoded.has_tuning_values);

  mcu_maintenance_tuning_t tuning_cmd = {0};
  tuning_cmd.magic = MCU_MAINTENANCE_MAGIC;
  tuning_cmd.opcode = MCU_MAINTENANCE_OP_SET_TUNING;
  tuning_cmd.car_type = 2u;
  tuning_cmd.force_intensity = 0.8f;
  tuning_cmd.motion_range = 0.6f;
  TEST_ASSERT_TRUE(mcu_maintenance_decode(reinterpret_cast<const uint8_t *>(&tuning_cmd),
                                          sizeof(tuning_cmd), &decoded));
  TEST_ASSERT_EQUAL_UINT8(MCU_MAINTENANCE_OP_SET_TUNING, decoded.opcode);
  TEST_ASSERT_EQUAL_UINT8(2u, decoded.car_type);
  TEST_ASSERT_TRUE(decoded.has_tuning_values);
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.8f, decoded.force_intensity);
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.6f, decoded.motion_range);

  switch_cmd.magic = 0x1111u;
  TEST_ASSERT_FALSE(mcu_maintenance_decode(reinterpret_cast<const uint8_t *>(&switch_cmd),
                                           sizeof(switch_cmd), &decoded));
}
