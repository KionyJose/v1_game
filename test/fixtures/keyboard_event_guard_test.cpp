#include "../../windows/runner/keyboard_event_guard.h"
#include <cassert>
#include <cstdio>

int main() {
  const LPARAM repeat = (1UL << 30);
  const SHORT held = static_cast<SHORT>(0x8000);
  assert(IsStaleAltRepeat(WM_SYSKEYDOWN, VK_MENU, repeat, 0, 0));
  assert(IsStaleAltRepeat(WM_KEYDOWN, VK_LMENU, repeat, 0, 0));
  assert(!IsStaleAltRepeat(WM_SYSKEYDOWN, VK_MENU, repeat, held, 0));
  assert(!IsStaleAltRepeat(WM_SYSKEYDOWN, VK_RMENU, repeat, 0, held));
  assert(!IsStaleAltRepeat(WM_SYSKEYDOWN, VK_MENU, 0, 0, 0));
  assert(!IsStaleAltRepeat(WM_SYSKEYUP, VK_MENU, repeat, 0, 0));
  assert(!IsStaleAltRepeat(WM_KEYDOWN, 'A', repeat, 0, 0));
  puts("Keyboard guard: 7 cases passed");
}
