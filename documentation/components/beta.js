// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import React from 'react';
import { useRouter } from 'next/router';

const Beta = () => {
  const location = useRouter();
  const isLanding = location.asPath === "/move-registry";
	return (
    <>
    { isLanding &&
      <div className="mt-6">
        <p className="nx-mt-6 nx-leading-7 first:nx-mt-0">The main point of failure MVR users need to be aware of is the experimental indexer backing the registry. Whether you run your own instance of the MVR indexer or use the Mysten Lab operated public good indexer, there is always risk that the service is not available, so build your application accordingly.</p>
        <p className="nx-mt-6 nx-leading-7 first:nx-mt-0">
          Read the documentation to learn how to:
        </p>
        <ul className="nx-mt-4 nx-ml-6">
          <li>Use a fallback address in your TypeScript to account for situations when MVR might not be available.</li>
          <li>Structure your application so it's easier to maintain uptime in the face of MVR outages.</li>
          <li>Take additional steps to de-risk using MVR.</li>
        </ul>
      </div> }
    </>
	);
};

export default Beta;
