"""Build an uploadable addon ZIP from the manifest's runtime file list."""
from pathlib import Path
import argparse,re,zipfile
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path);args=parser.parse_args()
manifest=(root/'SmartChatMsg.txt').read_text(encoding='utf-8')
version=re.search(r'^## Version:\s*(\S+)',manifest,re.M).group(1)
files=['SmartChatMsg.txt']+[line.strip() for line in manifest.splitlines() if line.strip() and not line.startswith('#')]
files+=['LICENSE','SmartChatMsg_ReadMe.txt',f'SmartChatMsg_Help_Guide_v{version}.html']
assert len(files)==len(set(files)), 'Duplicate release paths'
for name in files:
 p=root/name
 assert p.is_file() and p.resolve().is_relative_to(root),f'Missing or invalid release file: {name}'
output=args.output or root/f'SmartChatMsg-{version}.zip';output.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(output,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
 for name in files:archive.write(root/name,'SmartChatMsg/'+name)
with zipfile.ZipFile(output) as archive:
 assert archive.testzip() is None
 assert set(archive.namelist())=={'SmartChatMsg/'+name for name in files}
print(f'{output.resolve()}\n{len(files)} files; {output.stat().st_size:,} bytes; verified archive')
