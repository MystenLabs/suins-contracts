// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module.exports = {
	plugins: ['unused-imports', 'prettier', 'header', 'require-extensions'],
	extends: [
		'eslint:recommended',
		'prettier',
		'plugin:prettier/recommended',
		'plugin:import/typescript',
	],
	settings: {
		'import/resolver': {
			typescript: true,
		},
	},
	env: {
		es2020: true,
		node: true,
	},
	root: true,
	ignorePatterns: [
		'node_modules',
		'build',
		'dist',
		'coverage',
		'apps/icons/src',
		'next-env.d.ts',
		'doc/book',
		'external-crates',
		'storybook-static',
		'.next',
	],
	rules: {
		'no-case-declarations': 'off',
		'no-implicit-coercion': [2, { number: true, string: true, boolean: false }],
		'@typescript-eslint/no-redeclare': 'off',
		'@typescript-eslint/ban-types': [
			'error',
			{
				types: {
					Buffer: 'Buffer usage increases bundle size and is not consistently implemented on web.',
				},
				extendDefaults: true,
			},
		],
		'no-restricted-globals': [
			'error',
			{
				name: 'Buffer',
				message: 'Buffer usage increases bundle size and is not consistently implemented on web.',
			},
		],
		'header/header': [
			2,
			'line',
			[' Copyright (c) Mysten Labs, Inc.', ' SPDX-License-Identifier: Apache-2.0'],
		],
		'@typescript-eslint/no-unused-vars': [
			'error',
			{
				argsIgnorePattern: '^_',
				varsIgnorePattern: '^_',
				vars: 'all',
				args: 'none',
				ignoreRestSiblings: true,
			},
		],
		'require-extensions/require-extensions': 'error',
		'require-extensions/require-index': 'error',
		'@typescript-eslint/consistent-type-imports': ['error'],
		'import/consistent-type-specifier-style': ['error', 'prefer-top-level'],
		'import/no-cycle': ['error'],
	},
};
