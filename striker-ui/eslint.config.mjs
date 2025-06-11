import { defineConfig, globalIgnores } from 'eslint/config';
// Configs:
import jsConfig from '@eslint/js';
import prettierConfig from 'eslint-config-prettier';
// Plugins:
import nextPlugin from '@next/eslint-plugin-next';
import tsEslintPlugin from '@typescript-eslint/eslint-plugin';
import importPlugin from 'eslint-plugin-import';
import jsxA11yPlugin from 'eslint-plugin-jsx-a11y';
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';

// console.dir(
//   {
//     value: reactPlugin.configs.flat,
//   },
//   {
//     depth: 3,
//     showHidden: true,
//     sorted: true,
//   },
// );

/**
 * @type {import('eslint').Linter.Config}
 */
const config = defineConfig([
  globalIgnores(['node_modules/', '.next/', 'out/', '**/*.config.{js,mjs}']),
  {
    // Flat configs required.
    //
    // Configs are loaded in order, with latter ones overriding earlier ones.
    extends: [
      // Previously: "eslint:recommended"
      jsConfig.configs.recommended,

      // Previously: "plugin:@typescript-eslint/recommended"
      tsEslintPlugin.configs['flat/recommended'],

      // Previously: "plugin:import/errors"
      //
      // Don't use "import/recommended" because it's not updated yet.
      importPlugin.flatConfigs.errors,

      // Previously: "plugin:import/warnings"
      importPlugin.flatConfigs.warnings,

      // Previously: "plugin:import/typescript"
      importPlugin.flatConfigs.typescript,

      // Previously: "plugin:jsx-a11y/recommended"
      jsxA11yPlugin.flatConfigs.recommended,

      // Previously: "plugin:react/recommended"
      reactPlugin.configs.flat.recommended,

      // Previously: "plugin:react-hooks/recommended"
      reactHooksPlugin.configs['recommended-latest'],

      // Previously: "prettier"
      //
      // Contains only a json config, it's not a plugin.
      prettierConfig,

      // Replaces: "next/core-web-vitals"
      nextPlugin.flatConfig.recommended,
    ],

    files: ['**/*.{js,jsx,ts,tsx}'],

    languageOptions: {
      // parser:@typescript-eslint/parser already listed in its config.
    },

    name: 'striker-ui/all',

    plugins: {
      // plugin:@next/next already listed in its config.
      // plugin:@typescript-eslint already listed in its config.
      // plugin:import already listed in first of its configs.
      // plugin:jsx-a11y already listed in its config.
      // plugin:react already listed in its config.
      // plugin:react-hooks already listed in its config.
    },

    rules: {
      // Reduce the number of "if"s to reduce code complexity.
      complexity: ['error', 6],

      // Ensure regular scripts can't use jsx.
      'react/jsx-filename-extension': [
        'error',
        {
          extensions: ['.tsx'],
        },
      ],

      // Don't validate props for now.
      //
      // TODO: enable eventually.
      'react/prop-types': 'off',

      // Don't enforce "import React..." when using jsx.
      'react/react-in-jsx-scope': 'off',
    },

    settings: {
      react: {
        version: 'detect',
      },
    },
  },
]);

export default config;
