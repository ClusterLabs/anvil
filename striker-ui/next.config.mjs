export default () => {
  /**
   * @type {import('next').NextConfig}
   */
  const config = {
    distDir: 'out',
    output: 'export',
    pageExtensions: ['ts', 'tsx'],
    poweredByHeader: false,
    reactStrictMode: true,
  };

  return config;
};
