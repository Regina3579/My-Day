"""Synthesises My Day's five UI sounds and the nine to-do reminder sounds to choose from in
Settings (mono, 44.1 kHz, 16-bit WAV).

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

# To-do reminders, "Gentle Bloom": a little music box. Four soft notes rising up an F-major
# chord (C6, F6, A6, C7: "sol-do-mi-sol"), each a delicate bell (a music-box tine: a pure tone
# with a bright, quickly fading strike and a twin 1.6 Hz sharp for a slow shimmer) over a warm, piano-like
# tone an octave below (soft harmonics that fade more slowly). The notes grow a little louder
# as they rise and the last one rings longest; then a tiny sparkle (F7, A7, C8, F8) with a faint
# shimmer, in a small soft room, fading out at 3 s. A gentle "you have something lovely to do".
# Played by iOS for the notification (Linear PCM WAV, under Apple's 30-second limit).


def piano(freq, start, total, amp, decay, attack=0.006):
    """A warm, piano-like note: harmonics 1-4, the higher ones softer and gone sooner, with a
    6 ms hammer and a slow fade."""
    t = np.arange(int((total - start) * RATE)) / RATE
    note = np.zeros_like(t)
    for h, (a, d) in enumerate([(1.0, 1.0), (0.42, 0.55), (0.16, 0.32), (0.06, 0.2)], start=1):
        note += a * np.sin(2 * np.pi * freq * h * t) * np.exp(-t / (decay * d))
    a = int(attack * RATE)
    note[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    out = np.zeros(int(total * RATE))
    i = int(start * RATE)
    out[i:i + len(note)] += amp * note
    return out


BLOOM = 3.0
gentle_bloom = np.zeros(int(BLOOM * RATE))
for i, (freq, start, loud) in enumerate([(1046.5, 0.00, 0.78), (1396.9, 0.30, 0.84),
                                         (1760.0, 0.60, 0.92), (2093.0, 0.90, 1.00)]):
    ring = 1.7 if i == 3 else 1.0
    # The twin is 1.6 Hz sharp on every note, so each shimmers at the same slow, even pace.
    music_box = [(1.0, 1.0, 0.75), (1 + 1.6 / freq, 0.20, 0.85), (2.0, 0.10, 0.22),
                 (2.76, 0.10, 0.10), (5.40, 0.035, 0.04)]
    partials = [(r, a * loud, d * ring) for r, a, d in music_box]
    gentle_bloom += bell(freq, start, BLOOM - start, BLOOM, partials, attack=0.006)
    gentle_bloom += piano(freq / 2, start, BLOOM, 0.42 * loud, 0.9 * ring)
for k, freq in enumerate([2793.8, 3520.0, 4186.0, 5587.7]):
    gentle_bloom += sparkle(freq, 1.38 + 0.06 * k, BLOOM, 0.16 - 0.025 * k, 0.12 + 0.03 * k, twin=0.3)
t = np.arange(int((BLOOM - 1.36) * RATE)) / RATE
shimmer = sum(np.sin(2 * np.pi * f * t) for f in (2793.8 * 0.9985, 2793.8 * 1.0015, 3520.0))
shimmer *= 0.03 * (1 - np.exp(-t / 0.08)) * np.exp(-t / 0.4)
gentle_bloom[int(1.36 * RATE):] += shimmer
# Seed 38: this room's echo warms every note and the sparkle alike (within 1.2 dB), where most
# rooms would happen to cancel one note's pitch.
gentle_bloom = finish(room(gentle_bloom, 0.24, seed=38), 0.7, 0.65)
save('gentle_bloom.wav', gentle_bloom)


# Settings → Sounds & Haptics → Reminder Sound: eight more sounds a to-do's reminder can arrive
# with. Each is as loud to the ear as Gentle Bloom (its loudest 0.4 s, A-weighted, the way the
# ear hears high and low notes), the soft ones 2 dB quieter, never peaking above 0.85. Like
# Gentle Bloom's, each room's seed is the one (of 200) whose echo changes the tune's notes most
# evenly (within 0.2 to 3 dB of each other), so none of them is dulled.


def loudness(signal, window=0.4):
    """How loud the ear finds the loudest `window` seconds: the A-weighted RMS."""
    n = len(signal)
    f2 = np.fft.rfftfreq(n, 1 / RATE) ** 2
    a = 12194 ** 2 * f2 ** 2 / ((f2 + 20.6 ** 2) * np.sqrt((f2 + 107.7 ** 2) * (f2 + 737.9 ** 2))
                                * (f2 + 12194 ** 2))
    weighted = np.fft.irfft(np.fft.rfft(signal) * a / 0.7943, n)
    w = int(window * RATE)
    return np.sqrt(np.max(np.convolve(weighted ** 2, np.ones(w) / w, mode='valid')))


REFERENCE = loudness(gentle_bloom)


def level(signal, fade, db=0.0):
    """Fades the end out, then matches Gentle Bloom's loudness (`db` louder), peaking at most 0.85."""
    f = int(fade * RATE)
    signal[-f:] *= np.cos(np.linspace(0, np.pi / 2, f)) ** 2
    signal *= REFERENCE * 10 ** (db / 20) / loudness(signal)
    return signal * min(1.0, 0.85 / np.max(np.abs(signal)))


