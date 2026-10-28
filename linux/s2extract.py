"""Steam2 storage extractor (depot <n>.data/.index + <n>_<version>.manifest), standard library only.
Written from the formats as Chunksmith (github.com/siohaza/chunksmith, MIT) reads them.

  python3 -I s2extract.py list <manifest>
  python3 -I s2extract.py extract <manifest> <storage dir> <depot> <out dir> [glob ...]

Chunk modes: 0 raw, 1 zlib, 2/3 AES-CFB (encrypted depots: not supported here, reported).
"""
import fnmatch
import os
import struct
import sys
import zlib

FILE_FLAG = 0x4000


def load_manifest(path):
    d = open(path, 'rb').read()
    num_items, = struct.unpack_from('<I', d, 12)
    names_start = 56 + num_items * 28
    entries = []
    large = False
    for i in range(num_items):
        nameoff, size, fileid, dirtype, parent, nxt, first = struct.unpack_from('<7I', d, 56 + i * 28)
        if large:                       # extra entry: high bits of the previous file's size
            prev = entries[-1]
            prev['size'] = (prev['size'] & 0x7FFFFFFF) | (size << 31)
            entries.append(None)
            large = False
            continue
        s = names_start + nameoff
        name = d[s:d.index(b'\0', s)].decode('latin1')
        entries.append({'name': name, 'size': size, 'fileid': fileid, 'type': dirtype, 'parent': parent})
        if dirtype & FILE_FLAG and size & 0x80000000:
            large = True
    for e in entries:
        if e is None:
            continue
        parts = [e['name']]
        p = e['parent']
        while p != 0xFFFFFFFF:
            parts.append(entries[p]['name'])
            p = entries[p]['parent']
        e['path'] = '/'.join(reversed(parts)).strip('/')
    return [e for e in entries if e is not None]


def load_index(path):
    d = open(path, 'rb').read()
    idx = {}
    p = 0
    while p + 24 <= len(d):
        fileid, ilen, mode = struct.unpack_from('>QQQ', d, p)
        p += 24
        if ilen:
            chunks = [struct.unpack_from('>QQ', d, p + k) for k in range(0, ilen, 16)]
            idx[fileid] = (mode, chunks)
            p += ilen
    return idx


def safe_path(base, rel):
    rel = rel.replace('\\', '/').replace(':', '')
    parts = [c for c in rel.split('/') if c]
    if rel.startswith('/') or '..' in parts:
        raise ValueError('unsafe path in manifest: ' + rel)
    return os.path.join(base, *parts)


def main():
    cmd = sys.argv[1]
    entries = load_manifest(sys.argv[2])
    if cmd == 'list':
        for e in entries:
            if e['type'] & FILE_FLAG:
                print(f"FILE {e['size']:10d} {e['path']}")
            else:
                print(f"DIR             {e['path']}")
        return
    storage, depot, out = sys.argv[3], sys.argv[4], sys.argv[5]
    globs = sys.argv[6:]
    index = load_index(os.path.join(storage, depot + '.index'))
    data = open(os.path.join(storage, depot + '.data'), 'rb')
    done = missing = encrypted = bad = 0
    for e in entries:
        if not e['type'] & FILE_FLAG or e['fileid'] == 0xFFFFFFFF:
            continue
        if globs and not any(fnmatch.fnmatch(e['path'], g) for g in globs):
            continue
        dst = safe_path(out, e['path'])
        if e['fileid'] not in index:
            missing += 1
            print('missing in storage:', e['path'])
            continue
        mode, chunks = index[e['fileid']]
        if mode in (2, 3):
            encrypted += 1
            print('encrypted, skipped:', e['path'])
            continue
        os.makedirs(os.path.dirname(dst) or '.', exist_ok=True)
        with open(dst + '.part', 'wb') as o:
            for start, length in chunks:
                if not length:
                    continue
                data.seek(start)
                buf = data.read(length)
                o.write(zlib.decompress(buf) if mode == 1 else buf)
        if os.path.getsize(dst + '.part') != e['size']:
            bad += 1
            print(f"size mismatch {os.path.getsize(dst + '.part')} != {e['size']}: {e['path']}")
        os.replace(dst + '.part', dst)
        done += 1
    print(f'extracted {done}, missing {missing}, encrypted {encrypted}, size mismatches {bad}')


main()
