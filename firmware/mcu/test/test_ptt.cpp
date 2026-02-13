#include <unity.h>
#include "mcu_core.h"
#include "mcu_faults.h"
#include "mcu_ptt.h"

void test_ptt_emits_down_up_with_debounce(void) {
  mcu_ptt_state_t ptt;
  mcu_ptt_init(&ptt, 20u, false);

  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_NONE, mcu_ptt_update(&ptt, false, 0u));
  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_NONE, mcu_ptt_update(&ptt, true, 5u));
  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_NONE, mcu_ptt_update(&ptt, true, 24u));
  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_DOWN, mcu_ptt_update(&ptt, true, 25u));
  TEST_ASSERT_TRUE(mcu_ptt_is_pressed(&ptt));

  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_NONE, mcu_ptt_update(&ptt, false, 30u));
  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_NONE, mcu_ptt_update(&ptt, false, 49u));
  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_UP, mcu_ptt_update(&ptt, false, 50u));
  TEST_ASSERT_FALSE(mcu_ptt_is_pressed(&ptt));
}

void test_ptt_resync_suppresses_stale_edges(void) {
  mcu_ptt_state_t ptt;
  mcu_ptt_init(&ptt, 20u, false);

  mcu_ptt_resync(&ptt, true, 100u);
  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_NONE, mcu_ptt_update(&ptt, true, 140u));
  TEST_ASSERT_TRUE(mcu_ptt_is_pressed(&ptt));

  mcu_ptt_resync(&ptt, false, 150u);
  TEST_ASSERT_EQUAL(MCU_PTT_EVENT_NONE, mcu_ptt_update(&ptt, false, 200u));
  TEST_ASSERT_FALSE(mcu_ptt_is_pressed(&ptt));
}

void test_ptt_disabled_during_fault_estop_and_maintenance(void) {
  mcu_core_t core;
  mcu_core_init(&core, 0u, 100u, 100u, 200u, 200u, 50u);

  mcu_core_on_usb(&core, true, 0u);
  mcu_core_on_heartbeat(&core, 1u);
  mcu_core_tick(&core, 1u);
  TEST_ASSERT_TRUE(mcu_core_allow_ptt(&core));

  mcu_core_set_fault(&core, MCU_FAULT_COMMAND_INVALID, 2u);
  TEST_ASSERT_FALSE(mcu_core_allow_ptt(&core));

  mcu_core_on_estop(&core, true, 3u);
  TEST_ASSERT_FALSE(mcu_core_allow_ptt(&core));

  mcu_core_on_estop(&core, false, 10u);
  mcu_core_on_heartbeat(&core, 11u);
  mcu_core_tick(&core, 11u);
  TEST_ASSERT_TRUE(mcu_core_allow_ptt(&core));

  mcu_core_request_update(&core, 0x1122u, 12u);
  TEST_ASSERT_FALSE(mcu_core_allow_ptt(&core));
}
