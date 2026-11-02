#!/usr/bin/env bash
#
# 저장소 전체 점검기. 포맷·린트·타입 생성물·빌드·배포 설정·테스트·e2e 를 정해진 순서로
# 실행하고, 단계마다 통과 여부와 걸린 시간을 모아 보고한다. 실패하면 종료 코드는 1 이다.
#
#   ./check-all.sh                  # 전체
#   ./check-all.sh --list           # 단계 목록
#   ./check-all.sh --from test      # 이 단계부터
#   ./check-all.sh --skip test,e2e  # 이 단계들은 건너뛴다
#   ./check-all.sh -k               # 실패해도 끝까지 실행한다
#
# 빠르게 끝나는 검사를 앞에 두어 오래 걸리는 단계까지 가기 전에 멈춘다.
#
# `install` 은 node_modules 를 지우고 다시 설치하므로 `CI` 환경 변수가 있거나
# node_modules 가 없을 때만 실행한다.
#
# vitest 는 `AI_AGENT`·`CLAUDECODE` 를 보면 agent 리포터로 콘솔 블록을 숨기므로, vitest
# 단계는 이 변수를 빼고 색을 끈 채 실행한다. 테스트가 통과해도 출력에 콘솔 블록
# (`stdout |`·`stderr |`)이나 `uncaught`·unhandled 오류가 남으면 그 단계를 실패로 센다.
#
# `e2e` 는 `build` 가 만든 dist/ 를 `vite preview` 로 실제 Workers 런타임에서 실행하고
# HTTP 로 확인한다. 브라우저를 쓰는 테스트가 아니다. 브라우저 동작을 검증하려면
# Playwright 를 도입해 단계를 추가한다.
#
# 단계 출력은 화면과 로그 파일에 함께 남는다. 로그 디렉터리는 CHECK_LOG_DIR 로
# 정하고, 없으면 임시 디렉터리를 만든다.

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit; pwd)

# 이름|종류|설명|명령. 종류 `vitest` 는 위의 콘솔 블록 검사를 더한다.
# `deploy-dry-run` 과 `e2e` 는 `build` 가 만든 dist/ 를 사용한다.
STEPS=(
    "install|install|의존성 설치|./npm ci"
    "format|plain|Prettier 검사(고치지 않음)|./run format:check"
    "lint|plain|ESLint(경고도 실패로 처리)|./lint --max-warnings 0"
    "types|plain|worker-configuration.d.ts 최신 여부|./wrangler types --check"
    "build|plain|타입 검사와 빌드(tsc -b · vite)|./build"
    "deploy-dry-run|plain|Worker 배포 검증(wrangler --dry-run)|./wrangler deploy --dry-run"
    "test|vitest|브라우저 코드 테스트|./test run"
    "test-worker|vitest|Worker 테스트(workerd)|./test-worker run"
    "e2e|plain|빌드 결과 HTTP 점검(vite preview)|e2e_smoke"
)

BLOCK_PATTERN='^(stdout|stderr) \| '
ERROR_PATTERN='uncaught|unhandled (error|rejection)'

# `./dev` 의 48891 과 겹치지 않게 한다.
E2E_PORT=48892
E2E_URL="http://127.0.0.1:$E2E_PORT"
E2E_WAIT_SECS=60

usage() {
    echo "사용법: $(basename "$0") [옵션]"
    echo ""
    echo "포맷·린트·빌드·테스트·e2e 를 순서대로 실행하고 결과를 모아 보고합니다."
    echo ""
    echo "옵션:"
    echo "  --list              단계 목록을 출력합니다"
    echo "  --from STEP         STEP 부터 실행합니다"
    echo "  --skip STEP[,STEP]  STEP 을 건너뜁니다(여러 번 줄 수 있습니다)"
    echo "  -k, --keep-going    실패해도 남은 단계를 계속 실행합니다"
    echo "  --help              이 도움말을 출력합니다"
    echo ""
    echo "환경 변수:"
    echo "  CI                  값이 있으면 install 단계를 항상 실행합니다"
    echo "  CHECK_LOG_DIR       단계 로그를 남길 디렉터리(기본: 새 임시 디렉터리)"
}

list_steps() {
    local entry name kind desc cmd
    for entry in "${STEPS[@]}"; do
        IFS='|' read -r name kind desc cmd <<< "$entry"
        printf '  %-16s %s\n' "$name" "$desc"
        printf '  %-16s $ %s\n' "" "$cmd"
    done
}

