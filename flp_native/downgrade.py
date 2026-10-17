"""Rule set: FL 26.x -> FL 24.x, derived by diffing a project against the
output of a known-good downgrader. Anything not understood raises instead of guessing."""
import struct
from flp_events import Flp, FlpError
from versions import VERSIONS, version_string

DROP = {48, 49, 50, 51, 52, 103, 169, 170, 171, 172, 192, 251, 252, 253}
EQ2 = "Fruity Parametric EQ 2"

# FL26 playlist item = 88 B; FL24 = 60 B. The extra 28 B are per-clip properties; in the
# sample every item carried this default (f64 1.0, u32 -1, zeros). Anything else = unknown
# clip data -> refuse, same as the reference downgrader does.
PL26, PL24 = 88, 60
PL_DEFAULT_TAIL = bytes.fromhex("00 00 00 00 00 00 00 00 00 00 f0 3f 00 00 00 00 ff ff ff ff 00 00 00 00 00 00 00 00")

def downgrade_playlist(p: bytes) -> bytes:
    if len(p) % PL26:
        raise FlpError(f"неизвестная структура плейлиста (длина {len(p)} не кратна {PL26})")
    out = bytearray()
    for i in range(0, len(p), PL26):
        rec = p[i:i + PL26]
        if rec[PL24:] != PL_DEFAULT_TAIL:
            raise FlpError("плейлист FL 26 содержит неизученные дополнительные данные клипа")
        out += rec[:PL24]
    return bytes(out)

def _txt(p):
    return p.decode("utf-16le", "replace").rstrip("\0")

def remove_eq2_slots(events):
    out, i, n = [], 0, 0
    while i < len(events):
        e, p = events[i]
        if e == 201 and _txt(p) == EQ2:
            j = i
            while j < len(events) and events[j][0] != 213:
                j += 1
            if j >= len(events):
                raise FlpError("не найден блок состояния Parametric EQ 2")
            i, n = j + 1, n + 1
            continue
        out.append(events[i]); i += 1
    return out, n

def downgrade(flp: Flp, target: str, build: int | None = None, remove_eq2=True):
    build = build or VERSIONS[target][0]
    report = {"removed_eq2": 0, "unresolved": []}
    ev = [list(x) for x in flp.events]
    if remove_eq2:
        ev, report["removed_eq2"] = remove_eq2_slots(ev)
    out = []
    for e, p in ev:
        if e in DROP:
            continue
        if e == 199:
            p = (version_string(target, build) + "\0").encode()
        elif e == 159:
            p = struct.pack("<I", build)
        elif e == 104:                      # FL26 word -> FL24 byte (event 22)
            if p[1] != 0:
                raise FlpError("event 104 не помещается в байт")
            e, p = 22, p[:1]
        elif e == 238 and len(p) == 70:     # mixer slot params: drop trailing 4B
            if p[66:] != b"\0\0\0\0":
                raise FlpError("event 238: хвост не нулевой")
            p = p[:66]
        elif e == 213 and p[:4] == b"\x0c\0\0\0":   # Fruity Wrapper state version 12 -> 10
            p = b"\x0a\0\0\0" + p[4:]
        elif e == 227 and len(p) == 20 and p[11] == 0x70:
            p = p[:11] + b"\x20" + p[12:]
        elif e == 233:
            p = downgrade_playlist(p)
        out.append([e, p])
    return Flp(flp.header, out), report