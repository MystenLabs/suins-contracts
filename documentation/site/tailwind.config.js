// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/** @type {import("@tailwindcss/postcss").Config} */

module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx, md, mdx}",
    "./components/**/*.{js,ts,jsx,tsx, md, mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        blurple: "rgb(var(--suins-blurple) / <alpha-value>)",
        blurpleDark: "rgb(var(--suins-blurple-dark) / <alpha-value>)",
      }
    },
  },

}

