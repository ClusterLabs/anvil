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
            presets: ['@babel/preset-env', '@babel/preset-typescript'],
          },
        },
      },
    ],
  },
  optimization: {
    minimize: true,
  },
  output: {
    path: path.resolve(__dirname, 'out'),
    filename: 'index.js',
  },
  resolve: {
    extensions: ['.js', '.ts'],
  },
  stats: 'detailed',
  target: 'node10',
};
