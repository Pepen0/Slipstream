#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "ring_buffer.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PROTOCOL_MAGIC 0xA5C3F00Du
#define PROTOCOL_VERSION 1u
#define PROTOCOL_MAX_PAYLOAD 64u

typedef enum {
  PROTOCOL_TYPE_HEARTBEAT = 0x01,
  PROTOCOL_TYPE_COMMAND   = 0x02,
  PROTOCOL_TYPE_STATUS    = 0x10
} protocol_type_t;

#pragma pack(push, 1)
typedef struct {
  uint32_t magic;
  uint8_t version;
  uint8_t type;
  uint16_t length;
  uint32_t seq;
} protocol_header_t;
#pragma pack(pop)

typedef struct {
  protocol_header_t header;
  uint8_t payload[PROTOCOL_MAX_PAYLOAD];
  uint16_t crc;
} protocol_frame_t;

bool protocol_try_parse(ring_buffer_t *rb, protocol_frame_t *out);
uint16_t protocol_crc(const protocol_header_t *hdr, const uint8_t *payload, size_t len);

#ifdef __cplusplus
}
#endif
