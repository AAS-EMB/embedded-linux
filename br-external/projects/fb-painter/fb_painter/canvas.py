import numpy as np
from .config import (
    FB_DEV, WIDTH, HEIGHT, BPP,
    BG, COLORS, BAR_H, MAX_HISTORY,
)

_CHARS: dict[str, list[tuple[int, int]]] = {
    'U': [(0,0),(2,0),(0,1),(2,1),(0,2),(2,2),(0,3),(2,3),(1,4)],
    'C': [(1,0),(2,0),(0,1),(0,2),(0,3),(1,4),(2,4)],
}


class Canvas:

    def __init__(self, fb_device: str = FB_DEV):
        self._fb      = open(fb_device, "r+b", buffering=0)
        self.frame    = np.zeros((HEIGHT, WIDTH, BPP), dtype=np.uint8)
        self.history: list[np.ndarray] = []
        self.frame[:] = BG
        self._draw_ui()
        self.flush()

    # ── UI ───────────────────────────────────────────────────────────────────

    def _btn_w(self) -> int:
        return WIDTH // (len(COLORS) + 2)

    def _draw_ui(self) -> None:
        bar_y = HEIGHT - BAR_H
        btn_w = self._btn_w()
        self.frame[bar_y:, :] = (30, 30, 30)

        for i, color in enumerate(COLORS):
            x0 = i * btn_w + 2
            self.frame[bar_y + 4 : HEIGHT - 4, x0 : x0 + btn_w - 4] = color

        # UNDO
        x0 = len(COLORS) * btn_w + 2
        self.frame[bar_y + 4 : HEIGHT - 4, x0 : x0 + btn_w - 4] = (60, 60, 180)
        self._draw_label(x0 + (btn_w - 4) // 2 - 4, bar_y + 14, 'U', (255, 255, 255))

        # CLEAR
        x0 = (len(COLORS) + 1) * btn_w + 2
        self.frame[bar_y + 4 : HEIGHT - 4, x0 : WIDTH - 2] = (80, 80, 80)
        self._draw_label(x0 + (WIDTH - x0) // 2 - 4, bar_y + 14, 'C', (255, 255, 255))

    def _draw_label(self, x: int, y: int, char: str,
                    color: tuple[int, int, int]) -> None:
        for px, py in _CHARS.get(char, []):
            nx, ny = x + px * 2, y + py * 2
            if 0 <= nx < WIDTH and 0 <= ny < HEIGHT:
                self.frame[ny : ny + 2, nx : nx + 2] = color

    # ── History ──────────────────────────────────────────────────────────────

    def save_state(self) -> None:
        self.history.append(self.frame[: HEIGHT - BAR_H, :].copy())
        if len(self.history) > MAX_HISTORY:
            self.history.pop(0)

    def undo(self) -> None:
        if self.history:
            self.frame[: HEIGHT - BAR_H, :] = self.history.pop()
            self._draw_ui()
            self.flush()

    # ── Drawing ──────────────────────────────────────────────────────────────

    def draw_circle(self, cx: int, cy: int, r: int,
                    color: tuple[int, int, int]) -> None:
        x0 = max(0, cx - r);  x1 = min(WIDTH,         cx + r + 1)
        y0 = max(0, cy - r);  y1 = min(HEIGHT - BAR_H, cy + r + 1)
        for y in range(y0, y1):
            for x in range(x0, x1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.frame[y, x] = color

    def draw_line(self, x0: int, y0: int, x1: int, y1: int,
                  color: tuple[int, int, int], r: int) -> None:
        dx    = x1 - x0
        dy    = y1 - y0
        steps = max(abs(dx), abs(dy), 1)
        for i in range(steps + 1):
            self.draw_circle(x0 + dx * i // steps,
                             y0 + dy * i // steps, r, color)

    def clear(self) -> None:
        self.frame[: HEIGHT - BAR_H, :] = BG

    # ── Actions ──────────────────────────────────────────────────────────────

    def get_action_at(self, x: int, y: int):
        if y < HEIGHT - BAR_H:
            return 'draw', None
        idx = x // self._btn_w()
        if idx < len(COLORS):       return 'color', COLORS[idx]
        elif idx == len(COLORS):    return 'undo',  None
        else:                       return 'clear', None

    # ── Output ───────────────────────────────────────────────────────────────

    def flush(self) -> None:
        self._fb.seek(0)
        self._fb.write(self.frame.tobytes())

    def close(self) -> None:
        self._fb.close()