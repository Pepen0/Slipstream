#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  uint8_t *buf;
  size_t size;
  size_t head;
  size_t tail;
} ring_buffer_t;

void rb_init(ring_buffer_t *rb, uint8_t *storage, size_t size);
size_t rb_available(const ring_buffer_t *rb);
size_t rb_free(const ring_buffer_t *rb);
size_t rb_write(ring_buffer_t *rb, const uint8_t *data, size_t len);
size_t rb_read(ring_buffer_t *rb, uint8_t *dst, size_t len);
size_t rb_peek(const ring_buffer_t *rb, uint8_t *dst, size_t len);
void rb_drop(ring_buffer_t *rb, size_t len);

#ifdef __cplusplus
}
#endif
