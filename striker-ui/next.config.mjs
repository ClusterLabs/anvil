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
    webpack: (config, { isServer }) => {
      config.experiments = {
        ...config.experiments,
        // Make builds work with novnc >= v1.6.0.
        topLevelAwait: true,
      };

      if (!isServer) {
        config.output.environment = {
          ...config.output.environment,
          // Stop non-async environment warning.
          asyncFunction: true,
        };
      }

      return config;
    },
  };

  return config;
};
