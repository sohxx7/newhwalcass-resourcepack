"""Build the four 26.3 packs. HQ BGM remains managed separately."""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parent.parent
PACKS = {'new': 'pack', 'base': 'packs/base', 'low': 'packs/low', 'bgm': 'packs/bgm'}


def build(name):
    source = ROOT / PACKS[name]
    metadata = json.loads((source / 'pack.mcmeta').read_text(encoding='utf-8-sig'))
    if metadata['pack']['min_format'] != [97, 1] or metadata['pack']['max_format'] != [97, 1]:
        raise ValueError(f'{name}: expected 26.3 resource format 97.1')
    files = sorted(p for p in source.rglob('*') if p.is_file())
    for file in files:
        relative = file.relative_to(source)
        if relative.parts[0] not in {'assets', 'assets.ajmeta', 'pack.mcmeta', 'pack.png'}:
            raise ValueError(f'Unexpected pack member: {relative}')
        if file.is_symlink():
            raise ValueError(f'Symlink not allowed in pack: {relative}')
    output = ROOT / 'dist' / f'{name}-26.3.zip'
    output.parent.mkdir(exist_ok=True)
    with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=6) as archive:
        for file in files:
            info = ZipInfo(file.relative_to(source).as_posix(), (2026, 10, 13, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, file.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=6)
    with ZipFile(output) as archive:
        assert archive.testzip() is None
        assert set(archive.namelist()) == {p.relative_to(source).as_posix() for p in files}
        for file in files:
            assert archive.read(file.relative_to(source).as_posix()) == file.read_bytes()
    data = output.read_bytes()
    result = {'file': output.name, 'bytes': len(data), 'files': len(files),
              'sha1': hashlib.sha1(data).hexdigest(), 'sha256': hashlib.sha256(data).hexdigest()}
    print(json.dumps(result), flush=True)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pack', choices=['all', *PACKS], default='all')
    args = parser.parse_args()
    names = list(PACKS) if args.pack == 'all' else [args.pack]
    built = [build(name) for name in names]
    # Keep the published release checksums unchanged; new builds get their own manifest.
    output = ROOT / 'dist' / f'build-{args.pack}-26.3.json'
    output.write_text(json.dumps(built, indent=2) + '\n', encoding='utf-8', newline='\n')
