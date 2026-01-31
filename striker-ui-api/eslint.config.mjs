import { defineConfig, globalIgnores } from 'eslint/config';
import globals from 'globals';
// Configs:
import jsConfig from '@eslint/js';
import prettierConfig from 'eslint-config-prettier';
// Plugins:
import importPlugin from 'eslint-plugin-import';

/**
 * @type {import('eslint').Linter.Config}
 */
const config = defineConfig([
  globalIgnores(['node_modules/', 'out/', '**/*.config.{js/mjs}']),
  {
    extends: [
      // Previously: "eslint:recommended"
      jsConfig.configs.recommended,

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
  },
]);

export default config;
