#!/usr/bin/env python3
"""Live template editor sweep (see flutter_app/lib/admin/README.md).

Wraps fixed pictures, clips, SVGs and copy in flutter_app/lib with the
editable wrappers so the owner can replace them from admin edit mode:

  Image.asset(...)      -> EditableImage.asset(..., slot: '<file>.<Class>')
  Image.network(<const>)-> EditableImage.network(..., slot: ...)   (literal or k… constant only)
  SvgPicture.asset(...) -> EditableSvg.asset(..., slot: ...)
  NwsbVideo(...) / NwsbImage(...)      + slot: ... (last argument)
  Text('literal', ...)  -> EditableLabel('<slot>', 'literal', ...)
  Text(label, ...)      -> EditableLabel('<slot>', label, ...)  for label-like names

Default rendering is unchanged: each wrapper builds the same widget with the
same arguments unless an override exists. Also writes
lib/admin/template/slot_manifest.g.dart (every slot whose default is known
statically) and prints a per-file report.

Idempotent: calls that already carry `slot:` / EditableLabel are left alone.
Usage: python3 tools/admin-slot-sweep.py [--dry-run] [--report path]
The slug/hash here MUST match lib/admin/template/slot_keys.dart.
"""
import os, re, sys, json

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'flutter_app', 'lib')
ROOT = os.path.normpath(ROOT)
EXCLUDE_DIRS = {'admin', 'media', 'data', 'theme', 'profile_source'}
EXCLUDE_FILES = set()
LABEL_IDENTS = {'label', 'title', 'sub', 'subtitle', 'heading', 'caption', 'text', 'cta', 'kicker',
                'eyebrow', 'body', 'detail', 'headline', 'badge', 'hint', 'description'}
TEXT_UNSUPPORTED = ('textScaleFactor:', 'semanticsIdentifier:')
# Pictures drawn as decorations were wrapped by hand with slotImageProvider();
# list their static defaults here so All slots shows them.
EXTRA_MANIFEST = [
    ['profile.Background', 'assets/profile_source/img-bg.jpeg', 'screens/profile.dart'],
] + [['flip_brand_showcase.FlipBrandShowcase', f'assets/flip_brand/img{i}.jpg', 'widgets/flip_brand_showcase.dart'] for i in range(1, 9)]

# ── slot_keys.dart, ported ──────────────────────────────────────────────
def slot_hash(s):
    h = 0x811c9dc5
    for b in s.encode('utf-8'):
        h ^= b
        h = (h * 0x01000193) & 0xffffffff
    return '%08x' % h

def slot_slug(text):
    out = []
    dash = False
    for ch in text:
        c = ord(ch)
        if 65 <= c <= 90:
            c += 32
        if 97 <= c <= 122 or 48 <= c <= 57:
            out.append(chr(c)); dash = False
        elif not dash and out:
            out.append('-'); dash = True
    s = ''.join(out).rstrip('-')
    if len(s) > 40:
        s = s[:40].rstrip('-') + '-' + slot_hash(text)
    if not s:
        s = 't' + slot_hash(text)
    return s

def slot_media_id(p):
    q = p.find('?')
    if q >= 0: p = p[:q]
    sl = p.rfind('/')
    if sl >= 0: p = p[sl + 1:]
    dot = p.rfind('.')
    if dot > 0: p = p[:dot]
    return slot_slug(p)

# ── a small Dart scanner: skips strings and comments ───────────────────
def skip_string(src, i):
    """src[i] is at the start of a string literal (optionally r-prefixed). Returns index after it."""
    raw = False
    if src[i] == 'r':
        raw = True; i += 1
    q = src[i]
    triple = src.startswith(q * 3, i)
    delim = q * 3 if triple else q
    i += len(delim)
    n = len(src)
    while i < n:
        if not raw and src[i] == '\\':
            i += 2; continue
        if src.startswith(delim, i):
            return i + len(delim)
        if not raw and src[i] == '$' and i + 1 < n and src[i + 1] == '{':
            i = match_close(src, i + 1) + 1; continue
        if not triple and src[i] == '\n':
            return i  # broken literal; bail
        i += 1
    return n

def is_string_start(src, i):
    c = src[i]
    if c in '\'"':
        return True
    if c == 'r' and i + 1 < len(src) and src[i + 1] in '\'"' and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == '_')):
        return True
    return False

