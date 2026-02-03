#include <unity.h>
#include "mcu_core.h"

void setUp(void) {}
void tearDown(void) {}

static mcu_core_t core;

void test_usb_disconnect_fault(void) {
  mcu_core_init(&core, 0, 100, 0);
  mcu_core_on_usb(&core, true, 0);
  mcu_core_tick(&core, 0);
  mcu_core_on_heartbeat(&core, 10);
  TEST_ASSERT_EQUAL(MCU_STATE_ACTIVE, mcu_core_state(&core));

  mcu_core_on_usb(&core, false, 20);
  mcu_core_tick(&core, 20);
  TEST_ASSERT_EQUAL(MCU_STATE_FAULT, mcu_core_state(&core));
  TEST_ASSERT_FALSE(mcu_core_should_energize(&core, 20));
}

void test_heartbeat_timeout_fault(void) {
  mcu_core_init(&core, 0, 100, 0);
  mcu_core_on_usb(&core, true, 0);
  mcu_core_on_heartbeat(&core, 0);
  mcu_core_tick(&core, 0);
  TEST_ASSERT_TRUE(mcu_core_should_energize(&core, 50));

  mcu_core_tick(&core, 101);
  TEST_ASSERT_EQUAL(MCU_STATE_FAULT, mcu_core_state(&core));
  TEST_ASSERT_FALSE(mcu_core_should_energize(&core, 101));
}

void test_estop_fault(void) {
  mcu_core_init(&core, 0, 100, 0);
  mcu_core_on_usb(&core, true, 0);
  mcu_core_on_heartbeat(&core, 5);
  mcu_core_tick(&core, 5);
  TEST_ASSERT_EQUAL(MCU_STATE_ACTIVE, mcu_core_state(&core));

  mcu_core_on_estop(&core, true, 6);
  mcu_core_tick(&core, 6);
  TEST_ASSERT_EQUAL(MCU_STATE_FAULT, mcu_core_state(&core));
  TEST_ASSERT_FALSE(mcu_core_should_energize(&core, 6));
}

void test_fault_recover(void) {
  mcu_core_init(&core, 0, 100, 0);
  mcu_core_on_usb(&core, true, 0);
  mcu_core_on_heartbeat(&core, 1);
  mcu_core_tick(&core, 1);

  mcu_core_on_estop(&core, true, 2);
  mcu_core_tick(&core, 2);
  TEST_ASSERT_EQUAL(MCU_STATE_FAULT, mcu_core_state(&core));

  mcu_core_on_estop(&core, false, 10);
  mcu_core_tick(&core, 10);
  TEST_ASSERT_EQUAL(MCU_STATE_IDLE, mcu_core_state(&core));

  mcu_core_on_heartbeat(&core, 15);
  mcu_core_tick(&core, 15);
  TEST_ASSERT_EQUAL(MCU_STATE_ACTIVE, mcu_core_state(&core));
}

void test_no_heartbeat_no_active(void) {
  mcu_core_init(&core, 0, 100, 0);
  mcu_core_on_usb(&core, true, 0);
  mcu_core_tick(&core, 0);
  TEST_ASSERT_EQUAL(MCU_STATE_IDLE, mcu_core_state(&core));
  TEST_ASSERT_FALSE(mcu_core_should_energize(&core, 0));
}

void test_torque_decay_ramp(void) {
  mcu_core_init(&core, 0, 100, 100);
  mcu_core_on_usb(&core, true, 0);
  mcu_core_on_heartbeat(&core, 0);
  mcu_core_tick(&core, 0);
  TEST_ASSERT_EQUAL(MCU_STATE_ACTIVE, mcu_core_state(&core));

  mcu_core_tick(&core, 101);
  TEST_ASSERT_EQUAL(MCU_STATE_FAULT, mcu_core_state(&core));
  TEST_ASSERT_TRUE(mcu_core_should_energize(&core, 120));
  float scale_mid = mcu_core_torque_scale(&core, 150);
  TEST_ASSERT_TRUE(scale_mid < 1.0f && scale_mid > 0.0f);
  TEST_ASSERT_FALSE(mcu_core_should_energize(&core, 250));
  TEST_ASSERT_EQUAL_FLOAT(0.0f, mcu_core_torque_scale(&core, 250));
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;
  UNITY_BEGIN();
  RUN_TEST(test_usb_disconnect_fault);
  RUN_TEST(test_heartbeat_timeout_fault);
  RUN_TEST(test_estop_fault);
  RUN_TEST(test_fault_recover);
  RUN_TEST(test_no_heartbeat_no_active);
  RUN_TEST(test_torque_decay_ramp);
  return UNITY_END();
}