# 단계 이름을 번호(0부터)로 바꾼다. 없는 이름이면 실패한다.
step_index() {
    local i
    for i in "${!STEPS[@]}"; do
        if [ "${STEPS[$i]%%|*}" = "$1" ]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

FROM_INDEX=0
SKIPS=()
KEEP_GOING=0

need_step_name() {
    if [ -z "$2" ]; then
        echo "$1 에 단계 이름이 필요합니다 (--list 로 목록을 확인합니다)" 1>&2
        exit 1
    fi
}

add_skips() {
    local name names
    need_step_name --skip "$1"
    IFS=',' read -r -a names <<< "$1"
    for name in "${names[@]}"; do
        if ! step_index "$name" > /dev/null; then
            echo "없는 단계입니다: $name (--list 로 목록을 확인합니다)" 1>&2
            exit 1
        fi
        SKIPS+=("$name")
    done
}

set_from() {
    need_step_name --from "$1"
    if ! FROM_INDEX=$(step_index "$1"); then
        echo "없는 단계입니다: $1 (--list 로 목록을 확인합니다)" 1>&2
        exit 1
    fi
}

while [ $# -gt 0 ]; do
    case "$1" in
        --list) list_steps; exit 0 ;;
        --from) set_from "${2:-}"; shift 2 ;;
        --from=*) set_from "${1#--from=}"; shift ;;
        --skip) add_skips "${2:-}"; shift 2 ;;
        --skip=*) add_skips "${1#--skip=}"; shift ;;
        -k|--keep-going) KEEP_GOING=1; shift ;;
        --help) usage; exit 0 ;;
        *) echo "알 수 없는 옵션입니다: $1" 1>&2; usage 1>&2; exit 1 ;;
    esac
done

is_skipped() {
    local name
    for name in "${SKIPS[@]}"; do
        if [ "$name" = "$1" ]; then
            return 0
        fi
    done
    return 1
}

format_secs() {
    if [ "$1" -ge 60 ]; then
        printf '%dm%02ds' $(($1 / 60)) $(($1 % 60))
    else
        printf '%ds' "$1"
    fi
}

# 경로의 상태 코드와 본문을 확인한다. 본문 조건은 grep -E 패턴이다. 브라우저가 주소창으로
# 여는 요청과 같게 보낸다. 이 헤더가 없으면 `run_worker_first` 가 빠져도 /api/* 가 Worker 로
# 전달되어 결함을 찾지 못한다.
e2e_expect() {
    local path=$1 want_status=$2 want_body=$3 response status body
    response=$(curl -sS --max-time 10 -H 'Sec-Fetch-Mode: navigate' \
        -w '\n%{http_code}' "$E2E_URL$path") || return 1
    status=${response##*$'\n'}
    body=${response%$'\n'*}
    if [ "$status" = "$want_status" ] && grep -qE "$want_body" <<< "$body"; then
        echo "통과: GET $path → $status"
        return 0
    fi
    echo "실패: GET $path → $status (기대 상태: $want_status, 기대 본문: $want_body)"
    head -20 <<< "$body"
    return 1
}

e2e_smoke() {
    local server failed=0 i asset

    # n-exec 아래의 프로세스까지 한 번에 종료하도록 별도 프로세스 그룹으로 실행한다.
    # 남은 프로세스가 출력 파이프를 잡고 있으면 이 단계가 끝나지 않는다.
    set -m
    ./npx vite preview --host 127.0.0.1 --port "$E2E_PORT" --strictPort &
    server=$!
    set +m
    # shellcheck disable=SC2064 # server 는 지역 변수이므로 지금 펼친다.
    trap "kill -- -$server 2> /dev/null" EXIT

    for ((i = 0; i < E2E_WAIT_SECS; i++)); do
        # `-f` 가 없으면 포트를 점유한 다른 서버의 오류 응답도 준비 완료로 본다.
        if curl -fs -o /dev/null --max-time 2 "$E2E_URL/api/health"; then
            break
        fi
        if ! kill -0 "$server" 2> /dev/null; then
            echo "미리 보기 서버가 응답 전에 종료되었습니다."
            return 1
        fi
        sleep 1
    done

    # `run_worker_first` 가 빠지면 /api/* 에 SPA 의 HTML 이 200 으로 응답하므로 JSON 까지 확인한다.
    e2e_expect /api/health 200 '"status":"ok"' || failed=1
    e2e_expect /api/health 200 '"environment":"production"' || failed=1
    e2e_expect /api/unknown 404 '"error":"not_found"' || failed=1
    e2e_expect / 200 'id="root"' || failed=1
    e2e_expect /some/client/route 200 'id="root"' || failed=1

    asset=$(curl -sS --max-time 10 "$E2E_URL/" | grep -oE '/assets/[^"]+\.js' | head -1)
    if [ -z "$asset" ]; then
        echo "실패: index.html 에서 스크립트 경로를 찾지 못했습니다."
        failed=1
    else
        e2e_expect "$asset" 200 . || failed=1
    fi

    return $failed
}

LOG_DIR=${CHECK_LOG_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/check-all.XXXXXX")}
mkdir -p "$LOG_DIR" || exit 1

# 단계별 결과. 상태는 pass·fail·skip 이고, 비어 있으면 실행하지 않은 단계다.
STATUS=()
TIMES=()
NOTES=()

print_summary() {
    local i name label time failed=0
    echo
    echo "== 결과"
    for i in "${!STEPS[@]}"; do
        name=${STEPS[$i]%%|*}
        time=""
        if [ -n "${TIMES[$i]:-}" ]; then
            time=$(format_secs "${TIMES[$i]}")
        fi
        case "${STATUS[$i]:-}" in
            pass) label="통과" ;;
            fail) label="실패"; failed=$((failed + 1)) ;;
            skip) label="건너뜀" ;;
            *) label="실행 안 함" ;;
        esac
        printf '  %-16s %7s  %s' "$name" "$time" "$label"
        if [ -n "${NOTES[$i]:-}" ]; then
            printf '  %s' "${NOTES[$i]}"
        fi
        echo
    done
    echo
    echo "로그: $LOG_DIR"
    echo "전체 시간: $(format_secs $SECONDS)"
    if [ $failed -gt 0 ]; then
        echo "${failed}개 단계가 실패했습니다."
    fi
}

