// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it } from 'vitest';

import { e2eLiveNetworkDryRunFlow } from './pre-built';

describe('it should work on live networks', () => {
	it('should work on mainnet', async () => {
		const res = await e2eLiveNetworkDryRunFlow('mainnet');
		expect(res.effects.status.status).toEqual('success');
	});

	it('should work on testnet', async () => {
		const res = await e2eLiveNetworkDryRunFlow('testnet');
		expect(res.effects.status.status).toEqual('success');
	});
});
