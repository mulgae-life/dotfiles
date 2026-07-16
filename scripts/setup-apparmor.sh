#!/bin/bash
# Codex bwrap용 AppArmor 프로필 설치 (1회 실행)

sudo tee /etc/apparmor.d/codex-sandbox << 'EOF'
abi <abi/4.0>,
include <tunables/global>

profile codex-sandbox /home/*/.nvm/**/codex-linux-*/vendor/*/codex/codex flags=(unconfined) {
  userns,

  include if exists <local/codex-sandbox>
}
EOF

sudo apparmor_parser -r /etc/apparmor.d/codex-sandbox

# user namespace 제한 해제 (즉시 + 영구)
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
echo "kernel.apparmor_restrict_unprivileged_userns=0" | sudo tee /etc/sysctl.d/99-userns.conf

echo "AppArmor codex-sandbox 프로필 + sysctl 설정 완료"
