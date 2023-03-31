const path = require('path');

module.exports = {
	mode: 'development',
	context: path.resolve(__dirname, 'src'),
	devtool: 'source-map',
	entry: {
		main: './index.ts'
	},
	target: 'node',
	module: {
		rules: [
			{
				test: /\.tsx?$/,
				use: 'ts-loader',
				exclude: /node_modules/
			}
		]
	},
	resolve: {
		extensions: ['.ts', '.js', '.tsx', '.jsx']
	},
	output: {
		filename: 'index.js',
		path: path.resolve(__dirname, 'dist')
	},
	plugins: []
};
