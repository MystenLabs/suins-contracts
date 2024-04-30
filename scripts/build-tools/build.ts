// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
import { execSync } from 'child_process';
import { existsSync, promises as fs } from 'fs';
import * as path from 'path';
import type { BuildOptions } from 'esbuild';
import { build } from 'esbuild';

interface PackageJSON {
	name?: string;
	type?: 'module' | 'commonjs';
	exports?: Record<string, string | Record<string, string>>;
	files?: string[];
	types?: string;
	import?: string;
	main?: string;
	private?: boolean;
	sideEffects?: boolean;
}

const ignorePatterns = [/\.test.ts$/, /\.graphql$/];

const SRC = path.resolve(`${__dirname}/../../sdk/`);

export async function buildPackage(buildOptions?: BuildOptions) {
	const allFiles = await findAllFiles(path.join(SRC, 'src'));
	const packageJson = await readPackageJson();
	await clean();
	await buildCJS(allFiles, packageJson, buildOptions);
	await buildESM(allFiles, packageJson, buildOptions);
	// await buildImportDirectories(packageJson);
}

async function clean() {
	await createEmptyDir(path.join(SRC, 'dist'));
}

async function buildCJS(
	entryPoints: string[],
	{ sideEffects }: PackageJSON,
	buildOptions?: BuildOptions,
) {
	await build({
		format: 'cjs',
		logLevel: 'error',
		target: 'es2020',
		entryPoints,
		outdir: path.resolve(SRC + '/dist/cjs'),
		sourcemap: true,
		...buildOptions,
	});
	await buildTypes('tsconfig.json');

	const pkg: PackageJSON = {
		private: true,
		type: 'commonjs',
	};

	if (sideEffects === false) {
		pkg.sideEffects = false;
	}

	await fs.writeFile(path.join(SRC, 'dist/cjs/package.json'), JSON.stringify(pkg, null, 2));
}

async function buildESM(
	entryPoints: string[],
	{ sideEffects }: PackageJSON,
	buildOptions?: BuildOptions,
) {
	await build({
		format: 'esm',
		logLevel: 'error',
		target: 'es2020',
		entryPoints,
		outdir: path.resolve(SRC + '/dist/esm'),
		sourcemap: true,

		...buildOptions,
	});

	await buildTypes('tsconfig.esm.json');

	const pkg: PackageJSON = {
		private: true,
		type: 'module',
	};

	if (sideEffects === false) {
		pkg.sideEffects = false;
	}

	await fs.writeFile(path.join(SRC, 'dist/esm/package.json'), JSON.stringify(pkg, null, 2));
}

async function buildTypes(config: string) {
	execSync(`pnpm tsc --build ${config}`, {
		stdio: 'inherit',
		cwd: SRC,
	});
}

async function findAllFiles(dir: string, files: string[] = []) {
	const dirFiles = await fs.readdir(dir);
	for (const file of dirFiles) {
		const filePath = path.join(dir, file);
		const fileStat = await fs.stat(filePath);
		if (fileStat.isDirectory()) {
			await findAllFiles(filePath, files);
		} else if (!ignorePatterns.some((pattern) => pattern.test(filePath))) {
			files.push(filePath);
		}
	}
	return files;
}

async function createEmptyDir(path: string) {
	if (existsSync(path)) {
		await fs.rm(path, { recursive: true });
	}

	await fs.mkdir(path, { recursive: true });
}

async function readPackageJson() {
	return JSON.parse(await fs.readFile(path.join(SRC, 'package.json'), 'utf-8')) as PackageJSON;
}

buildPackage();
