#ifndef RUNNER_KEYBOARD_EVENT_GUARD_H_
#define RUNNER_KEYBOARD_EVENT_GUARD_H_
#include <windows.h>

// A repeated Alt-down with no Alt pressed contradicts its modifier state.
// Such stale messages can arrive around native focus changes. Keep valid key
// transitions and repetitions intact; do not forward this inconsistent event.
inline bool IsStaleAltRepeat(UINT message, WPARAM key, LPARAM flags,
                             SHORT left_alt, SHORT right_alt) {
  const bool down = message == WM_KEYDOWN || message == WM_SYSKEYDOWN;
  const bool alt = key == VK_MENU || key == VK_LMENU || key == VK_RMENU;
  const bool repeated = (static_cast<ULONG_PTR>(flags) & (1UL << 30)) != 0;
  const bool held = ((left_alt | right_alt) & 0x8000) != 0;
  return down && alt && repeated && !held;
}
#endif
