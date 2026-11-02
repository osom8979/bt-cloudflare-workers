# CLAUDE.md

React + Vite + Hono 를 Cloudflare Workers 에 배포하는 프로젝트. 구조와 명령은 [README](README.md) 를 본다.

<!-- template-only:start -->

이 저장소는 템플릿이다. 파생 프로젝트는 `./init-project <이름>` 으로 만든다(README 의 "템플릿에서 새 프로젝트 만들기"). 템플릿 자체에서는 `init-project` 를 실행하거나 배포하지 않는다.

<!-- template-only:end -->

## 규칙 참조

별도 규칙 문서를 두지 않고 `../app.cvp.run/docs/rules/` 를 참조한다. 규칙을 이 저장소로 복사하지 않는다.

- **TS/TSX 코드 작성·수정** → `code-style.md`
- **한국어 글 작성·수정**(문서·주석·테스트 이름·UI 문자열) → `writing-style.md`

## 명령어

`node`, `npm`, `npx` 대신 `./node`, `./npm`, `./npx` 를 사용한다. 스크립트 목록은 `package.json` 의 `scripts` 를 참조한다.

`wrangler.jsonc` 의 바인딩·`vars`·`compatibility_date` 를 바꾸면 `./cf-typegen` 으로 `worker-configuration.d.ts` 를 다시 만든다. `Env` 를 직접 작성하지 않는다.

"모두 통과"는 `./check-all.sh` 전체 통과를 뜻한다. 일부만 빠르게 볼 때는 `./lint`, `./build`, `./test run`, `./test-worker run` 을 쓴다.
