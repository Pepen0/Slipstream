#include <unity.h>
#include "mcu_core.h"

static mcu_core_t update_core;

static void init_core(uint32_t now_ms) {
  mcu_core_init(&update_core, now_ms, 100, 0, 100, 100, 20);
  mcu_core_on_usb(&update_core, true, now_ms);
}

void test_update_request_blocks_energize(void) {
  init_core(0);
  mcu_core_on_heartbeat(&update_core, 1);
  mcu_core_tick(&update_core, 1);
  TEST_ASSERT_EQUAL(MCU_STATE_ACTIVE, mcu_core_state(&update_core));
  TEST_ASSERT_TRUE(mcu_core_should_energize(&update_core, 1));

  mcu_core_request_update(&update_core, 0x1234u, 2);
  TEST_ASSERT_EQUAL(MCU_UPDATE_STATE_REQUESTED, mcu_core_update_state(&update_core));
  TEST_ASSERT_EQUAL(MCU_STATE_MAINTENANCE, mcu_core_state(&update_core));
  TEST_ASSERT_FALSE(mcu_core_should_energize(&update_core, 2));
}

void test_update_arm_ready(void) {
  init_core(0);
  mcu_core_request_update(&update_core, 0xABCDu, 5);
  TEST_ASSERT_EQUAL(MCU_UPDATE_STATE_REQUESTED, mcu_core_update_state(&update_core));
  TEST_ASSERT_TRUE(mcu_core_arm_update(&update_core, 0xABCDu, 6));
  TEST_ASSERT_EQUAL(MCU_UPDATE_STATE_ARMED, mcu_core_update_state(&update_core));
  TEST_ASSERT_FALSE(mcu_core_update_ready(&update_core, 10));
  TEST_ASSERT_TRUE(mcu_core_update_ready(&update_core, 30));
}

void test_update_request_timeout_rollback(void) {
  init_core(0);
  mcu_core_request_update(&update_core, 0x55AAu, 0);
  mcu_core_tick(&update_core, 200);
  TEST_ASSERT_EQUAL(MCU_UPDATE_STATE_IDLE, mcu_core_update_state(&update_core));
  TEST_ASSERT_EQUAL(MCU_UPDATE_RESULT_ABORT_TIMEOUT, mcu_core_update_result(&update_core));
  TEST_ASSERT_EQUAL(MCU_STATE_IDLE, mcu_core_state(&update_core));
}

void test_update_abort_estop(void) {
  init_core(0);
  mcu_core_request_update(&update_core, 0x7777u, 0);
  mcu_core_on_estop(&update_core, true, 1);
  mcu_core_tick(&update_core, 1);
  TEST_ASSERT_EQUAL(MCU_UPDATE_STATE_IDLE, mcu_core_update_state(&update_core));
  TEST_ASSERT_EQUAL(MCU_UPDATE_RESULT_ABORT_ESTOP, mcu_core_update_result(&update_core));
}