def harp(freq, start, total, amp, decay=1.6):
    """A soft harp string plucked near a quarter of its length: harmonics 1-10, softer and gone
    sooner as they rise, with a 3 ms pluck."""
    t = np.arange(int((total - start) * RATE)) / RATE
    note = np.zeros_like(t)
    for h in range(1, 11):
        if freq * h >= RATE / 2 * 0.9:
            break
        strength = abs(np.sin(h * np.pi * 0.27)) / h ** 1.7
        note += strength * np.sin(2 * np.pi * freq * h * t) * np.exp(-t / (decay / (1 + 0.45 * (h - 1))))
    a = int(0.003 * RATE)
    note[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    out = np.zeros(int(total * RATE))
    i = int(start * RATE)
    out[i:i + len(note)] += amp * note
    return out


def smooth(values, seconds):
    """Rounds off sudden steps over about `seconds` (a Hann window), keeping the ends level."""
    w = np.hanning(max(3, int(seconds * RATE)))
    w /= w.sum()
    pad = len(w)
    padded = np.concatenate([np.full(pad, values[0]), values, np.full(pad, values[-1])])
    return np.convolve(padded, w, mode='same')[pad:-pad]


def flute(tune, total, breath=0.05, seed=11):
    """A soft flute playing `tune` legato: (freq, start, loudness) notes, each held until the next
    starts and the last to the end. A near-pure tone (weak 2nd to 5th harmonics) that glides into
    each note in about 30 ms with a light tongued dip, a gentle 5.2 Hz vibrato easing in once a
    note has settled, a slow 90 ms swell into the first note, and soft breath noise (brightest
    around 3.5 kHz) that follows the tone, with a little puff on each tongued note."""
    n = int(total * RATE)
    t = np.arange(n) / RATE
    freq, amp, since = np.zeros(n), np.zeros(n), np.zeros(n)
    for f0, start, loud in tune:
        i = int(start * RATE)
        freq[i:], amp[i:], since[i:] = f0, loud, t[i:] - start
    freq, amp = smooth(freq, 0.03), smooth(amp, 0.02)
    for _, start, _ in tune[1:]:
        amp *= 1 - 0.4 * np.exp(-((t - start) / 0.025) ** 2)
    ease = np.clip((since - 0.18) / 0.35, 0, 1)
    wobble = np.sin(2 * np.pi * 5.2 * t) * ease
    freq = freq * (1 + 0.004 * wobble)
    amp = amp * (1 + 0.04 * wobble)
    a = int(0.09 * RATE)
    amp[:a] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, a))
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    tone = np.zeros(n)
    for h, strength in enumerate([1.0, 0.30, 0.11, 0.045, 0.018], start=1):
        tone += strength * np.sin(h * phase) * (freq * h < RATE / 2 * 0.9)
    rng = np.random.default_rng(seed)
    noise = np.fft.rfft(rng.standard_normal(n))
    hz = np.fft.rfftfreq(n, 1 / RATE)
    noise = np.fft.irfft(noise * np.exp(-np.log(np.maximum(hz, 1) / 3500) ** 2 / 0.5), n)
    noise /= np.max(np.abs(noise))
    puff = 1 + 2.5 * np.exp(-since / 0.02) * (since < 0.2) * (t > tune[0][1] + 0.05)
    return amp * (tone + breath * noise * puff)


