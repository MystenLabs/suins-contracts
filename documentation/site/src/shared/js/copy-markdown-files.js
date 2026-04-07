// Copyright (c) Walrus Foundation
// SPDX-License-Identifier: Apache-2.0

const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');

const contentDir = path.join(__dirname, '../../../../content');
const outputDir = path.join(__dirname, '../../../static/markdown');
const baseUrl = 'https://docs.suins.io';
const llmsTxtDirective = `> For the complete documentation index, see [llms.txt](${baseUrl}/llms.txt)\n\n`;

/**
 * Strips frontmatter and cleans MDX/JSX components from markdown
 */
function stripFrontmatter(content) {
  const { content: markdownContent } = matter(content);
  return cleanMdxComponents(markdownContent);
}

/**
 * Removes or simplifies MDX/JSX components for cleaner markdown
 */
function cleanMdxComponents(content) {
  let cleaned = content;

  // Remove import statements
  cleaned = cleaned.replace(/^import\s+.*?from\s+['"].*?['"];?\s*$/gm, '');

  // Convert Card components to markdown links
  cleaned = cleaned.replace(/<Card[^>]*title="([^"]*)"[^>]*href="([^"]*)"[^>]*\/>/g, '- [$1]($2)');

  // Remove Cards wrapper
  cleaned = cleaned.replace(/<Cards[^>]*>/g, '');
  cleaned = cleaned.replace(/<\/Cards>/g, '');

  // Remove other common JSX components but keep their content
  cleaned = cleaned.replace(/<(\w+)[^>]*>(.*?)<\/\1>/gs, '$2');

  // Remove self-closing JSX tags
  cleaned = cleaned.replace(/<\w+[^>]*\/>/g, '');

  // Clean up excessive newlines
  cleaned = cleaned.replace(/\n{3,}/g, '\n\n');

  return cleaned.trim();
}

/**
 * Recursively copies markdown files from content dir to static dir as .md files,
 * so they are served alongside the Docusaurus routes.
 *
 * content/node-operator.mdx  → static/node-operator.md  → served at /node-operator.md
 * content/suins/overview.mdx → static/suins/overview.md → served at /suins/overview.md
 * content/suins/index.mdx    → static/suins/index.md    → served at /suins/index.md
 */
function copyMarkdownFiles(dir, baseDir = dir) {
  const files = fs.readdirSync(dir);

  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      copyMarkdownFiles(filePath, baseDir);
    } else if (file.endsWith('.md') || file.endsWith('.mdx')) {
      const content = fs.readFileSync(filePath, 'utf8');
      const cleanContent = stripFrontmatter(content);

      // Insert llms.txt directive at the top of the file
      const outputContent = llmsTxtDirective + cleanContent;

      // Preserve directory structure, normalize to .md extension
      const relativePath = path.relative(baseDir, filePath);
      const outputPath = path.join(outputDir, relativePath.replace(/\.mdx?$/, '.md'));

      fs.mkdirSync(path.dirname(outputPath), { recursive: true });
      fs.writeFileSync(outputPath, outputContent, 'utf8');
      console.log(`✓ Copied: ${relativePath} → ${path.relative(outputDir, outputPath)}`);
    }
  });
}

console.log('📝 Starting markdown export...');
console.log(`Source: ${contentDir}`);
console.log(`Output: ${outputDir}\n`);

// Copy all markdown files
copyMarkdownFiles(contentDir);

console.log('\n✅ Markdown files exported successfully');