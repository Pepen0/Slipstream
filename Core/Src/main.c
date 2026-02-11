/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Steering Joystick (PA0/A0) + Throttle Pot (PC4/A4) over UART
  *
  * NUCLEO-C071RB wiring:
  *   Steering joystick VRx -> A0  (PA0 / ADC1_IN0  / ADC_CHANNEL_0)
  *   Throttle potentiometer wiper -> A4 (PC4 / ADC1_IN11 / ADC_CHANNEL_11)
  *   (If wiring to Arduino A3, use PB0 / ADC channel for PB0 instead.)
  *   Pot outer pins -> 3.3V and GND
  *
  * UART:
  *   USART2 @ 115200 8N1 -> STLink VCP (COM3)
  ******************************************************************************
  */
/* USER CODE END Header */

#include "main.h"

/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
/* USER CODE END Includes */

/* USER CODE BEGIN PD */
#define DEADZONE_PCT   5
#define MAX_ANGLE_DEG  90
#define CALIB_SAMPLES  64
#define THR_DEADBAND   10
#define LOOP_DELAY_MS  20   // ~50 Hz (safe at 115200 with verbose line)
/* USER CODE END PD */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc1;
UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
volatile uint32_t rawS = 0;      // steering raw (PA0 / CH0)
volatile uint32_t rawT = 0;      // throttle raw (PC4 / CH11)

volatile uint32_t centerS  = 2048;
volatile uint32_t leftS    = 2048;
volatile uint32_t rightS   = 2048;

volatile uint32_t thr_rest = 2048;
volatile uint32_t thr_max  = 2048;

volatile int32_t steer_pct = 0;  // -100..+100
volatile int32_t angle_deg = 0;  // -90..+90
volatile int32_t thr_pct   = 0;  // 0..100
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_ADC1_Init(void);
static void MX_USART2_UART_Init(void);

/* USER CODE BEGIN 0 */
static int32_t clamp_i32(int32_t x, int32_t lo, int32_t hi)
{
  if (x < lo) return lo;
  if (x > hi) return hi;
  return x;
}

static uint32_t adc_read_channel(uint32_t channel)
{
  ADC_ChannelConfTypeDef sConfig = {0};
  sConfig.Channel = channel;
  sConfig.Rank    = ADC_REGULAR_RANK_1;
  sConfig.SamplingTime = ADC_SAMPLINGTIME_COMMON_1;

  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }

  // Dummy conversion after channel switch
  HAL_ADC_Start(&hadc1);
  HAL_ADC_PollForConversion(&hadc1, 10);
  (void)HAL_ADC_GetValue(&hadc1);

  // Real conversion
  HAL_ADC_Start(&hadc1);
  HAL_ADC_PollForConversion(&hadc1, 10);
  uint32_t v = HAL_ADC_GetValue(&hadc1);
  HAL_ADC_Stop(&hadc1);

  return v;
}

static void uart_tx(const char *s)
{
  HAL_UART_Transmit(&huart2, (uint8_t*)s, (uint16_t)strlen(s), 100);
}
/* USER CODE END 0 */

