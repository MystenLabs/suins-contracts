// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
export const SuiNS = (rev: string) => (packageId?: string) => `[package]
name = "suins"
version = "0.0.1"
edition = "2024.beta"
${packageId ? `published-at = "${packageId}"` : ''}

[dependencies]

[addresses]
suins = "${packageId || '0x0'}"`;

export const SuiNSDependentPackages =
	(rev: string, name: string, extraDependencies?: string) => (packageId?: string) => `[package]
name = "${name}"
version = "0.0.1"
edition = "2024.beta"
${packageId ? `published-at = "${packageId}"` : ''}

[dependencies]
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
suins_subdomains = { local = "../subdomains" }
suins = { local = "../suins" }

[addresses]
temp_subdomain_proxy = "${packageId || '0x0'}"
suins_temp_subdomain_proxy = "${packageId || '0x0'}"
`;
