# bt-cloudflare-workers

Cloudflare Workers 배포용 기본 템플릿. React + Vite + Hono 를 Workers 에 배포한다.

| 경로                        | 역할                                                                     |
| --------------------------- | ------------------------------------------------------------------------ |
| `src/worker/`               | Hono API. `/api/*` 를 처리한다                                           |
| `src/react-app/`            | React SPA. 빌드 결과를 Workers Static Assets 로 제공한다                 |
| `wrangler.jsonc`            | Worker 설정. `env.development` 는 로컬 개발용이다                        |
| `worker-configuration.d.ts` | `wrangler types` 생성물. 바인딩을 바꾸면 `./cf-typegen` 으로 다시 만든다 |

## 시작하기

`node`·`npm`·`npx` 대신 저장소의 `./node`·`./npm`·`./npx` 를 쓴다. 첫 실행 때 `n-exec` 가 `.node-version` 의 Node 를 `.node/` 에 설치한다.

```sh
./npm install
./dev          # http://localhost:48891
```

Worker 로컬 시크릿은 `.dev.vars.example` 을 `.dev.vars.development` 로, 브라우저 공개 값은 `.env.example` 을 `.env.development` 로 복사해 채운다.

## 명령

| 명령                       | 동작                                                           |
| -------------------------- | -------------------------------------------------------------- |
| `./n-exec <명령>`          | 저장소의 Node 환경에서 명령 실행. 아래 래퍼의 기반이다         |
| `./node`, `./npm`, `./npx` | 저장소의 Node 로 `node`·`npm`·`npx` 실행                       |
| `./run <스크립트>`         | `npm run` 실행                                                 |
| `./dev`                    | 개발 서버 (`CLOUDFLARE_ENV=development`)                       |
| `./build`                  | 타입 검사 후 빌드                                              |
| `./npm run check`          | 빌드 후 `wrangler deploy --dry-run` 으로 배포 설정 검증        |
| `./npm run preview`        | 빌드 결과를 Workers 런타임으로 미리 보기                       |
| `./npm run deploy`         | 빌드 후 배포                                                   |
| `./test run`               | 브라우저 코드 테스트                                           |
| `./test-worker run`        | Worker 테스트 (workerd 안에서 실행)                            |
| `./lint`, `./format`       | ESLint, Prettier                                               |
| `./cf-typegen`             | `worker-configuration.d.ts` 재생성                             |
| `./wrangler`               | `wrangler` CLI 실행                                            |
| `./check-all.sh`           | 포맷·린트·타입·빌드·배포 검증·테스트·e2e 전체 점검 (CI 진입점) |

### 전체 점검

`./check-all.sh` 는 아래 단계를 순서대로 실행하고 단계마다 결과와 걸린 시간을 보고한다. `--list` 로 단계와 명령을, `--help` 로 옵션을 확인한다.

| 단계             | 내용                                                                   |
| ---------------- | ---------------------------------------------------------------------- |
| `install`        | `./npm ci`. `CI` 가 있거나 `node_modules` 가 없을 때만 실행한다        |
| `format`         | Prettier 검사                                                          |
| `lint`           | ESLint. 경고도 실패로 처리한다                                         |
| `types`          | `worker-configuration.d.ts` 최신 여부                                  |
| `build`          | 타입 검사와 빌드                                                       |
| `deploy-dry-run` | `wrangler deploy --dry-run` 으로 배포 검증. 실제로 배포하지 않는다     |
| `test`           | 브라우저 코드 테스트                                                   |
| `test-worker`    | Worker 테스트                                                          |
| `e2e`            | 빌드 결과를 `vite preview` 로 실제 Workers 런타임에서 실행해 HTTP 점검 |

`e2e` 는 브라우저를 쓰지 않는다. 브라우저 동작을 검증하려면 Playwright 를 도입해 단계를 추가한다.

## Cloudflare 연결

아래 작업은 저장소 밖의 계정 설정이므로 처음 한 번 직접 수행한다.

1. **로그인**: `./wrangler login`
2. **시크릿 등록**: `./wrangler secret put <NAME>`. 값을 `wrangler.jsonc` 의 `vars` 에 넣지 않는다.
3. **배포**: `./npm run deploy`. 저장소를 Workers Builds 에 연결하는 경우 빌드 명령은 `npm run build`, 배포 명령은 `npx wrangler deploy` 로 둔다. Node 버전은 `.node-version` 을 따른다.
4. **도메인**: 대시보드에서 연결하거나 `wrangler.jsonc` 에 `"routes": [{"pattern": "example.com", "custom_domain": true}]` 를 추가한다.

이 템플릿에는 인증이 없다. 비공개 기능을 추가하기 전에 Cloudflare Access 나 앱 인증을 적용한다. 그 전까지 `*.workers.dev` 주소도 공개되므로, 필요하면 `"workers_dev": false` 로 끈다.

## 버전 제약

아래 패키지는 호환성 때문에 버전이나 종류를 제한한다.

| 패키지                      | 내용                                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------------------------------ |
| `typescript`                | `~6.0` 으로 고정한다. 7.0 은 컴파일러 API 가 달라 `typescript-eslint` 가 지원하지 않는다 (`<6.1.0`)    |
| `eslint-plugin-import-x`    | `eslint-plugin-import` 가 ESLint 10 을 지원하지 않아 대체했다. 규칙 이름은 `import-x/order` 이다       |
| `@cloudflare/vitest-plugin` | `@cloudflare/vitest-pool-workers` 의 후속 패키지이다. 옛 이름은 폐기되었고 vitest 5 를 지원하지 않는다 |