int main(void)
{
  HAL_Init();
  SystemClock_Config();

  MX_GPIO_Init();
  MX_ADC1_Init();
  MX_USART2_UART_Init();

  /* USER CODE BEGIN 2 */
  // Give STLink VCP time to enumerate
  HAL_Delay(1500);

  uart_tx("HELLO\r\n");

  // --- Calibrate steering center (hands off steering joystick) ---
  uint32_t sumS = 0;
  for (int i = 0; i < CALIB_SAMPLES; i++)
  {
    sumS += adc_read_channel(ADC_CHANNEL_0);   // PA0
    HAL_Delay(2);
  }
  centerS = sumS / CALIB_SAMPLES;
  leftS = centerS;
  rightS = centerS;

  // --- Calibrate throttle rest (hands off pot / set to idle position) ---
  uint32_t sumT = 0;
  for (int i = 0; i < CALIB_SAMPLES; i++)
  {
    sumT += adc_read_channel(ADC_CHANNEL_11);  // PC4 (A4)
    HAL_Delay(2);
  }
  thr_rest = sumT / CALIB_SAMPLES;

  // Start thr_max slightly above rest; you'll learn max by turning pot up once
  thr_max = thr_rest + 50;
  if (thr_max > 4095) thr_max = 4095;

  char bootmsg[200];
  int bootlen = snprintf(bootmsg, sizeof(bootmsg),
    "OK | steer CH0 center=%lu | thr CH11 rest=%lu\r\n",
    (unsigned long)centerS, (unsigned long)thr_rest);
  HAL_UART_Transmit(&huart2, (uint8_t*)bootmsg, (uint16_t)bootlen, 100);
  /* USER CODE END 2 */

  while (1)
  {
    // Read both inputs (SEPARATE devices now)
    rawS = adc_read_channel(ADC_CHANNEL_0);    // Steering joystick PA0
    rawT = adc_read_channel(ADC_CHANNEL_11);   // Throttle pot PC4 ✅ CHANGED

    // Learn steering min/max over time
    if (rawS < leftS)  leftS  = rawS;
    if (rawS > rightS) rightS = rawS;

    // Learn throttle max over time (turn pot to max once)
    if (rawT > thr_max) thr_max = rawT;

    // --- Steering mapping (-100..+100 with deadzone) ---
    int32_t ds = (int32_t)rawS - (int32_t)centerS;

    int32_t spanR = (int32_t)rightS - (int32_t)centerS;
    int32_t spanL = (int32_t)centerS - (int32_t)leftS;
    if (spanR < 10) spanR = 10;
    if (spanL < 10) spanL = 10;

    int32_t deadzone_counts = (DEADZONE_PCT * 4095) / 100;

    if (abs(ds) <= deadzone_counts)
      steer_pct = 0;
    else if (ds > 0)
      steer_pct = (ds * 100) / spanR;
    else
      steer_pct = (ds * 100) / spanL;

    steer_pct = clamp_i32(steer_pct, -100, 100);
    angle_deg = (steer_pct * MAX_ANGLE_DEG) / 100;

    // --- Throttle mapping (0..100 from rest->max) ---
    int32_t dt = (int32_t)rawT - (int32_t)thr_rest;
    if (dt < THR_DEADBAND) dt = 0;

    int32_t thr_span = (int32_t)thr_max - (int32_t)thr_rest;
    if (thr_span < 1) thr_span = 1;

    thr_pct = (dt * 100) / thr_span;
    thr_pct = clamp_i32(thr_pct, 0, 100);

    // Verbose output (same style as before)
    char msg[220];
    int len = snprintf(msg, sizeof(msg),
      "S=%4lu (L=%4lu C=%4lu R=%4lu) | steer=%4ld%% angle=%4lddeg || "
      "T=%4lu (rest=%4lu max=%4lu) | thr=%3ld%%\r\n",
      (unsigned long)rawS,
      (unsigned long)leftS, (unsigned long)centerS, (unsigned long)rightS,
      (long)steer_pct, (long)angle_deg,
      (unsigned long)rawT,
      (unsigned long)thr_rest, (unsigned long)thr_max,
      (long)thr_pct);

    HAL_UART_Transmit(&huart2, (uint8_t*)msg, (uint16_t)len, 100);

    HAL_Delay(LOOP_DELAY_MS);
  }
}

/* ---- Init functions (kept standard) ---- */

void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  __HAL_FLASH_SET_LATENCY(FLASH_LATENCY_0);

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSIDiv = RCC_HSI_DIV4;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.SYSCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_APB1_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

static void MX_ADC1_Init(void)
{
  ADC_ChannelConfTypeDef sConfig = {0};

  hadc1.Instance = ADC1;
  hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV1;
  hadc1.Init.Resolution = ADC_RESOLUTION_12B;
  hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc1.Init.ScanConvMode = ADC_SCAN_DISABLE;
  hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
  hadc1.Init.LowPowerAutoWait = DISABLE;
  hadc1.Init.LowPowerAutoPowerOff = DISABLE;
  hadc1.Init.ContinuousConvMode = DISABLE;
  hadc1.Init.NbrOfConversion = 1;
  hadc1.Init.DiscontinuousConvMode = DISABLE;
  hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc1.Init.DMAContinuousRequests = DISABLE;
  hadc1.Init.Overrun = ADC_OVR_DATA_PRESERVED;
  hadc1.Init.SamplingTimeCommon1 = ADC_SAMPLETIME_12CYCLES_5;
  hadc1.Init.OversamplingMode = DISABLE;
  hadc1.Init.TriggerFrequencyMode = ADC_TRIGGER_FREQ_HIGH;
  if (HAL_ADC_Init(&hadc1) != HAL_OK)
  {
    Error_Handler();
  }

  // Base channel config; actual channel selected in adc_read_channel()
  sConfig.Channel = ADC_CHANNEL_0;
  sConfig.Rank = ADC_REGULAR_RANK_1;
  sConfig.SamplingTime = ADC_SAMPLINGTIME_COMMON_1;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
}

static void MX_USART2_UART_Init(void)
{
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart2.Init.ClockPrescaler = UART_PRESCALER_DIV1;
  huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
}

static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOC_CLK_ENABLE();

  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);

  // Keep PA1 as GPIO input (your button)
  GPIO_InitStruct.Pin = GPIO_PIN_1;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  // PA5 output (LED)
  GPIO_InitStruct.Pin = GPIO_PIN_5;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
}

void Error_Handler(void)
{
  const char *e = "ERROR_HANDLER\r\n";
  HAL_UART_Transmit(&huart2, (uint8_t*)e, (uint16_t)strlen(e), 100);
  __disable_irq();
  while (1) { }
}
