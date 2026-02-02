#include "ring_buffer.h"

void rb_init(ring_buffer_t *rb, uint8_t *storage, size_t size) {
  rb->buf = storage;
  rb->size = size;
  rb->head = 0;
  rb->tail = 0;
}

static size_t rb_used(const ring_buffer_t *rb) {
  if (rb->head >= rb->tail) {
    return rb->head - rb->tail;
  }
  return rb->size - (rb->tail - rb->head);
}

size_t rb_available(const ring_buffer_t *rb) {
  return rb_used(rb);
}

size_t rb_free(const ring_buffer_t *rb) {
  return rb->size - rb_used(rb) - 1;
}

size_t rb_write(ring_buffer_t *rb, const uint8_t *data, size_t len) {
  size_t written = 0;
  while (written < len && rb_free(rb) > 0) {
    rb->buf[rb->head] = data[written++];
    rb->head = (rb->head + 1) % rb->size;
  }
  return written;
}

size_t rb_read(ring_buffer_t *rb, uint8_t *dst, size_t len) {
  size_t read = 0;
  while (read < len && rb_available(rb) > 0) {
    dst[read++] = rb->buf[rb->tail];
    rb->tail = (rb->tail + 1) % rb->size;
  }
  return read;
}

size_t rb_peek(const ring_buffer_t *rb, uint8_t *dst, size_t len) {
  size_t available = rb_available(rb);
  if (len > available) {
    len = available;
  }
  size_t idx = rb->tail;
  for (size_t i = 0; i < len; ++i) {
    dst[i] = rb->buf[idx];
    idx = (idx + 1) % rb->size;
  }
  return len;
}

void rb_drop(ring_buffer_t *rb, size_t len) {
  size_t available = rb_available(rb);
  if (len > available) {
    len = available;
  }
  rb->tail = (rb->tail + len) % rb->size;
}
