import { terser } from 'rollup-plugin-terser';

export default {
	input: 'src/index.js',
	output: {
		file: 'dist/canvas-helper.min.js',
		format: 'umd',
		name: 'CH',
	},
	plugins: [terser()],
};
