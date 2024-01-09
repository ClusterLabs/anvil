const path = require('path');

module.exports = {
  entry: './src/index.ts',
  mode: 'production',
  module: {
    rules: [
      {
        exclude: /node_modules/,
        test: /\.ts$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              ['@babel/preset-env', { corejs: 3, useBuiltIns: 'usage' }],
              '@babel/preset-typescript',
            ],
          },
        },
      },
    ],
  },
  optimization: {
    minimize: true,
  },
  output: {
    clean: true,
    filename: 'index.js',
    path: path.resolve(__dirname, 'out'),
  },
  resolve: {
    extensions: ['.js', '.ts'],
  },
  stats: 'detailed',
  target: ['node10', 'node16'],
};
