#include <unity.h>
#include "mcu_jog.h"

void test_jog_start_and_timeout(void) {
  mcu_jog_state_t jog;
  mcu_jog_init(&jog);

  mcu_jog_command_t cmd = {0};
  cmd.magic = MCU_JOG_MAGIC;
  cmd.mode = MCU_JOG_MODE_TORQUE;
  cmd.left_torque = 0.4f;
  cmd.right_torque = -0.2f;
  cmd.duration_ms = 100;

  TEST_ASSERT_TRUE(mcu_jog_start(&jog, &cmd, 1000, 150, 500));
  TEST_ASSERT_TRUE(mcu_jog_active(&jog));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.4f, mcu_jog_left(&jog));
  TEST_ASSERT_FLOAT_WITHIN(1e-6f, -0.2f, mcu_jog_right(&jog));

  TEST_ASSERT_TRUE(mcu_jog_update(&jog, 1050));
  TEST_ASSERT_FALSE(mcu_jog_update(&jog, 1101));
  TEST_ASSERT_FALSE(mcu_jog_active(&jog));
}

void test_jog_stop_command(void) {
  mcu_jog_state_t jog;
  mcu_jog_init(&jog);

  mcu_jog_command_t cmd = {0};
  cmd.magic = MCU_JOG_MAGIC;
  cmd.mode = MCU_JOG_MODE_TORQUE;
  cmd.left_torque = 0.5f;
  cmd.right_torque = 0.5f;
  cmd.duration_ms = 200;

  TEST_ASSERT_TRUE(mcu_jog_start(&jog, &cmd, 0, 150, 500));
  TEST_ASSERT_TRUE(mcu_jog_active(&jog));

  mcu_jog_command_t stop = {0};
  stop.magic = MCU_JOG_MAGIC;
  stop.mode = MCU_JOG_MODE_TORQUE;
  stop.left_torque = 0.0f;
  stop.right_torque = 0.0f;
  stop.duration_ms = 0;
  TEST_ASSERT_TRUE(mcu_jog_start(&jog, &stop, 10, 150, 500));
  TEST_ASSERT_FALSE(mcu_jog_active(&jog));
}

void test_jog_default_duration(void) {
  mcu_jog_state_t jog;
  mcu_jog_init(&jog);

  mcu_jog_command_t cmd = {0};
  cmd.magic = MCU_JOG_MAGIC;
  cmd.mode = MCU_JOG_MODE_TORQUE;
  cmd.left_torque = 0.2f;
  cmd.right_torque = 0.2f;
  cmd.duration_ms = 0;

  TEST_ASSERT_TRUE(mcu_jog_start(&jog, &cmd, 500, 150, 500));
  TEST_ASSERT_TRUE(mcu_jog_update(&jog, 649));
  TEST_ASSERT_FALSE(mcu_jog_update(&jog, 651));
}
