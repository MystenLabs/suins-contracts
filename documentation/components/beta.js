// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import React from 'react';
import { useRouter } from 'next/router';
import { Callout } from 'nextra/components';

const Beta = () => {
  const location = useRouter();
  const isLanding = location.asPath === "/move-registry";
	return (
    <>
		<Callout type="error" emoji="👀">
			This is a developer preview of the Move Registry. It is experimental and therefore provides no
			guarantees of uptime or correctness. Use at your own risk.
		</Callout>
    { isLanding && 
      <div className="mt-6">
        <p className="nx-mt-6 nx-leading-7 first:nx-mt-0">The main point of failure MVR users need to be aware of is the experimental indexer backing the registry. Whether you run your own instance of the MVR indexer or use the Mysten Lab operated public good indexer, there is always risk that the service is not available, so build your application accordingly.</p>
        <p className="nx-mt-6 nx-leading-7 first:nx-mt-0 hidden">
        Here's how you (can use a fallback address in your typescript to easily fall back to not using MVR / should structure your application so it's easy to maintain uptime in the face of MVR outage / however else users can de-risk using MVR) 
        </p>
      </div> }
    </>
	);
};

export default Beta;
