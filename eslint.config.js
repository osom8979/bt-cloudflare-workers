import js from '@eslint/js';
import {defineConfig, globalIgnores} from 'eslint/config';
import {createNodeResolver, importX} from 'eslint-plugin-import-x';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default defineConfig(
  globalIgnores(['**/dist', '.n', '.node', '.wrangler', 'worker-configuration.d.ts']),
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2022,
      globals: globals.browser,
    },
    plugins: {
      'import-x': importX,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    settings: {
      // 지정하지 않으면 기본 리졸버 `node` 를 찾다가 저장소 루트의 `./node` 래퍼를 JS 로 불러와 실패한다.
      'import-x/resolver-next': [createNodeResolver()],
      'import-x/internal-regex': '^@/',
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', {allowConstantExport: true}],
      '@typescript-eslint/no-unused-vars': [
        'error',
        {argsIgnorePattern: '^_', varsIgnorePattern: '^_'},
      ],
      '@typescript-eslint/no-empty-object-type': ['error', {allowInterfaces: 'always'}],
      'import-x/order': [
        'error',
        {
          groups: [
            'builtin',
            'external',
            'internal',
            'parent',
            'sibling',
            'index',
            'object',
            'type',
          ],
          'newlines-between': 'always',
          pathGroups: [
            {
              pattern: 'react',
              group: 'external',
              position: 'before',
            },
            {
              pattern: '@/**',
              group: 'external',
              position: 'after',
            },
          ],
          pathGroupsExcludedImportTypes: ['react'],
          distinctGroup: true,
          alphabetize: {
            order: 'asc',
            caseInsensitive: true,
          },
        },
      ],
    },
  }
);
