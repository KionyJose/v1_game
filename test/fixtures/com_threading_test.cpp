#include <windows.h>
#include <objbase.h>
#include <cassert>
#include <cstdio>
#include <thread>

int main() {
  // Reproduce miniaudio's init/uninit sequence on the old shared STA thread.
  assert(SUCCEEDED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)));
  assert(CoInitializeEx(nullptr, COINIT_MULTITHREADED) == RPC_E_CHANGED_MODE);
  CoUninitialize();  // The legacy audio helper does this even after failure.
  APTTYPE type;
  APTTYPEQUALIFIER qualifier;
  assert(CoGetApartmentType(&type, &qualifier) == CO_E_NOTINITIALIZED);

  // With Dart/audio on a separate thread, its COM calls cannot drain the
  // platform apartment that is required by WebView2.
  assert(SUCCEEDED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)));
  std::thread audio([] {
    assert(SUCCEEDED(CoInitializeEx(nullptr, COINIT_MULTITHREADED)));
    CoUninitialize();
  });
  audio.join();
  assert(SUCCEEDED(CoGetApartmentType(&type, &qualifier)));
  assert(type == APTTYPE_STA || type == APTTYPE_MAINSTA);
  CoUninitialize();
  std::puts("COM regression reproduced; separate audio thread preserves STA.");
  return 0;
}
