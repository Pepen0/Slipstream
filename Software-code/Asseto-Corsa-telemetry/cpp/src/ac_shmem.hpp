#pragma once
#include <cstdint>
#include <array>

#pragma pack(push, 4)
struct SPageFilePhysics {
  int32_t packetId;
  float   gas;
  float   brake;
  float   fuel;
  int32_t gear; // -1..7
  int32_t rpms;
  float   steerAngle; // deg
  float   speedKmh;
  std::array<float,3> accG;     // x,y,z
  std::array<float,3> velocity; // local m/s
  std::array<float,3> angularVelocity;
  std::array<float,4> tyreSlip;
  std::array<float,4> tyreLoad;
  std::array<float,4> tyreCoreTemp; // C
  std::array<float,4> suspensionTravel;
};

struct SPageFileGraphics {
  int32_t packetId;
  int32_t status; // 0 off,1 replay,2 live
  int32_t completedLaps;
  int32_t position;
  float   iCurrentTime;
  float   iLastTime;
  float   iBestTime;
  float   lapTime;
  float   deltaLapTime;
  float   normalizedCarPosition;
};

struct SPageFileStatic {
  char    smVersion[15];
  char    acVersion[15];
  char    carModel[33];
  char    track[33];
  char    trackConfiguration[33];
  int32_t maxRpm;
};
#pragma pack(pop)

#define AC_SHM_PHYSICS  L"acpmf_physics"
#define AC_SHM_GRAPHICS L"acpmf_graphics"
#define AC_SHM_STATIC   L"acpmf_static"
