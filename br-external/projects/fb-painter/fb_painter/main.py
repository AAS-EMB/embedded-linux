import time
import os
import sys

from .canvas import Canvas
from .touch  import TouchReader
from .config import COLORS, UI_DEBOUNCE, FB_DEV, INPUT_DEV


def run() -> None:
    if not os.path.exists(FB_DEV):
        print(f"Error: {FB_DEV} not found. Is DRM/fbdev loaded?", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(INPUT_DEV):
        print(f"Error: {INPUT_DEV} not found.", file=sys.stderr)
        sys.exit(1)

    canvas = Canvas()
    touch  = TouchReader()

    color               = COLORS[2]
    prev_x = prev_y     = None
    was_touching        = False
    stroke_saved        = False
    last_ui_action_time = 0.0

    print("fb-painter ready. Touch to draw.")

    try:
        while True:
            x, y, _, touching = touch.get()

            if touching:
                action, val = canvas.get_action_at(x, y)
                now = time.monotonic()
                debounced = (now - last_ui_action_time) > UI_DEBOUNCE

                if action == 'color' and debounced:
                    color = val
                    last_ui_action_time = now
                    prev_x = prev_y = None
                    stroke_saved = False

                elif action == 'undo' and debounced:
                    canvas.undo()
                    last_ui_action_time = now
                    prev_x = prev_y = None
                    stroke_saved = False

                elif action == 'clear' and debounced:
                    canvas.save_state()
                    canvas.clear()
                    canvas._draw_ui()
                    canvas.flush()
                    last_ui_action_time = now
                    prev_x = prev_y = None
                    stroke_saved = False

                elif action == 'draw':
                    if not stroke_saved:
                        canvas.save_state()
                        stroke_saved = True
                    if prev_x is not None and was_touching:
                        canvas.draw_line(prev_x, prev_y, x, y, color, 4)
                    else:
                        canvas.draw_circle(x, y, 4, color)
                    canvas.flush()
                    prev_x, prev_y = x, y

            else:
                prev_x = prev_y = None
                stroke_saved = False

            was_touching = touching
            time.sleep(0.01)

    except KeyboardInterrupt:
        print("\nExiting.")
    finally:
        canvas.close()


if __name__ == "__main__":
    run()