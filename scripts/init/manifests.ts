// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
export const SuiNS = (rev: string) => (packageId?: string) => `[package]
name = "suins"
version = "0.0.1"
edition = "2024.beta"
${packageId ? `published-at = "${packageId}"` : ''}

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "${rev}" }

[addresses]
suins = "${packageId || '0x0'}"`;

export const SuiNSDependentPackages =
	(rev: string, name: string, extraDependencies?: string) => (packageId?: string) => `[package]
name = "${name}"
version = "0.0.1"
edition = "2024.beta"
${packageId ? `published-at = "${packageId}"` : ''}

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "${rev}", override=true }
suins = { local = "../suins" }
${extraDependencies || ''}

[addresses]
${name} = "${packageId || '0x0'}"`;

export const TempSubdomainProxy = (rev: string) => (packageId?: string) => `[package]
name = "temp_subdomain_proxy"
version = "0.0.1"
edition = "2024.beta"
${packageId ? `published-at = "${packageId}"` : ''}

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "${rev}", override=true }
subdomains = { local = "../subdomains" }
utils = { local = "../utils" }

[addresses]
temp_subdomain_proxy = "${packageId || '0x0'}"
`;
