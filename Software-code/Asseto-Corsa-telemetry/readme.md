# The code that get telemetry data from Asseto-Corsa

# Generate Python stubs
```bash

python -m grpc_tools.protoc -I ./proto --python_out=. --grpc_python_out=. proto/telemetry/v1/telemetry.proto

```