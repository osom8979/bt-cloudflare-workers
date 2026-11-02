# CLAUDE.md

bt-cloudflare-workers: Cloudflare Workers 배포용 기본 템플릿. React + Vite + Hono + Cloudflare Workers. 구조와 명령은 [README](README.md) 를 본다.

## 규칙 참조

별도 규칙 문서를 두지 않고 `../app.cvp.run/docs/rules/` 를 참조한다. 규칙을 이 저장소로 복사하지 않는다.

- **TS/TSX 코드 작성·수정** → `code-style.md`
- **한국어 글 작성·수정**(문서·주석·테스트 이름·UI 문자열) → `writing-style.md`

## 명령어

`node`, `npm`, `npx` 대신 `./node`, `./npm`, `./npx` 를 사용한다. 스크립트 목록은 `package.json` 의 `scripts` 를 참조한다.

`wrangler.jsonc` 의 바인딩을 바꾸면 `./cf-typegen` 으로 `worker-configuration.d.ts` 를 다시 만든다. `Env` 를 직접 작성하지 않는다.

"모두 통과"는 `./lint`, `./build`, `./test run`, `./test-worker run` 전체 통과를 뜻한다.
