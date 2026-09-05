"""Build an installable pack with pack.mcmeta directly at the ZIP root."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json

root = Path(__file__).resolve().parent.parent
json.loads((root / 'pack.mcmeta').read_text(encoding='utf-8'))
files = list((root / 'assets').rglob('*'))
files.extend(root / name for name in ('pack.mcmeta', 'pack.png', 'assets.ajmeta'))
files = sorted(p for p in files if p.is_file())
output = root / 'dist' / 'Newhwalcass.zip'
output.parent.mkdir(exist_ok=True)
with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
    for file in files:
        archive.write(file, file.relative_to(root).as_posix())
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert 'pack.mcmeta' in archive.namelist()
    for file in files:
        assert archive.read(file.relative_to(root).as_posix()) == file.read_bytes()
print(f'{output}: {len(files)} files')
print('SHA256:', hashlib.sha256(output.read_bytes()).hexdigest())
