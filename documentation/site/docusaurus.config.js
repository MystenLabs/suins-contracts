// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import {themes as prismThemes} from "prism-react-renderer";
import remarkGlossary from "./src/plugins/remark-glossary.js";

import path from "path";
import { fileURLToPath } from "url";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// This runs in Node.js - Don"t use client-side code here (browser APIs, JSX...)

/** @type {import("@docusaurus/types").Config} */
const config = {
  title: "SuiNS Documentation",
  tagline: "Own your identity",
  favicon: "img/favicon.png",

  // Set the production url of your site here
  url: "https://docs.suins.com",
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often "/<projectName>/"
  baseUrl: "/",

  // GitHub pages deployment config.
  // If you aren"t using GitHub pages, you don"t need these.
  organizationName: "mystenlabs", // Usually your GitHub org/user name.
  projectName: "suins-contracts", // Usually your repo name.

  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",

  // Even if you don"t use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },
  headTags: [
    {
      tagName: "meta",
      attributes: {
        name: "algolia-site-verification",
        content: "BCA21DA2879818D2",
      },
    },
  ],
  plugins: [
    "docusaurus-plugin-copy-page-button",
    function docsAliasPlugin() {
      return {
        name: "docs-alias-plugin",
        configureWebpack() {
          return {
            resolve: {
              alias: {
                "@docs": path.resolve(__dirname, "../content"),
              },
            },
          };
        },
      };
    },
  ],
  presets: [
    [
      "classic",
      /** @type {import("@docusaurus/preset-classic").Options} */
      ({
        docs: {
          path: "../content",
          routeBasePath: "/",
          sidebarPath: "./sidebars.js",
          editUrl:
            "https://github.com/MystenLabs/suins-contracts/tree/main/documentation/",
          remarkPlugins: [[remarkGlossary, { glossaryFile: "static/glossary.json" }]],
        },
        theme: {
          customCss: path.resolve(__dirname, "./src/css/custom.css"),
        },
      }),
    ],
  ],
  markdown: {
    format: "mdx",
    mermaid: true,
    preprocessor: ({filePath, fileContent}) => {
      return fileContent.replaceAll("{{MY_VAR}}", "MY_VALUE");
    },
    parseFrontMatter: async (params) => {
      const result = await params.defaultParseFrontMatter(params);
      result.frontMatter.description =
        result.frontMatter.description?.replaceAll("{{MY_VAR}}", "MY_VALUE");
      return result;
    },
    mdx1Compat: {
      comments: true,
      admonitions: true,
      headingIds: true,
    },
    anchors: {
      maintainCase: true,
    },
  },

  themeConfig:
    /** @type {import("@docusaurus/preset-classic").ThemeConfig} */
    ({
      navbar: {
        title: "SuiNS Docs",
        logo: {
          alt: "SuiNS Logo",
          src: "img/logo.svg",
          srcDark: "img/logodark.svg",
        },
        items: [
          
          {
            type: "docSidebar",
            sidebarId: "nsSidebar",
            position: "right",
            label: "SuiNS",
          },
          /*{
            type: "docSidebar",
            sidebarId: "communitySidebar",
            position: "right",
            label: "Communities",
          },*/
          {
            type: "docSidebar",
            sidebarId: "mvrSidebar",
            position: "right",
            label: "MVR",
          },
          {
            label: "SuiNS Dashboard",
            href: "https://suins.io",   // ← external link
            position: "right",
          },
        ],
      },
      footer: {
        style: "dark",
        copyright: `Copyright © ${new Date().getFullYear()} SuiNS Foundation.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),
  customFields: {
    pushFeedbackId: 'j035k7w3r9',
  },
};

export default config;
