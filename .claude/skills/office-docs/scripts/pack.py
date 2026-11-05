#!/usr/bin/env python3
"""풀어 놓은 OOXML 디렉토리를 다시 .docx/.pptx/.xlsx 파일로 묶는다.

사용: python scripts/pack.py unpacked/ out.docx

`(cd unpacked && rm -f ../out.docx && zip -Xr ../out.docx .)` 대신 쓴다. 임시 파일에 새
아카이브를 쓴 뒤 교체하므로 이전 파일의 잔여 항목이 섞이지 않고, `[Content_Types].xml`을
비압축으로 맨 앞에 둔다.
"""

import sys
from pathlib import Path

from office.helpers import rezip


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    if not (src / "[Content_Types].xml").is_file():
        print(f"OOXML 디렉토리가 아닙니다 ([Content_Types].xml 없음): {src}", file=sys.stderr)
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    rezip(src, out)
    print(f"{src}/ → {out} ({out.stat().st_size:,} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
