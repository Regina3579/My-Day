"""Synthesises My Day's five UI sounds (mono, 44.1 kHz, 16-bit WAV).

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


def sparkle(freq, start, total, amp, decay, glide=0.01, vibrato=0.0, twin=0.0):
    """One tiny sparkle: a near-pure sine that starts `glide` flat and rises onto its note in
    about 20 ms (the "twinkle"), with a faint octave. `vibrato` adds a slow 5.5 Hz wobble and `twin` a
    detuned copy, both for a dreamier sparkle."""
    t = np.arange(int(min(decay * 7, total - start) * RATE)) / RATE
    f = freq * (1 - glide * np.exp(-t / 0.02)) * (1 + vibrato * np.sin(2 * np.pi * 5.5 * t))
    phase = 2 * np.pi * np.cumsum(f) / RATE
    note = amp * (np.sin(phase) + 0.12 * np.sin(2 * phase) * np.exp(-t / (decay / 3)))
    if twin:
        note += twin * amp * np.sin(phase * 1.003)
    note *= np.exp(-t / decay)
    a = int(0.003 * RATE)
    note[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    out = np.zeros(int(total * RATE))
    i = int(start * RATE)
    out[i:i + len(note)] += note
    return out


def bubble(start, total, f0, f1, amp, sweep=0.015, decay=0.022):
    """A soft, rounded bubble "pop": a sine whose pitch rises quickly from f0 to f1, as a
    popping bubble's does, and dies away fast, with a gentle 3 ms start and no noise."""
    t = np.arange(int(decay * 8 * RATE)) / RATE
    f = f1 - (f1 - f0) * np.exp(-t / sweep)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    note = amp * (np.sin(phase) + 0.08 * np.sin(2 * phase)) * np.exp(-t / decay)
    a = int(0.003 * RATE)
    note[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    out = np.zeros(int(total * RATE))
    i = int(start * RATE)
    out[i:i + len(note)] += note
    return out


def room(signal, wet, seed=3):
    """A small, soft room: the dry sound plus its echo off a synthetic impulse response
    (decaying noise, darkened above 4.5 kHz, after a 12 ms gap so the strike stays clear)."""
    rng = np.random.default_rng(seed)
    n = int(0.45 * RATE)
    t = np.arange(n) / RATE
    ir = rng.standard_normal(n) * np.exp(-t / 0.11)
    spec = np.fft.rfft(ir)
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    ir = np.fft.irfft(spec / np.sqrt(1 + (freqs / 4500) ** 4), n)
    ir[:int(0.012 * RATE)] = 0
    ir /= np.sqrt(np.sum(ir ** 2))
    size = len(signal) + n
    tail = np.fft.irfft(np.fft.rfft(signal, size) * np.fft.rfft(ir, size), size)[:len(signal)]
    return signal + wet * tail


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

# First-time tips, "Ting… twinkle!": My Day's discovery sound, the same for every tip.
# A soft, warm crystal "ting" (G6, a fourth below the task ting, with a slow 8 ms strike,
# a detuned twin for shimmer and a quiet octave below for warmth), then three delicate
# rising sparkles up a C-major chord (C7, E7, G7: "ti-li-ling"), in a small soft room,
# fading out gently. 0.7 s.
TIP = 0.70
tip_glass = [(1.0, 1.0, 0.20), (1.0028, 0.35, 0.22), (0.5, 0.12, 0.10),
             (2.0, 0.10, 0.07), (2.76, 0.05, 0.04), (5.40, 0.012, 0.015)]


def tip_ting(total):
    return bell(1568.0, 0.0, total, total, tip_glass, attack=0.008)


tip = tip_ting(TIP)
for start, freq, amp, decay in [(0.150, 2093.0, 0.30, 0.070), (0.215, 2637.0, 0.28, 0.075),
                                (0.280, 3136.0, 0.26, 0.110)]:
    tip += sparkle(freq, start, TIP, amp, decay)
save('tip_discovery.wav', finish(room(tip, 0.18), 0.22, 0.6))

# The quote tip's version ends dreamier, "ting ✨ ting-ling ✨": the same ting, then two
# softer, longer sparkles (E7, then A7 with a slow wobble and a detuned twin), a faint
# shimmer blooming under them, and a little more room. 0.75 s.
QUOTE_TIP = 0.75
quote_tip = tip_ting(QUOTE_TIP)
quote_tip += sparkle(2637.0, 0.170, QUOTE_TIP, 0.30, 0.100, twin=0.3)
quote_tip += sparkle(3520.0, 0.255, QUOTE_TIP, 0.25, 0.160, vibrato=0.003, twin=0.4)
t = np.arange(int((QUOTE_TIP - 0.22) * RATE)) / RATE
bloom = sum(np.sin(2 * np.pi * f * t) for f in (2093.0 * 0.9985, 2093.0 * 1.0015, 2637.0))
bloom *= 0.035 * (1 - np.exp(-t / 0.08)) * np.exp(-t / 0.25)
quote_tip[int(0.22 * RATE):] += bloom
save('tip_discovery_dreamy.wav', finish(room(quote_tip, 0.26, seed=5), 0.25, 0.6))

# Picking a mood star, "pop… ting ✨": the star coming alive. A tiny, soft bubble pop
# (rising 520 Hz → E6), then 55 ms later one delicate, warm crystal ting an octave above
# where the pop ends (E7, 5 ms strike, a detuned twin and a warm octave below), in a
# small room, fading out quickly. 0.4 s.
MOOD = 0.40
mood = bubble(0.0, MOOD, 520.0, 1318.5, 0.8)
mood += bell(2637.0, 0.055, MOOD - 0.055, MOOD,
             [(1.0, 1.0, 0.09), (1.0032, 0.3, 0.10), (0.5, 0.18, 0.06), (2.0, 0.05, 0.03),
              (2.76, 0.03, 0.02)], attack=0.005)
save('mood_pop_ting.wav', finish(room(mood, 0.12, seed=9), 0.14, 0.6))
