"""Original rising console launch cue, synthesized without samples."""
import math
import pathlib
import struct
import wave

rate = 22050
seconds = 1.8
frames = bytearray()
for i in range(round(rate * seconds)):
    t = i / rate
    envelope = min(1, t / .06) * min(1, (seconds - t) / .6)
    shimmer = sum(math.sin(math.tau * f * t) for f in (220, 330, 440, 660)) * .055
    sweep = math.sin(math.tau * (180 * t + 220 * t * t)) * .045
    bell = math.sin(math.tau * 1320 * t) * math.exp(-t * 3) * .055
    left = (shimmer + sweep + bell) * envelope
    right = (shimmer + sweep * .85 + bell * .65) * envelope
    frames.extend(struct.pack('<hh', int(left * 32767), int(right * 32767)))
target = pathlib.Path(__file__).resolve().parents[1] / 'assets/Sons/Futurista/launch.wav'
target.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(target), 'wb') as output:
    output.setnchannels(2)
    output.setsampwidth(2)
    output.setframerate(rate)
    output.writeframes(frames)