def match_close(src, i):
    """src[i] is ( [ or {. Returns index of the matching closer."""
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack = [pairs[src[i]]]
    i += 1
    n = len(src)
    while i < n:
        c = src[i]
        if src.startswith('//', i):
            j = src.find('\n', i); i = n if j < 0 else j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2); i = n if j < 0 else j + 2; continue
        if is_string_start(src, i):
            i = skip_string(src, i); continue
        if c in pairs:
            stack.append(pairs[c])
        elif c in ')]}':
            if not stack or stack[-1] != c:
                return -1
            stack.pop()
            if not stack:
                return i
        i += 1
    return -1

def code_mask(src):
    """True for characters that are code (not in a string or comment)."""
    mask = bytearray(b'\x01') * len(src)
    i, n = 0, len(src)
    while i < n:
        if src.startswith('//', i):
            j = src.find('\n', i); j = n if j < 0 else j
            mask[i:j] = b'\x00' * (j - i); i = j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2); j = n if j < 0 else j + 2
            mask[i:j] = b'\x00' * (j - i); i = j; continue
        if is_string_start(src, i):
            j = skip_string(src, i)
            mask[i:j] = b'\x00' * (j - i); i = j; continue
        i += 1
    return mask

def split_top_args(inner):
    """Split call arguments at top-level commas. Returns list of (start, end) spans in inner."""
    spans, depth, start, i, n = [], 0, 0, 0, len(inner)
    while i < n:
        c = inner[i]
        if inner.startswith('//', i):
            j = inner.find('\n', i); i = n if j < 0 else j; continue
        if inner.startswith('/*', i):
            j = inner.find('*/', i + 2); i = n if j < 0 else j + 2; continue
        if is_string_start(inner, i):
            i = skip_string(inner, i); continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        elif c == ',' and depth == 0:
            spans.append((start, i)); start = i + 1
        i += 1
    if inner[start:].strip():
        spans.append((start, n))
    return spans

LIT_RE = re.compile(r"""^(r?)('''|\"\"\"|'|")(.*)\2$""", re.S)

def string_value(expr):
    """Value of a single Dart string literal without interpolation, else None."""
    e = expr.strip()
    m = LIT_RE.match(e)
    if not m:
        return None
    raw, q, body = m.group(1), m.group(2), m.group(3)
    # reject adjacent-literal concatenation like 'a' 'b'
    if len(q) == 1 and not raw:
        k = 0
        while k < len(body):
            if body[k] == '\\': k += 2; continue
            if body[k] == q: return None
            k += 1
    elif len(q) == 1 and q in body:
        return None
    if raw:
        return body
    out, k = [], 0
    while k < len(body):
        c = body[k]
        if c == '$':
            return None  # interpolation
        if c == '\\':
            nx = body[k + 1] if k + 1 < len(body) else ''
            simple = {'n': '\n', 't': '\t', 'r': '\r', 'b': '\b', 'f': '\f', 'v': '\v', '0': '\0'}
            if nx in simple:
                out.append(simple[nx]); k += 2; continue
            if nx == 'u':
                if body[k + 2:k + 3] == '{':
                    j = body.index('}', k)
                    out.append(chr(int(body[k + 3:j], 16))); k = j + 1; continue
                out.append(chr(int(body[k + 2:k + 6], 16))); k += 6; continue
            if nx == 'x':
                out.append(chr(int(body[k + 2:k + 4], 16))); k += 4; continue
            if nx == '\n':
                k += 2; continue
            out.append(nx); k += 2; continue
        out.append(c); k += 1
    return ''.join(out)

# ── constants (const kX = '...';) so k… defaults resolve for the manifest
CONST_RE = re.compile(r"""^\s*(?:static\s+)?const\s+(?:String\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*('[^'\n$]*'|"[^"\n$]*")\s*;""", re.M)

def collect_consts(files):
    out = {}
    for f in files:
        for m in CONST_RE.finditer(open(f, encoding='utf-8').read()):
            out.setdefault(m.group(1), set()).add(m.group(2)[1:-1])
    return {k: next(iter(v)) for k, v in out.items() if len(v) == 1}

# ── classes: innermost class/mixin/extension body containing a position ──
CLASS_RE = re.compile(r'\b(?:abstract\s+|base\s+|final\s+|sealed\s+|interface\s+)*(?:class|mixin|extension)\s+([A-Za-z_][A-Za-z0-9_]*)[^{;]*\{')

