#include "frame_batcher.h"
#include "protocol.h"

#include <cassert>

using namespace heartbeat;

int main() {
  FrameBatcher batcher(64);

  auto f1 = build_frame(PacketType::Heartbeat, 1, nullptr, 0);
  auto f2 = build_frame(PacketType::Heartbeat, 2, nullptr, 0);

  assert(batcher.append(f1));
  assert(batcher.append(f2));
  assert(batcher.size() == f1.size() + f2.size());

  FrameBatcher tiny(8);
  assert(!tiny.append(f1));

  FrameBatcher small(20);
  assert(small.append(f1));
  assert(!small.append(f2));

  return 0;
}
