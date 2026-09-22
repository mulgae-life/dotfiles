#!/usr/bin/env python3
"""OOXML 파일(.docx/.pptx/.xlsx 등)을 디렉토리로 안전하게 푼다.

사용: python scripts/unpack.py file.docx unpacked/

`unzip` + `find -type l -delete` 대신 쓴다. 심볼릭 링크 항목과 대상 디렉토리 밖으로
나가는 경로는 거부하므로 외부에서 받은 파일에도 그대로 쓸 수 있다.
"""

import sys
import zipfile
from pathlib import Path

from office.helpers import safe_extract


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    src, dest = Path(sys.argv[1]), Path(sys.argv[2])
    if not src.is_file():
        print(f"파일이 없습니다: {src}", file=sys.stderr)
        return 1
    if dest.exists() and any(dest.iterdir()):
        print(f"대상 디렉토리가 비어 있지 않습니다: {dest}", file=sys.stderr)
        return 1
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(src) as zf:
        safe_extract(zf, dest)
    print(f"{src} → {dest}/ ({len(list(dest.rglob('*')))}개 항목)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
