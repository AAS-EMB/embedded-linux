import struct
import threading
from .config import (
    INPUT_DEV,
    WIDTH, HEIGHT,
    TOUCH_X_MIN, TOUCH_X_MAX,
    TOUCH_Y_MIN, TOUCH_Y_MAX,
)

EVENT_FMT  = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FMT)

EV_SYN       = 0
EV_ABS       = 3
ABS_X        = 0
ABS_Y        = 1
ABS_PRESSURE = 24


def _map(val: int, in_min: int, in_max: int, out_min: int, out_max: int) -> int:
    val = max(in_min, min(in_max, val))
    return int((val - in_min) * (out_max - out_min) / (in_max - in_min) + out_min)


class TouchReader:
    def __init__(self, device: str = INPUT_DEV):
        self._device  = device
        self.x        = 0
        self.y        = 0
        self.pressure = 0
        self.touching = False
        self._lock    = threading.Lock()
        self._thread  = threading.Thread(target=self._read, daemon=True)
        self._thread.start()

    def _read(self) -> None:
        raw_x = raw_y = pressure = 0
        with open(self._device, "rb") as f:
            while True:
                data = f.read(EVENT_SIZE)
                if len(data) < EVENT_SIZE:
                    break
                try:
                    _, _, etype, code, value = struct.unpack(EVENT_FMT, data)
                except struct.error:
                    continue

                if etype == EV_ABS:
                    if   code == ABS_X:        raw_x    = value
                    elif code == ABS_Y:        raw_y    = value
                    elif code == ABS_PRESSURE: pressure = value

                elif etype == EV_SYN:
                    sx = _map(raw_x, TOUCH_X_MIN, TOUCH_X_MAX, 0, WIDTH  - 1)
                    sy = _map(raw_y, TOUCH_Y_MIN, TOUCH_Y_MAX, HEIGHT - 1, 0)
                    with self._lock:
                        self.x        = sx
                        self.y        = sy
                        self.pressure = pressure
                        self.touching = pressure > 0

    def get(self) -> tuple[int, int, int, bool]:
        with self._lock:
            return self.x, self.y, self.pressure, self.touching