def class_spans(src, mask):
    spans = []
    for m in CLASS_RE.finditer(src):
        if not mask[m.start()]:
            continue
        open_i = m.end() - 1
        close = match_close(src, open_i)
        if close > 0:
            spans.append((open_i, close, m.group(1)))
    return spans

FUNC_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_<>, ?]*\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*\([^;{]*\)\s*(?:async\s*)?\{', re.M)

def owner_name(spans, pos):
    best = None
    for a, b, name in spans:
        if a < pos < b and (best is None or a > best[0]):
            best = (a, b, name)
    if best is None:
        return 'shared'
    n = best[2].lstrip('_')
    if n.endswith('State') and len(n) > 5:
        n = n[:-5]
    return n or 'shared'

# ── the sweep ──────────────────────────────────────────────────────────
PATTERNS = [
    ('image_asset', re.compile(r'(?<![A-Za-z0-9_.])Image\.asset\(')),
    ('image_network', re.compile(r'(?<![A-Za-z0-9_.])Image\.network\(')),
    ('svg_asset', re.compile(r'(?<![A-Za-z0-9_.])SvgPicture\.asset\(')),
    ('nwsb_video', re.compile(r'(?<![A-Za-z0-9_.])NwsbVideo\(')),
    ('nwsb_image', re.compile(r'(?<![A-Za-z0-9_.])NwsbImage\(')),
    ('text', re.compile(r'(?<![A-Za-z0-9_.])Text\(')),
]
# Already converted — read for the manifest only (keeps re-runs complete).
DONE_PATTERNS = [
    ('image', 'first', re.compile(r'(?<![A-Za-z0-9_.])EditableImage\.(?:asset|network)\(')),
    ('image', 'first', re.compile(r'(?<![A-Za-z0-9_.])EditableSvg\.asset\(')),
    ('video', 'asset', re.compile(r'(?<![A-Za-z0-9_.])NwsbVideo\(')),
    ('image', 'url', re.compile(r'(?<![A-Za-z0-9_.])NwsbImage\(')),
    ('text', 'label', re.compile(r'(?<![A-Za-z0-9_.])EditableLabel\(')),
]

def has_named(inner, spans, name):
    for a, b in spans:
        if re.match(r'\s*' + name + r'\s*:', inner[a:b]):
            return True
    return False

def named_value(inner, spans, name):
    for a, b in spans:
        m = re.match(r'\s*' + name + r'\s*:(.*)$', inner[a:b], re.S)
        if m:
            return m.group(1).strip()
    return None

def append_insert(src, open_i, close_i, arg):
    """(position, text) that appends `arg` as the last argument of the call
    whose parentheses are at open_i / close_i. Insert-only, so edits inside
    nested calls never collide with it."""
    inner = src[open_i + 1:close_i]
    stripped = inner.rstrip()
    pos = open_i + 1 + len(stripped)
    if not stripped.strip():
        return (open_i + 1, arg)
    if stripped.endswith(','):
        last_nl = stripped.rfind('\n')
        if last_nl >= 0:
            line = stripped[last_nl + 1:]
            indent = line[:len(line) - len(line.lstrip())]
            return (pos, '\n' + indent + arg + ',')
        return (pos, ' ' + arg + ',')
    return (pos, ', ' + arg)

def const_ok(expr, consts):
    e = expr.strip()
    if string_value(e) is not None:
        return string_value(e)
    if re.fullmatch(r'_?k[A-Z][A-Za-z0-9_]*', e):
        return consts.get(e.lstrip('_')) or consts.get(e) or ''
    return None

def sweep_file(path, stem, consts, report, manifest, dry):
    src = open(path, encoding='utf-8').read()
    orig = src
    counts = {k: 0 for k, _ in PATTERNS}
    skipped = []
    # edits applied back-to-front on the original positions
    mask = code_mask(src)
    spans = class_spans(src, mask)
    edits = []  # (start, end, replacement)
    for kind, rx in PATTERNS:
        for m in rx.finditer(src):
            s = m.start()
            if not mask[s]:
                continue
            open_i = m.end() - 1
            close_i = match_close(src, open_i)
            if close_i < 0:
                skipped.append((kind, src.count('\n', 0, s) + 1, 'unbalanced'))
                continue
            inner = src[open_i + 1:close_i]
            args = split_top_args(inner)
            line = src.count('\n', 0, s) + 1
            slot = f"{stem}.{owner_name(spans, s)}"
            if kind == 'text':
                if not args:
                    continue
                sep = '' if src[open_i + 1:open_i + 2] in ('\n', '\r') else ' '
                first = inner[args[0][0]:args[0][1]]
                if any(u in inner for u in TEXT_UNSUPPORTED):
                    skipped.append((kind, line, 'unsupported Text argument')); continue
                val = string_value(first)
                if val is None:
                    f = first.strip()
                    ident = f[7:] if f.startswith('widget.') else f
                    if ident not in LABEL_IDENTS:
                        if string_value(first.strip()) is None and ("'" in f or '"' in f):
                            skipped.append((kind, line, 'interpolated/concatenated text'))
                        continue
                    edits.append((s, open_i + 1, f"EditableLabel('{slot}',{sep}"))
                    counts[kind] += 1
                    continue
                edits.append((s, open_i + 1, f"EditableLabel('{slot}',{sep}"))
                counts[kind] += 1
                manifest.append([f"{slot}.{slot_slug(val)}", 'text', val, os.path.relpath(path, ROOT)])
                continue
            if has_named(inner, args, 'slot'):
                continue
            if not args:
                continue
            first = inner[args[0][0]:args[0][1]]
            if kind == 'image_network':
                v = const_ok(first, consts)
                if v is None:
                    skipped.append((kind, line, 'data/user image: ' + first.strip()[:40])); continue
                edits.append((s, open_i, 'EditableImage.network'))
            elif kind == 'image_asset':
                v = const_ok(first, consts)
                edits.append((s, open_i, 'EditableImage.asset'))
            elif kind == 'svg_asset':
                v = const_ok(first, consts)
                edits.append((s, open_i, 'EditableSvg.asset'))
            elif kind == 'nwsb_video':
                expr = named_value(inner, args, 'asset')
                v = const_ok(expr, consts) if expr else None
            else:  # nwsb_image
                expr = named_value(inner, args, 'url')
                v = const_ok(expr, consts) if expr else None
            p_, t_ = append_insert(src, open_i, close_i, f"slot: '{slot}'")
            edits.append((p_, p_, t_))
            counts[kind] += 1
            if v:
                t = 'video' if kind == 'nwsb_video' else 'image'
                manifest.append([f"{slot}.{slot_media_id(v)}", t, v, os.path.relpath(path, ROOT)])
    for t, where, rx in DONE_PATTERNS:
        for m in rx.finditer(src):
            if not mask[m.start()]:
                continue
            open_i = m.end() - 1
            close_i = match_close(src, open_i)
            if close_i < 0:
                continue
            inner = src[open_i + 1:close_i]
            args = split_top_args(inner)
            if not args or has_named(inner, args, 'id'):
                continue
            if where == 'label':
                if len(args) < 2:
                    continue
                sl = string_value(inner[args[0][0]:args[0][1]])
                val = string_value(inner[args[1][0]:args[1][1]])
                if sl and val is not None:
                    manifest.append([f"{sl}.{slot_slug(val)}", 'text', val, os.path.relpath(path, ROOT)])
                continue
            slv = named_value(inner, args, 'slot')
            sl = string_value(slv) if slv else None
            if not sl:
                continue
            expr = inner[args[0][0]:args[0][1]] if where == 'first' else named_value(inner, args, where)
            v = const_ok(expr, consts) if expr else None
            if v:
                manifest.append([f"{sl}.{slot_media_id(v)}", t, v, os.path.relpath(path, ROOT)])
    if not edits:
        report.append((os.path.relpath(path, ROOT), counts, skipped))
        return False
    # every edit is a small replacement or a pure insertion; none overlap,
    # so apply them back to front on the original positions
    out = src
    for st, en, rep in sorted(edits, key=lambda e: (e[0], e[1]), reverse=True):
        out = out[:st] + rep + out[en:]
    src = out
    # import
    rel = os.path.relpath(os.path.join(ROOT, 'admin', 'template', 'editable.dart'), os.path.dirname(path)).replace(os.sep, '/')
    imp = f"import '{rel}';"
    if ('EditableImage' in src or 'EditableSvg' in src or 'EditableLabel' in src) and imp not in src:
        imports = list(re.finditer(r"^import [^;]+;[ \t]*$", src, re.M))
        if imports:
            last = imports[-1]
            src = src[:last.end()] + '\n' + imp + src[last.end():]
        else:
            src = imp + '\n' + src
    # drop a flutter_svg import that nothing uses any more
    if 'SvgPicture' not in re.sub(r"^import .*$", '', src, flags=re.M) and not re.search(r'\bSvg[A-Z]\w*|\bvg\.', re.sub(r"^import .*$", '', src, flags=re.M)):
        src = re.sub(r"^import 'package:flutter_svg/flutter_svg\.dart';\n", '', src, flags=re.M)
    report.append((os.path.relpath(path, ROOT), counts, skipped))
    if src != orig and not dry:
        open(path, 'w', encoding='utf-8').write(src)
    return src != orig

def stem_for(path, collisions):
    base = os.path.splitext(os.path.basename(path))[0]
    if base in collisions:
        return os.path.basename(os.path.dirname(path)) + '_' + base
    return base

def main():
    dry = '--dry-run' in sys.argv
    files = []
    for d, dirs, fs in os.walk(ROOT):
        rel = os.path.relpath(d, ROOT)
        top = rel.split(os.sep)[0]
        if top in EXCLUDE_DIRS:
            continue
        for f in fs:
            if f.endswith('.dart') and not f.endswith('.g.dart'):
                files.append(os.path.join(d, f))
    files.sort()
    all_files = []
    for d, _, fs in os.walk(ROOT):
        all_files += [os.path.join(d, f) for f in fs if f.endswith('.dart')]
    consts = collect_consts(all_files)
    bases = [os.path.splitext(os.path.basename(f))[0] for f in files]
    collisions = {b for b in bases if bases.count(b) > 1}
    report, manifest = [], []
    for f in files:
        sweep_file(f, stem_for(f, collisions), consts, report, manifest, dry)
    for slot, asset, src_file in EXTRA_MANIFEST:
        if os.path.exists(os.path.join(ROOT, '..', asset)):
            manifest.append([f"{slot}.{slot_media_id(asset)}", 'image', asset, src_file])
    # manifest (unique keys, first default wins)
    seen, rows = set(), []
    for r in manifest:
        if r[0] in seen:
            continue
        seen.add(r[0]); rows.append(r)
    rows.sort()
    def dq(s):
        return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n').replace('\r', '\\r') + "'"
    body = ''.join(f"  [{dq(a)}, {dq(b)}, {dq(c)}, {dq(d)}],\n" for a, b, c, d in rows)
    man = ("// GENERATED by tools/admin-slot-sweep.py — do not edit by hand.\n"
           "// [slot key, type, default (asset path or text), source file]\n"
           "const kSlotManifest = <List<String>>[\n" + body + "];\n")
    if not dry:
        open(os.path.join(ROOT, 'admin', 'template', 'slot_manifest.g.dart'), 'w', encoding='utf-8').write(man)
    # report
    tot = {k: 0 for k, _ in PATTERNS}
    lines = ['# Template slot sweep report', '', f'{len(rows)} static slots in the manifest.', '',
             '| file | Image.asset | Image.network | Svg | NwsbVideo | NwsbImage | Text |', '|---|---|---|---|---|---|---|']
    skipped_all = []
    for f, c, sk in report:
        for k in tot: tot[k] += c[k]
        if any(c.values()):
            lines.append(f"| {f} | {c['image_asset']} | {c['image_network']} | {c['svg_asset']} | {c['nwsb_video']} | {c['nwsb_image']} | {c['text']} |")
        skipped_all += [(f,) + s for s in sk]
    lines.append(f"| **total** | {tot['image_asset']} | {tot['image_network']} | {tot['svg_asset']} | {tot['nwsb_video']} | {tot['nwsb_image']} | {tot['text']} |")
    lines += ['', '## Skipped', '']
    lines += [f"- {f}:{ln} {k} — {why}" for f, k, ln, why in skipped_all]
    rp = None
    if '--report' in sys.argv:
        rp = sys.argv[sys.argv.index('--report') + 1]
        open(rp, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print(json.dumps({'totals': tot, 'manifest': len(rows), 'skipped': len(skipped_all), 'report': rp}))

if __name__ == '__main__':
    main()
