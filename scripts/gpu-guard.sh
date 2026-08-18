#!/usr/bin/env bash
# GPU 메모리 고갈 크래시 가드 (2026-08-16 시스템 사망 사건 재발 방지, gotchas G6)
# 원리: amdgpu의 "Not enough memory for command submission" 커널 에러는
#   시스템 행의 전조 (첫 에러 후 ~3분 내 사망, 초기엔 시스템이 반응함).
#   이 시그니처가 뜨는 즉시 GTT 최대 점유 프로세스를 죽여 시스템을 살린다.
# 보조 조건: GTT가 상한 1.5GiB 이내 + 가용 RAM < 1GiB (사망 직전 상태) → 선제 대응.
set -u

INTERVAL="${GUARD_INTERVAL:-15}"
CARD_DIR=$(dirname "$(ls /sys/class/drm/card*/device/mem_info_gtt_total 2>/dev/null | head -1)")
GTT_TOTAL=$(cat "$CARD_DIR/mem_info_gtt_total")
HARD_HEADROOM=$((1536*1024*1024))   # 1.5GiB

log() { logger -t gpu-guard "$*"; echo "$(date +%T) $*"; }

# /proc/*/fdinfo에서 amdgpu GTT 점유 최대 프로세스 탐색 (compositor 제외)
top_gtt_pid() {
  local best_pid=0 best_kib=0
  for p in /proc/[0-9]*; do
    local pid=${p#/proc/}
    local comm; comm=$(cat "$p/comm" 2>/dev/null) || continue
    case "$comm" in gnome-shell|Xwayland|kwin*|weston*) continue;; esac
    local kib=0 f
    for f in "$p"/fdinfo/*; do
      # 같은 프로세스의 여러 fd는 같은 DRM 클라이언트를 중복 보고할 수 있어 최대값 사용
      local v; v=$(awk '/^drm-memory-gtt:/ {print $2; exit}' "$f" 2>/dev/null) || continue
      [[ -n ${v:-} && $v -gt $kib ]] && kib=$v
    done
    if (( kib > best_kib )); then best_kib=$kib; best_pid=$pid; fi
  done
  echo "$best_pid $best_kib"
}

kill_top() {
  local reason="$1"
  read -r pid kib <<<"$(top_gtt_pid)"
  if (( pid > 0 && kib > 2*1024*1024 )); then   # 2GiB 이상 점유자만
    local comm; comm=$(cat /proc/$pid/comm 2>/dev/null || echo '?')
    log "EMERGENCY($reason): kill -9 $pid ($comm, GTT $((kib/1024/1024))GiB)"
    notify-send -u critical "gpu-guard" "$reason → $comm(pid $pid) 강제 종료 (GTT $((kib/1024/1024))GiB)" 2>/dev/null || true
    kill -9 "$pid"
  else
    log "EMERGENCY($reason): 2GiB+ GTT 점유 프로세스를 못 찾음 — 개입 없음"
  fi
}

# 테스트 모드: 스캐너만 실행하고 종료
if [[ ${1:-} == --scan-test ]]; then
  read -r pid kib <<<"$(top_gtt_pid)"
  echo "top GTT: pid=$pid comm=$(cat /proc/$pid/comm 2>/dev/null || echo -) gtt=$((kib/1024/1024))GiB"
  exit 0
fi

log "가드 시작 (GTT total $((GTT_TOTAL/1024/1024/1024))GiB, ${INTERVAL}s 주기)"
while sleep "$INTERVAL"; do
  # 1) 확정 시그니처: 최근 커널 로그의 CS ENOMEM 에러
  if journalctl -k --since "-${INTERVAL}s" --no-pager -q 2>/dev/null \
     | grep -qm1 "Not enough memory for command submission"; then
    kill_top "amdgpu CS ENOMEM 감지"
    sleep 30   # 정리 시간
    continue
  fi
  # 2) 선제 조건: GTT 상한 임박 + RAM 고갈 동시
  gtt_used=$(cat "$CARD_DIR/mem_info_gtt_used")
  mem_avail_kib=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  if (( gtt_used > GTT_TOTAL - HARD_HEADROOM && mem_avail_kib < 1024*1024 )); then
    kill_top "GTT 임박($((gtt_used/1024/1024/1024))GiB)+RAM 고갈($((mem_avail_kib/1024))MiB)"
    sleep 30
  fi
done
