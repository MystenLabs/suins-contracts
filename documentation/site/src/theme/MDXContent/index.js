import React from "react";
import { MDXProvider } from "@mdx-js/react";
import MDXComponents from "@theme/MDXComponents";
import Link from "@docusaurus/Link";
import Term from "../../components/Glossary/Term";
import ImportContent from "@site/src/components/ImportContent";
import Tabs from "@theme/Tabs";
import TabItem from "@theme/TabItem";
import Video from "../../components/Video";
import AgentPrompt from "@site/src/shared/components/AgentPrompt";

export default function MDXContent({ children }) {
  const suiComponents = {
    ...MDXComponents,
    Link,
    Term,
    ImportContent,
    Tabs,
    TabItem,
    Video,
    AgentPrompt,
  };
  return <MDXProvider components={suiComponents}>{children}</MDXProvider>;
}
