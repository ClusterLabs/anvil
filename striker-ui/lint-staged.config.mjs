/**
 * @type {import('lint-staged').Configuration}
 */
const config = {
  '!(out/**/*)*.{js,jsx,ts,tsx}': [
    'npm run eslint:base -- --fix',
    'prettier --write',
  ],
  '!(out/**/*)*.{json,md,mjs}': 'prettier --write',
};

export default config;
