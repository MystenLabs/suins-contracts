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
 * Checks if a markdown file should be skipped (draft or redirect)
 */
function shouldSkip(content) {
  const { data } = matter(content);
  if (data.draft === true) return true;
  if (typeof data.title === 'string' && data.title.startsWith('Redirecting')) return true;
  if (data.sidebar_class_name === 'hidden') return true;
  return false;
}

/**
 * Strips frontmatter and cleans MDX/JSX components from markdown
 */
function stripFrontmatter(content) {
  const { content: markdownContent } = matter(content);
  return cleanMdxComponents(markdownContent);
}

/**
 * Removes or simplifies MDX/JSX components for cleaner markdown.
 * Protects fenced code blocks from being modified.
 */
function cleanMdxComponents(content) {
  let cleaned = content;

  // ── Protect code blocks from JSX cleaning ──────────────────────────────
  const codeBlocks = [];
  cleaned = cleaned.replace(/```[\s\S]*?```/g, match => {
    codeBlocks.push(match);
    return `__CODE_BLOCK_${codeBlocks.length - 1}__`;
  });
  cleaned = cleaned.replace(/`[^`\n]+`/g, match => {
    codeBlocks.push(match);
    return `__CODE_BLOCK_${codeBlocks.length - 1}__`;
  });

  // ── Remove import statements ───────────────────────────────────────────
  cleaned = cleaned.replace(/^import\s+.*?from\s+['"].*?['"];?\s*$/gm, '');

  // ── Convert Card components to markdown links ──────────────────────────
  cleaned = cleaned.replace(
    /<Card[^>]*title="([^"]*)"[^>]*href="([^"]*)"[^>]*\/>/g,
    '- [$1]($2)',
  );
  cleaned = cleaned.replace(/<Cards[^>]*>/g, '');
  cleaned = cleaned.replace(/<\/Cards>/g, '');

  // ── Convert Docusaurus admonitions to blockquotes ──────────────────────
  cleaned = cleaned.replace(
    /^:::(tip|info|warning|danger|note|caution)(?:[ \t]+(.+))?\s*\n([\s\S]*?)^:::\s*$/gm,
    (_match, type, title, body) => {
      const label = type.charAt(0).toUpperCase() + type.slice(1);
      const header = title ? title.trim() : label;
      const lines = body
        .trim()
        .split('\n')
        .map(l => `> ${l}`)
        .join('\n');
      return `> **${header}**\n>\n${lines}`;
    },
  );

  // ── Convert <a> tags to markdown links before generic stripping ────────
  cleaned = cleaned.replace(
    /<a\s+href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/g,
    '[$2]($1)',
  );

  // ── Remove paired JSX/HTML tags, keep content (loop for nesting) ───────
  let prev;
  do {
    prev = cleaned;
    cleaned = cleaned.replace(/<(\w+)[^>]*>([\s\S]*?)<\/\1>/g, '$2');
  } while (cleaned !== prev);

  // ── Remove remaining self-closing JSX/HTML tags ────────────────────────
  cleaned = cleaned.replace(/<\w+[^>]*\/>/g, '');

  // ── Remove JSX expression comments ─────────────────────────────────────
  cleaned = cleaned.replace(/\{\/\*[\s\S]*?\*\/\}/g, '');

  // ── Restore code blocks ────────────────────────────────────────────────
  cleaned = cleaned.replace(/__CODE_BLOCK_(\d+)__/g, (_match, idx) => codeBlocks[parseInt(idx)]);

  // ── Clean up excessive newlines ────────────────────────────────────────
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

      if (shouldSkip(content)) {
        const relativePath = path.relative(baseDir, filePath);
        console.log(`  ⏭ Skipped: ${relativePath}`);
        return;
      }

      const cleanContent = stripFrontmatter(content);

      if (!cleanContent.trim()) {
        const relativePath = path.relative(baseDir, filePath);
        console.log(`  ⏭ Skipped (empty): ${relativePath}`);
        return;
      }

      // Insert llms.txt directive at the top of the file
      const outputContent = llmsTxtDirective + cleanContent;

      // Preserve directory structure, normalize to .md extension
      const relativePath = path.relative(baseDir, filePath);
      const outputPath = path.join(outputDir, relativePath.replace(/\.mdx?$/, '.md'));

      fs.mkdirSync(path.dirname(outputPath), { recursive: true });
      fs.writeFileSync(outputPath, outputContent, 'utf8');
      console.log(`  ✔ Copied: ${relativePath}`);
    }
  });
}

console.log('📝 Starting markdown export...');
console.log(`Source: ${contentDir}`);
console.log(`Output: ${outputDir}\n`);

// Clean and recreate output directory
if (fs.existsSync(outputDir)) {
  fs.rmSync(outputDir, { recursive: true });
}
fs.mkdirSync(outputDir, { recursive: true });

// Copy all markdown files
copyMarkdownFiles(contentDir);

console.log('\n✅ Markdown files exported successfully');