trap 'echo; echo "중단했습니다."; print_summary; exit 130' INT

cd "$ROOT_DIR" || exit 1
echo "로그: $LOG_DIR"

FAILED=0
for i in "${!STEPS[@]}"; do
    IFS='|' read -r name kind desc cmd <<< "${STEPS[$i]}"

    if [ "$i" -lt "$FROM_INDEX" ] || is_skipped "$name"; then
        STATUS[i]=skip
        continue
    fi
    if [ "$kind" = install ] && [ -z "${CI:-}" ] && [ -d node_modules ]; then
        STATUS[i]=skip
        NOTES[i]="CI 가 아니고 node_modules 가 있음"
        continue
    fi
    if [ $FAILED -gt 0 ] && [ $KEEP_GOING -eq 0 ]; then
        continue
    fi

    log="$LOG_DIR/$(printf '%02d' $((i + 1)))-$name.log"
    echo
    echo "== [$((i + 1))/${#STEPS[@]}] $name — $desc"
    echo "\$ $cmd"

    if [ "$kind" = vitest ]; then
        cmd="env -u AI_AGENT -u CLAUDECODE NO_COLOR=1 $cmd"
    fi

    started=$SECONDS
    eval "$cmd" < /dev/null 2>&1 | tee "$log"
    code=${PIPESTATUS[0]}
    TIMES[i]=$((SECONDS - started))

    if [ "$code" -ne 0 ]; then
        STATUS[i]=fail
        NOTES[i]="종료 코드 $code"
    elif [ "$kind" = vitest ]; then
        blocks=$(grep -cE "$BLOCK_PATTERN" "$log")
        errors=$(grep -ciE "$ERROR_PATTERN" "$log")
        if [ "$blocks" -gt 0 ] || [ "$errors" -gt 0 ]; then
            STATUS[i]=fail
            NOTES[i]="콘솔 블록 $blocks · uncaught/unhandled $errors"
            echo
            echo "테스트는 통과했지만 출력에 경고가 남았습니다:"
            grep -nE "$BLOCK_PATTERN" "$log" | head -20
            grep -niE "$ERROR_PATTERN" "$log" | head -20
        else
            STATUS[i]=pass
        fi
    else
        STATUS[i]=pass
    fi

    if [ "${STATUS[$i]}" = fail ]; then
        FAILED=$((FAILED + 1))
    fi
done

print_summary
if [ $FAILED -gt 0 ]; then
    exit 1
fi
echo "모든 단계를 통과했습니다."
