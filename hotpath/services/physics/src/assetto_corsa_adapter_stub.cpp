#include "assetto_corsa_adapter.h"

namespace slipstream::physics {

struct AssettoCorsaAdapter::Impl {};

AssettoCorsaAdapter::AssettoCorsaAdapter() : impl_(new Impl()) {}
AssettoCorsaAdapter::~AssettoCorsaAdapter() { delete impl_; }

bool AssettoCorsaAdapter::start() { return false; }

bool AssettoCorsaAdapter::read(TelemetrySample &) { return false; }

} // namespace slipstream::physics
