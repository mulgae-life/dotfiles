#!/usr/bin/env bash
# 비공개 작업 레포(origin)의 현재 파일을 공개 레포(public 원격)에 릴리즈 커밋 하나로 올린다.
# 새 커밋의 부모는 공개 레포의 직전 릴리즈 커밋이라, 비공개 커밋 기록은 전송되지 않는다.
# 릴리즈 노트는 CHANGELOG.md의 같은 버전 행, 작성자는 GitHub 대리 주소(noreply)를 쓴다.
#
# 사용: bash scripts/publish-release.sh <버전>     예) bash scripts/publish-release.sh v2.68
# 전제: 작업 트리가 깨끗하고 HEAD가 origin에 푸시된 상태, gh 로그인
# 공개 원격 이름은 PUBLIC_REMOTE(기본 public), gh에 넘길 owner/repo는 PUBLIC_REPO(기본: 원격 주소에서 읽음)로 바꿀 수 있다.
set -euo pipefail

VERSION="${1:-}"
PUBLIC_REMOTE="${PUBLIC_REMOTE:-public}"

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

[[ "$VERSION" =~ ^v[0-9]+(\.[0-9]+)*$ ]] || die "버전을 v2.68 형식으로 주세요"
cd "$(git rev-parse --show-toplevel)"

public_url=$(git remote get-url "$PUBLIC_REMOTE") || die "'${PUBLIC_REMOTE}' 원격이 없습니다"
origin_url=$(git remote get-url origin) || die "'origin' 원격이 없습니다"
[[ "$public_url" != "$origin_url" ]] || die "origin과 ${PUBLIC_REMOTE} 원격이 같은 레포를 가리킵니다"
if [[ -n "${PUBLIC_REPO:-}" ]]; then
  public_repo=$PUBLIC_REPO
elif [[ "$public_url" =~ ^(https://github\.com/|git@github\.com:)([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$ ]]; then
  public_repo=${BASH_REMATCH[2]%.git}
else
  die "공개 원격 주소에서 owner/repo를 읽지 못했습니다(PUBLIC_REPO로 지정): $public_url"
fi

[[ -z "$(git status --porcelain)" ]] || die "작업 트리에 커밋하지 않은 변경이 있습니다"
git fetch -q origin
[[ "$(git rev-parse HEAD)" == "$(git rev-parse '@{upstream}')" ]] || die "HEAD가 origin에 푸시된 상태와 다릅니다"

row_count=$(grep -cF "| **${VERSION}** |" CHANGELOG.md || true)
[[ "$row_count" == 1 ]] || die "CHANGELOG.md에서 ${VERSION} 행을 하나로 찾지 못했습니다(${row_count}개)"
row=$(grep -F "| **${VERSION}** |" CHANGELOG.md)
notes=${row#"| **${VERSION}** | "}
notes=${notes%" |"}

existing_tag=$(git ls-remote --tags "$PUBLIC_REMOTE" "refs/tags/${VERSION}")
[[ -z "$existing_tag" ]] || die "공개 레포에 ${VERSION} 태그가 이미 있습니다"

# 공개 쪽 태그를 로컬로 받아 오지 않는다(비공개 태그 체계와 섞이지 않게)
git fetch -q --no-tags "$PUBLIC_REMOTE"
tree=$(git rev-parse 'HEAD^{tree}')
parent_args=()
if parent=$(git rev-parse -q --verify "refs/remotes/${PUBLIC_REMOTE}/main"); then
  [[ "$(git rev-parse "${parent}^{tree}")" != "$tree" ]] || die "공개 레포의 최신 릴리즈와 파일이 같아 올릴 것이 없습니다"
  parent_args=(-p "$parent")
fi

read -r gh_id gh_login < <(gh api user -q '"\(.id) \(.login)"')
[[ -n "${gh_id:-}" && -n "${gh_login:-}" ]] || die "gh 계정 정보를 읽지 못했습니다"
email="${gh_id}+${gh_login}@users.noreply.github.com"

new=$(GIT_AUTHOR_NAME="$gh_login" GIT_AUTHOR_EMAIL="$email" \
      GIT_COMMITTER_NAME="$gh_login" GIT_COMMITTER_EMAIL="$email" \
      git commit-tree "$tree" "${parent_args[@]}" -m "$VERSION" -m "$notes")

git push --atomic "$PUBLIC_REMOTE" "${new}:refs/heads/main" "${new}:refs/tags/${VERSION}"
gh release create "$VERSION" -R "$public_repo" --title "$VERSION" --notes "$notes" --verify-tag
git fetch -q --no-tags "$PUBLIC_REMOTE"

printf '✅ %s 공개 릴리즈 완료: https://github.com/%s/releases/tag/%s\n' "$VERSION" "$public_repo" "$VERSION"
