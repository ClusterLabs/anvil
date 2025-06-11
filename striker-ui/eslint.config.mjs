import { FlatCompat } from '@eslint/eslintrc';
import { defineConfig, globalIgnores } from 'eslint/config';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';
// Configs:
import jsConfig from '@eslint/js';
import prettierConfig from 'eslint-config-prettier';
// Plugins:
import nextPlugin from '@next/eslint-plugin-next';
import tsEslintPlugin from '@typescript-eslint/eslint-plugin';
import importPlugin from 'eslint-plugin-import';
// import jsxA11yPlugin from 'eslint-plugin-jsx-a11y';
import reactPlugin from 'eslint-plugin-react';
import reactHooksPlugin from 'eslint-plugin-react-hooks';

// Mimic commonjs variables, which are unavailable in mjs.
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Create the converter; nothing's converted at this point.
const compat = new FlatCompat({
  baseDirectory: __dirname,
});

/**
 * @type {import('eslint').Linter.Config}
 */
const config = defineConfig([
  globalIgnores(['node_modules/', '.next/', 'out/', '**/*.config.{js,mjs}']),
  // Previously: "airbnb"
  //
  // Convert the old eslintrc config
  ...compat.extends('eslint-config-airbnb'),
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
      //
      // Already applied in "airbnb".
      // importPlugin.flatConfigs.errors,

      // Previously: "plugin:import/warnings"
      //
      // Already applied in "airbnb".
      // importPlugin.flatConfigs.warnings,

      // Previously: "plugin:import/typescript"
      importPlugin.flatConfigs.typescript,

      // Previously: "plugin:jsx-a11y/recommended"
      //
      // Already applied in "airbnb".
      // jsxA11yPlugin.flatConfigs.recommended,

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
      // "eslint" rules:

      // Reduce the number of "if"s to reduce code complexity.
      complexity: 'error',

      /** @deprecated */
      'global-require': 'off',

      /** @deprecated */
      'lines-around-directive': 'off',

      /** @deprecated */
      'lines-between-class-members': 'off',

      /** @deprecated */
      'no-buffer-constructor': 'off',

      /** @deprecated */
      'no-new-object': 'off',

      /** @deprecated */
      'no-new-require': 'off',

      // Allow defaults on component props.
      'no-param-reassign': [
        'error',
        {
          props: false,
        },
      ],

      /** @deprecated */
      'no-path-concat': 'off',

      /** @deprecated */
      'no-return-await': 'off',

      // Allow template curly in regular strings for "yup" schemas.
      'no-template-curly-in-string': 'off',

      /** @deprecated */
      'spaced-comment': 'off',

      // "@typescript-eslint" rules:

      // Ignore unused rest or spread (...) siblings.
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          caughtErrors: 'none',
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

      // "react" rules:

      // Use arrow functions when declaring components.
      'react/function-component-definition': [
        'error',
        {
          namedComponents: 'arrow-function',
        },
      ],

      // Ensure regular scripts can't use jsx.
      'react/jsx-filename-extension': [
        'error',
        {
          extensions: ['.tsx'],
        },
      ],

      // Allow props spreading; mostly for spreading slotProps.
      'react/jsx-props-no-spreading': 'off',

      // React v19 removed `propTypes`.
      'react/prop-types': 'off',

      // Don't enforce "import React..." when using jsx.
      'react/react-in-jsx-scope': 'off',

      // React v19 removed `defaultProps`.
      'react/require-default-props': 'off',
    },

    settings: {
      react: {
        version: 'detect',
      },
    },
  },
]);

export default config;
