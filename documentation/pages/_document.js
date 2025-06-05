// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { Html, Head, Main, NextScript } from 'next/document'
 
export default function Document() {
  return (
    <Html lang="en">
      <Head>
        <link rel="shortcut icon" href="/favicon.png" />
        <meta name="algolia-site-verification"  content="BCA21DA2879818D2" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  )
}