def pad(freqs, start, total, amp, rise=0.6, decay=2.5):
    """A soft, warm background chord: each note a pair of sines 0.15% apart (a slow, gentle
    shimmer), swelling in over `rise` seconds and fading slowly."""
    t = np.arange(int((total - start) * RATE)) / RATE
    chord = sum(np.sin(2 * np.pi * f * 0.99925 * t) + np.sin(2 * np.pi * f * 1.00075 * t) for f in freqs)
    chord *= amp * (1 - np.exp(-t / (rise / 3))) * np.exp(-t / decay)
    out = np.zeros(int(total * RATE))
    out[int(start * RATE):][:len(chord)] += chord
    return out


# "Sparkling Sunrise", bright musical bells (4 s): a happy D-major tune climbing like the sun
# coming up (D6 F#6 A6 D7, then B6 D7 and a long, ringing F#7), on bright hand bells (a strong
# octave and twelfth in each strike, a twin 1.8 Hz sharp for shimmer) over a warm, piano-like
# tone an octave below, then a sprinkle of glittering high bells (D major's pentatonic notes,
# A7 to F#8) and a soft shimmer, in a small room.
SUNRISE = 4.0
SUNRISE_TUNE = [(1174.7, 0.00, 0.80), (1480.0, 0.17, 0.84), (1760.0, 0.34, 0.88), (2349.3, 0.51, 0.95),
                (1975.5, 0.85, 0.85), (2349.3, 1.02, 0.92), (2960.0, 1.19, 1.00)]
GLITTER = [3520.0, 3951.1, 4698.6, 5274.0, 5919.9]
sunrise = np.zeros(int(SUNRISE * RATE))
for i, (freq, start, loud) in enumerate(SUNRISE_TUNE):
    ring = 2.0 if i == len(SUNRISE_TUNE) - 1 else 1.0
    hand_bell = [(1.0, 1.0, 0.70), (1 + 1.8 / freq, 0.22, 0.80), (2.0, 0.32, 0.30), (3.0, 0.16, 0.16),
                 (4.2, 0.07, 0.08), (5.4, 0.03, 0.04)]
    sunrise += bell(freq, start, SUNRISE - start, SUNRISE, [(r, a * loud, d * ring) for r, a, d in hand_bell])
    sunrise += piano(freq / 2, start, SUNRISE, 0.25 * loud, 0.8 * ring)
rng = np.random.default_rng(21)
for k in range(8):
    start = 1.50 + k * 0.10 + rng.uniform(-0.025, 0.025)
    sunrise += bell(GLITTER[rng.integers(len(GLITTER))], start, 0.4, SUNRISE,
                    [(1.0, 0.13 * (1 - k / 11), 0.07), (2.0, 0.02, 0.03)], attack=0.002)
t = np.arange(int((SUNRISE - 1.25) * RATE)) / RATE
glow = sum(np.sin(2 * np.pi * f * t) for f in (2349.3 * 0.9985, 2349.3 * 1.0015, 2960.0, 3520.0))
sunrise[int(1.25 * RATE):] += 0.03 * glow * (1 - np.exp(-t / 0.1)) * np.exp(-t / 0.9)
save('sparkling_sunrise.wav', level(room(sunrise, 0.26, seed=133), 0.9))

