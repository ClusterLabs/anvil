const path = require('path');

module.exports = {
  entry: './index.js',
  mode: 'production',
  module: {
    rules: [
      {
        exclude: /node_modules/,
        test: /\.m?js$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
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
  stats: 'detailed',
  target: 'node10',
};
