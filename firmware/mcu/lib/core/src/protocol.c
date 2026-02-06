#include "protocol.h"
#include "crc16.h"

static void read_bytes(ring_buffer_t *rb, uint8_t *dst, size_t len) {
  rb_read(rb, dst, len);
}

uint16_t protocol_crc(const protocol_header_t *hdr, const uint8_t *payload, size_t len) {
  uint16_t crc = crc16_ccitt((const uint8_t *)hdr, sizeof(protocol_header_t), 0xFFFF);
  if (len > 0 && payload != NULL) {
    crc = crc16_ccitt(payload, len, crc);
  }
  return crc;
}

bool protocol_try_parse(ring_buffer_t *rb, protocol_frame_t *out) {
  while (rb_available(rb) >= sizeof(protocol_header_t)) {
    protocol_header_t hdr;
    rb_peek(rb, (uint8_t *)&hdr, sizeof(hdr));

    if (hdr.magic != PROTOCOL_MAGIC || hdr.version != PROTOCOL_VERSION) {
      rb_drop(rb, 1);
      continue;
    }

    size_t total_len = sizeof(protocol_header_t) + hdr.length + sizeof(uint16_t);
    if (hdr.length > PROTOCOL_MAX_PAYLOAD) {
      rb_drop(rb, 1);
      continue;
    }
    if (rb_available(rb) < total_len) {
      return false;
    }

    read_bytes(rb, (uint8_t *)&hdr, sizeof(hdr));
    uint8_t payload[PROTOCOL_MAX_PAYLOAD] = {0};
    if (hdr.length > 0) {
      read_bytes(rb, payload, hdr.length);
    }
    uint16_t crc_field = 0;
    read_bytes(rb, (uint8_t *)&crc_field, sizeof(crc_field));

    uint16_t calc = protocol_crc(&hdr, payload, hdr.length);
    if (crc_field != calc) {
      continue;
    }

    out->header = hdr;
    out->crc = crc_field;
    if (hdr.length > 0) {
      for (size_t i = 0; i < hdr.length; ++i) {
        out->payload[i] = payload[i];
      }
    }
    return true;
  }
  return false;
}

static void write_u32(uint8_t *dst, uint32_t v) {
  dst[0] = (uint8_t)(v & 0xFF);
  dst[1] = (uint8_t)((v >> 8) & 0xFF);
  dst[2] = (uint8_t)((v >> 16) & 0xFF);
  dst[3] = (uint8_t)((v >> 24) & 0xFF);
}

static void write_u16(uint8_t *dst, uint16_t v) {
  dst[0] = (uint8_t)(v & 0xFF);
  dst[1] = (uint8_t)((v >> 8) & 0xFF);
}

size_t protocol_build_frame(uint8_t type, uint32_t seq, const uint8_t *payload, size_t len,
                            uint8_t *out, size_t out_max) {
  if (len > PROTOCOL_MAX_PAYLOAD) {
    len = PROTOCOL_MAX_PAYLOAD;
  }
  size_t total = sizeof(protocol_header_t) + len + sizeof(uint16_t);
  if (out_max < total) {
    return 0;
  }

  protocol_header_t hdr;
  hdr.magic = PROTOCOL_MAGIC;
  hdr.version = PROTOCOL_VERSION;
  hdr.type = type;
  hdr.length = (uint16_t)len;
  hdr.seq = seq;

  write_u32(out, hdr.magic);
  out[4] = hdr.version;
  out[5] = hdr.type;
  write_u16(out + 6, hdr.length);
  write_u32(out + 8, hdr.seq);

  if (len > 0 && payload != NULL) {
    for (size_t i = 0; i < len; ++i) {
      out[sizeof(protocol_header_t) + i] = payload[i];
    }
  }

  uint16_t crc = protocol_crc(&hdr, payload, len);
  write_u16(out + sizeof(protocol_header_t) + len, crc);
  return total;
}