# "Sparkling Sunrise – Soft Version", gentle musical bells (4 s): the same tune an octave lower
# and a little slower (D5 to F#6), on soft bells (a slow 12 ms strike, hardly any overtones)
# blended with a warm piano-like tone, then four quiet sparkles (D7 F#7 A7 D8) and a little more
# room: the sunrise, but sleepy. 2 dB softer.
soft_sunrise = np.zeros(int(SUNRISE * RATE))
for i, (freq, start, loud) in enumerate(SUNRISE_TUNE):
    ring = 1.8 if i == len(SUNRISE_TUNE) - 1 else 1.0
    freq, start = freq / 2, start * 1.15
    soft_bell = [(1.0, 1.0, 0.90), (1 + 1.2 / freq, 0.25, 1.0), (2.0, 0.12, 0.35), (3.0, 0.03, 0.15)]
    soft_sunrise += bell(freq, start, SUNRISE - start, SUNRISE, [(r, a * loud, d * ring) for r, a, d in soft_bell],
                         attack=0.012)
    soft_sunrise += piano(freq, start, SUNRISE, 0.30 * loud, 0.9 * ring, attack=0.012)
for k, freq in enumerate([2349.3, 2960.0, 3520.0, 4698.6]):
    soft_sunrise += sparkle(freq, 1.75 + 0.11 * k, SUNRISE, 0.10 - 0.015 * k, 0.16 + 0.03 * k, twin=0.3)
save('sparkling_sunrise_soft.wav', level(room(soft_sunrise, 0.32, seed=35), 0.9, -2))

# "My Day – Gentle Flute", a soft, peaceful flute melody (4.4 s): G5 A5 C6, then A5 G5 and a
# long, settling C6, slow and legato, over a soft, warm C-major chord (C5 E5 G5) that swells in
# underneath, in a small room. 2 dB softer.
GENTLE_FLUTE = 4.4
gentle_flute = flute([(784.0, 0.00, 0.85), (880.0, 0.50, 0.90), (1046.5, 0.95, 1.00), (880.0, 1.85, 0.90),
                      (784.0, 2.25, 0.85), (1046.5, 2.65, 0.95)], GENTLE_FLUTE)
gentle_flute += pad([523.25, 659.26, 783.99], 0.0, GENTLE_FLUTE, 0.035, rise=0.8, decay=3.0)
save('gentle_flute.wav', level(room(gentle_flute, 0.30, seed=111), 1.0, -2))

# "My Day – Soft Melodic Flute", a peaceful flute melody (4.5 s): a little F-major tune, C6 D6 F6,
# up to A6, then G6 F6 D6 and a long F6, over soft harp chords rolled under it (F, then B-flat
# as the tune comes down, then F again for the last note), in a small room.
MELODIC_FLUTE = 4.5
melodic_flute = flute([(1046.5, 0.00, 0.85), (1174.7, 0.32, 0.88), (1396.9, 0.64, 0.95), (1760.0, 1.16, 1.00),
                       (1568.0, 1.58, 0.90), (1396.9, 1.90, 0.88), (1174.7, 2.22, 0.85), (1396.9, 2.62, 0.95)],
                      MELODIC_FLUTE, seed=12)
for start, chord in [(0.00, [698.46, 880.0, 1046.5]), (1.58, [466.16, 587.33, 698.46]),
                     (2.62, [698.46, 880.0, 1046.5, 1396.9])]:
    for k, freq in enumerate(chord):
        melodic_flute += harp(freq, start + 0.06 * k, MELODIC_FLUTE, 0.22)
save('soft_melodic_flute.wav', level(room(melodic_flute, 0.28, seed=128), 1.0))

