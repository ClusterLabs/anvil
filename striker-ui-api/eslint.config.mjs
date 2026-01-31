import { defineConfig, globalIgnores } from 'eslint/config';
import globals from 'globals';
// Configs:
import jsConfig from '@eslint/js';
import prettierConfig from 'eslint-config-prettier';
// Plugins:
import importPlugin from 'eslint-plugin-import';
import tsEslintPlugin from '@typescript-eslint/eslint-plugin';

/**
 * @type {import('eslint').Linter.Config}
 */
const config = defineConfig([
  globalIgnores(['out/', '**/*.config.{js,mjs}']),
  {
    extends: [
      // Previously: "eslint:recommended"
      jsConfig.configs.recommended,

      // Previously: "plugin:@typescript-eslint/recommended"
      tsEslintPlugin.configs['flat/recommended'],

      // Previously: "plugin:import/errors"
      importPlugin.flatConfigs.errors,

      // Previously: "plugin:import/typescript"
      importPlugin.flatConfigs.typescript,

      // Previously: "plugin:import/warnings"
      importPlugin.flatConfigs.warnings,

      // Previously: "prettier"
      prettierConfig,
    ],

    languageOptions: {
      globals: {
        // Previously: env.es2022=true
        ...globals.es2022,
        // Previously: env.node=true
        ...globals.node,
      },
    },

    name: 'striker-ui-api/all',

    rules: {
      // "@typescript-eslint" rules:

      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          // Ignore unused "error" variables in catch block of try-catches
          caughtErrors: 'none',
          // Ignore unused rest or spread (...) siblings
          ignoreRestSiblings: true,
        },
      ],

      // "import" rules:

      // Don't require file extensions when importing.
      'import/extensions': [
        'error',
        'ignorePackages',
        {
          js: 'never',
          jsx: 'never',
          mjs: 'never',
          ts: 'never',
          tsx: 'never',
        },
      ],
    },
  },
]);

export default config;
