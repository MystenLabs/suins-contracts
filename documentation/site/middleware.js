import { next } from "@vercel/edge";

export default function middleware(request) {
  const accept = request.headers.get("accept") || "";
  const url = new URL(request.url);
  const pathname = url.pathname;

  // Content negotiation: serve markdown when Accept: text/markdown
  if (
    accept.includes("text/markdown") &&
    !pathname.startsWith("/markdown/") &&
    !pathname.startsWith("/_next/") &&
    !pathname.endsWith(".md") &&
    !pathname.includes(".")
  ) {
    // Rewrite to the markdown file
    url.pathname = `/markdown${pathname}.md`;
    return fetch(url, {
      headers: request.headers,
      redirect: "manual",
    });
  }

  return next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon|img|fonts).*)"],
};