# "Soft Ting" (1.5 s): one gentle crystal ting, A6 with a slow 10 ms strike, a twin 1.4 Hz sharp
# for a slow shimmer and a warm octave below, ringing out softly in a small room. 2 dB softer.
SOFT_TING = 1.5
soft_ting = bell(1760.0, 0.0, SOFT_TING, SOFT_TING,
                 [(1.0, 1.0, 0.42), (1 + 1.4 / 1760.0, 0.35, 0.48), (0.5, 0.16, 0.22), (2.0, 0.07, 0.10),
                  (2.76, 0.035, 0.05)], attack=0.010)
save('soft_ting.wav', level(room(soft_ting, 0.22, seed=141), 0.5, -2))

# "Morning Harp" (3.5 s): a soft harp rolling up a C-major chord (C5 E5 G5 C6 E6 G6 C7, 70 ms
# apart, the top note ringing longest), then answering itself with two quiet notes coming down
# (E6, C6): a gentle "good morning", in a small room.
HARP = 3.5
morning_harp = np.zeros(int(HARP * RATE))
for k, freq in enumerate([523.25, 659.26, 783.99, 1046.5, 1318.5, 1568.0, 2093.0]):
    morning_harp += harp(freq, 0.07 * k, HARP, 0.8 + 0.03 * k, decay=2.2 if k == 6 else 1.6)
for start, freq in [(1.15, 1318.5), (1.42, 1046.5)]:
    morning_harp += harp(freq, start, HARP, 0.55, decay=1.8)
save('morning_harp.wav', level(room(morning_harp, 0.26, seed=90), 0.8))

# "Wind Chimes" (4 s): five little tuned chimes (C6 D6 E6 G6 A6, a pentatonic scale, so any two
# sound sweet together) touched by a soft breeze: eleven strikes, quick at first, then further
# apart and gentler, each ringing with a chime tube's overtones (2.76 and 5.4 times its note)
# and a slow shimmer, in a small room.
CHIMES = 4.0
CHIME_NOTES = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0]
wind_chimes = np.zeros(int(CHIMES * RATE))
rng = np.random.default_rng(6)
start, last = 0.0, -1
for k in range(11):
    note = rng.choice([i for i in range(len(CHIME_NOTES)) if i != last])
    freq, last = CHIME_NOTES[note], note
    tube = [(1.0, 1.0, 1.1), (1 + 1.1 / freq, 0.30, 1.2), (2.76, 0.30, 0.45), (5.40, 0.10, 0.18),
            (8.93, 0.03, 0.08)]
    loud = (1 - k / 16) * rng.uniform(0.8, 1.0)
    wind_chimes += bell(freq, start, CHIMES - start, CHIMES, [(r, a * loud, d) for r, a, d in tube], attack=0.004)
    start += 0.12 + 0.03 * k + rng.uniform(-0.03, 0.03)
save('wind_chimes.wav', level(room(wind_chimes, 0.24, seed=130), 0.9))

# "Happy Marimba" (2.5 s): a cheerful little wooden tune, C6 E6 G6, a quick G6 again, then a high
# C7 ("do-mi-sol, sol-do!"), on marimba bars (a warm tone with the bar's overtones at 3.93 and
# 9.2 times the note, gone fast) struck with a soft 4 ms mallet, the last bar ringing longer, in
# a small room.
MARIMBA = 2.5
happy_marimba = np.zeros(int(MARIMBA * RATE))
for i, (freq, start, loud) in enumerate([(1046.5, 0.00, 0.85), (1318.5, 0.14, 0.88), (1568.0, 0.28, 0.92),
                                         (1568.0, 0.50, 0.80), (2093.0, 0.64, 1.00)]):
    ring = 1.8 if i == 4 else 1.0
    bar = [(1.0, 1.0, 0.45 * ring), (3.93, 0.28, 0.07), (9.2, 0.07, 0.025)]
    happy_marimba += bell(freq, start, MARIMBA - start, MARIMBA, [(r, a * loud, d) for r, a, d in bar],
                          attack=0.004)
save('happy_marimba.wav', level(room(happy_marimba, 0.22, seed=152), 0.7))
