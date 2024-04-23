/** @type {import("tailwindcss").Config} */
//let colors = require("tailwindcss/colors");

//delete colors.lightBlue;
//delete colors.warmGray;
//delete colors.trueGray;
//delete colors.coolGray;
//delete colors.blueGray;

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

