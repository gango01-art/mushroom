#!/usr/bin/env python3
"""Create a reproducible, checksummed addon bundle (not a standalone Dota binary)."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile
ROOT=Path(__file__).resolve().parents[1]
import re
VERSION=re.search(r'Config.VERSION\s*=\s*"([^"]+)"',(ROOT/'game/scripts/vscripts/rift/core/config.lua').read_text()).group(1)
EXTRA=['START_DEMO.cmd','START_MATCH.cmd','BUILD_MAP.cmd','BUILD_FX.cmd','tools/install_duality.ps1',
       'README_FIRST.txt','docs/START_HERE.md','docs/ARENA_BUILD.md','docs/THIRD_PARTY.md','docs/design/arena-plan.svg',
       'docs/licenses/Barebones-Apache-2.0.txt','docs/licenses/Barebones-NOTICE.txt']
def files():
    paths=[p for tree in ['game','content'] for p in (ROOT/tree).rglob('*') if p.is_file()]
    paths.extend(ROOT/name for name in EXTRA)
    return sorted(paths,key=lambda p:p.relative_to(ROOT).as_posix())
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path('/workspace/artifacts')/f'duality-{VERSION}.zip')
    args=parser.parse_args()
    payload=files()
    compiled=(ROOT/'game/maps/rift_arena.vmap_c').is_file()
    manifest={'version':VERSION,'kind':'dota2-addon-bundle','requires':'Dota 2 + Workshop Tools',
              'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
              'source_dirty':bool(subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip()),
              'compiled_arena_included':compiled,
              'custom_fx_sources':['particles/duality/lc_gold_powershot.vpcf'],
              'custom_fx_compiled_included':(ROOT/'game/particles/duality/lc_gold_powershot.vpcf_c').is_file(),
              'demo_map':'dota','gameplay_validated_in_dota':False,
              'files':[{'path':p.relative_to(ROOT).as_posix(),'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in payload]}
    prefix=f'duality-{VERSION}/'
    args.output.parent.mkdir(parents=True,exist_ok=True)
    temporary=args.output.with_suffix('.zip.tmp')
    with zipfile.ZipFile(temporary,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for p in payload:
            info=zipfile.ZipInfo(prefix+p.relative_to(ROOT).as_posix(),date_time=(2026,11,15,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED
            archive.writestr(info,p.read_bytes())
        archive.writestr(prefix+'build_manifest.json',json.dumps(manifest,indent=2)+'\n')
    temporary.replace(args.output)
    with zipfile.ZipFile(args.output) as archive:
        assert archive.testzip() is None
        for entry in manifest['files']:
            assert hashlib.sha256(archive.read(prefix+entry['path'])).hexdigest()==entry['sha256']
    digest=hashlib.sha256(args.output.read_bytes()).hexdigest()
    args.output.with_suffix('.zip.sha256').write_text(digest+'  '+args.output.name+'\n')
    print(f'{args.output} ({args.output.stat().st_size} bytes, {len(payload)} files, compiled arena: {compiled})')
    print('SHA256 '+digest)
if __name__=='__main__':main()
