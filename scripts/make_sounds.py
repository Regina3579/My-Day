"""Synthesises My Day's two UI sounds (mono, 44.1 kHz, 16-bit WAV).

Run from MyDay/Resources/Sounds (needs numpy): python3 ../../../scripts/make_sounds.py
"""
import wave
import numpy as np

RATE = 44_100


def bell(freq, start, length, total, partials, attack=0.003):
    """One struck-glass note: decaying sine partials, (ratio, amplitude, decay seconds)."""
    t = np.arange(int(length * RATE)) / RATE
    note = np.zeros_like(t)
    for ratio, amp, decay in partials:
        f = freq * ratio
        if f >= RATE / 2 * 0.9:
            continue
        note += amp * np.sin(2 * np.pi * f * t) * np.exp(-t / decay)
    # Soft raised-cosine attack, so the strike never clicks.
    a = int(attack * RATE)
    note[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    out = np.zeros(int(total * RATE))
    i = int(start * RATE)
    out[i:i + len(note)] += note[:len(out) - i]
    return out


def finish(signal, fade, peak):
    f = int(fade * RATE)
    signal[-f:] *= np.cos(np.linspace(0, np.pi / 2, f)) ** 2
    signal *= peak / np.max(np.abs(signal))
    return signal


def save(name, signal):
    data = (np.clip(signal, -1, 1) * 32767).astype('<i2')
    with wave.open(name, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print(name, f'{len(signal) / RATE:.2f} s', f'{len(data) * 2 // 1024} KB')


# "Ting": a small crystal bell (C7), a slightly detuned twin for shimmer, a warm octave
# below, and quiet glassy overtones that fade quickly.
TING = 0.42
glass = [(1.0, 1.0, 0.13), (1.0032, 0.35, 0.15), (0.5, 0.16, 0.08),
         (2.76, 0.10, 0.045), (5.40, 0.035, 0.02)]
ting = bell(2093.0, 0.0, TING, TING, glass)
save('task_complete_ting.wav', finish(ting, 0.07, 0.6))

# All done: a rising C-major bell arpeggio, the last note ringing longer, with a sprinkle
# of tiny high "glitter" notes.
CHIME = 1.25
soft_bell = [(1.0, 1.0, 0.32), (1.0035, 0.3, 0.34), (2.0, 0.14, 0.12), (3.0, 0.05, 0.06), (0.5, 0.1, 0.2)]
chime = np.zeros(int(CHIME * RATE))
for i, (freq, amp) in enumerate([(1046.5, 0.7), (1318.5, 0.75), (1568.0, 0.8), (2093.0, 1.0)]):
    partials = [(r, a * amp, d * (1.5 if i == 3 else 1.0)) for r, a, d in soft_bell]
    chime += bell(freq, 0.09 * i, CHIME - 0.09 * i, CHIME, partials)
rng = np.random.default_rng(7)
for k in range(7):
    start = 0.30 + k * 0.085 + rng.uniform(-0.02, 0.02)
    freq = [3136.0, 3520.0, 4186.0, 4698.6][k % 4]
    chime += bell(freq, start, 0.2, CHIME, [(1.0, 0.09 * (1 - k / 9), 0.045)], attack=0.002)
save('all_done_chime.wav', finish(chime, 0.35, 0.6))
