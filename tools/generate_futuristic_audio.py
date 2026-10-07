"""Generate original console ambience and soft interface tones (no samples)."""
import math
import pathlib
import random
import struct
import wave

ROOT = pathlib.Path(__file__).resolve().parents[1] / 'assets/Sons/Futurista'
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050


def write(name, seconds, sample):
    with wave.open(str(ROOT / name), 'wb') as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        frames = bytearray()
        for i in range(round(seconds * RATE)):
            left, right = sample(i / RATE, i)
            frames.extend(struct.pack('<hh', int(max(-1, min(1, left)) * 32767),
                                      int(max(-1, min(1, right)) * 32767)))
        output.writeframes(frames)


def tone(seconds, frequencies):
    def sample(t, _):
        envelope = (1 - math.exp(-t * 160)) * math.exp(-t * 23)
        envelope *= min(1, (seconds - t) * 100)
        value = sum(math.sin(math.tau * f * t) / (i + 1)
                    for i, f in enumerate(frequencies)) * envelope * .19
        return value, value
    return sample


write('move.wav', .18, tone(.18, [660, 990, 1320]))
write('open.wav', .4, tone(.4, [440, 660, 880, 1100]))

# All oscillators complete whole cycles over 24s, including the stereo swell.
# Low-pass water noise is crossfaded across the loop boundary.
rng = random.Random(71)
noise = []
value = 0
for _ in range(RATE * 24):
    value = .985 * value + .015 * rng.uniform(-1, 1)
    noise.append(value)
edge = RATE
boundary = (noise[0] + noise[-1]) / 2
for i in range(edge):
    mix = i / edge
    noise[i] = noise[i] * mix + boundary * (1 - mix)
    noise[-1 - i] = noise[-1 - i] * mix + boundary * (1 - mix)


def ambient(t, i):
    # Airy suspended chord, warm bass and delicate stereo bell particles.
    swell = .72 + .14 * math.sin(math.tau * t / 24)
    frequencies = [110, 164.8333333333, 220, 293.6666666667, 329.625, 440]
    pad_left = sum(math.sin(math.tau * f * t + j * .3) / (j + 2)
                   for j, f in enumerate(frequencies)) * .11
    pad_right = sum(math.sin(math.tau * f * t - j * .3) / (j + 2)
                    for j, f in enumerate(frequencies)) * .11
    shimmer = (.5 + .5 * math.cos(math.tau * t / 6)) ** 8
    bell = (math.sin(math.tau * 880 * t) + .3 * math.sin(math.tau * 1320 * t)) * .012 * shimmer
    air = noise[i] * .035
    return pad_left * swell + bell + air, pad_right * (1.44 - swell) + bell * .7 + air


write('water_ambient.wav', 24, ambient)
