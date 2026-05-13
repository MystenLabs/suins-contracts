// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import React, { useState, useEffect } from "react";
import { liteClient as algoliasearch } from "algoliasearch/lite";
import {
  InstantSearch,
  useInfiniteHits,
  useInstantSearch,
  Index,
} from "react-instantsearch";
import { truncateAtWord, getDeepestHierarchyLabel, getHierarchyBreadcrumbs, cleanTooltipText } from "./utils";
import ControlledSearchBox from "./ControlledSearchBox";
import TabbedResults from "./TabbedResults";

const baseSearchClient = algoliasearch(
  "M9JD2UP87M",
  "826134b026a63bb35692f08f1dc85d1c",
);

const searchClient = {
  ...baseSearchClient,
  search(requests: any[]) {
    const hasValidQuery = requests.some(
      (req) => req.params?.query?.length >= 3,
    );
    if (!hasValidQuery) {
      return Promise.resolve({
        results: requests.map(() => ({
          hits: [],
          nbHits: 0,
          processingTimeMS: 0,
        })),
      });
    }
    return baseSearchClient.search(requests);
  },
};

const indices = [
  { label: "SuiNS", indexName: "suins_docs" },
  { label: "Sui", indexName: "sui_docs" },
  { label: "The Move Book", indexName: "move_book" },
  { label: "SDKs", indexName: "sui_sdks" },
  { label: "Walrus", indexName: "walrus_docs" },
];

function HitItem({ hit }: { hit: any }) {
  const crumbs = getHierarchyBreadcrumbs(hit.hierarchy);
  const title = crumbs.length > 0 ? crumbs[crumbs.length - 1] : cleanTooltipText(hit.hierarchy?.lvl0 || "Untitled");
  const breadcrumb = crumbs.length > 1 ? crumbs.slice(0, -1) : [];

  return (
    <a
      href={hit.url}
      className="modal-result block px-4 py-3 -mx-2 rounded-lg no-underline hover:bg-suins-gray-5 dark:hover:bg-suins-white-10 transition-colors"
    >
      {breadcrumb.length > 0 && (
        <div className="text-xs text-suins-gray-50 dark:text-suins-gray-50 mb-1 truncate">
          {breadcrumb.join(" > ")}
        </div>
      )}
      <div className="text-sm font-medium text-gray-900 dark:text-white">
        {title}
      </div>
      {hit.content && (
        <p
          className="text-xs text-suins-gray-60 dark:text-suins-white-80 mt-1 mb-0 line-clamp-2"
          dangerouslySetInnerHTML={{
            __html: truncateAtWord(hit._highlightResult.content.value, 120),
          }}
        />
      )}
    </a>
  );
}

function HitsList({
  scrollContainerRef,
}: {
  scrollContainerRef: React.RefObject<HTMLDivElement>;
}) {
  const { hits, isLastPage, showMore } = useInfiniteHits();

  useEffect(() => {
    const el = scrollContainerRef.current;
    if (!el) return;

    const handleScroll = () => {
      const atBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - 1;
      if (atBottom && !isLastPage) {
        showMore();
      }
    };

    el.addEventListener("scroll", handleScroll);
    return () => el.removeEventListener("scroll", handleScroll);
  }, [isLastPage, showMore, scrollContainerRef]);

  return (
    <div>
      {hits.map((hit) => (
        <HitItem key={hit.objectID} hit={hit} />
      ))}
    </div>
  );
}

function EmptyState({ label }: { label: string }) {
  const { results } = useInstantSearch();
  if (results?.hits?.length === 0) {
    return (
      <p className="text-sm text-suins-gray-50 dark:text-suins-gray-50">
        No results in {label}
      </p>
    );
  }
  return null;
}

function ResultsUpdater({
  indexName,
  onUpdate,
}: {
  indexName: string;
  onUpdate: (index: string, count: number) => void;
}) {
  const { results } = useInstantSearch();
  const previousHitsRef = React.useRef<number | null>(null);
  useEffect(() => {
    if (results && results.nbHits !== previousHitsRef.current) {
      previousHitsRef.current = results.nbHits;
      onUpdate(indexName, results.nbHits);
    }
  }, [results?.nbHits, indexName, onUpdate, results]);
  return null;
}

export default function MultiIndexSearchModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const [activeIndex, setActiveIndex] = useState(indices[0].indexName);
  const [tabCounts, setTabCounts] = React.useState<Record<string, number>>({
    walrus_docs: 0,
  });
  const [query, setQuery] = React.useState("");
  const scrollContainerRef = React.useRef<HTMLDivElement>(null);
  const searchBoxRef = React.useRef<HTMLInputElement>(null);
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
      // Focus the search input when modal opens
      setTimeout(() => {
        searchBoxRef.current?.focus();
      }, 300);
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen]);

  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  const activeMeta = {
    suins_docs: null,
    sui_docs: { label: "Sui Docs", url: "https://docs.sui.io" },
    move_book: {
      label: "The Move Book",
      url: "https://move-book.com/",
    },
    sui_sdks: { label: "SDK Docs", url: "https://sdk.mystenlabs.com" },
    walrus_docs: { label: "Walrus Docs", url: "https://docs.wal.app"},
  }[activeIndex];

  if (!isOpen) return null;
  return (
    <div className="fixed inset-0 bg-suins-gray-70 dark:bg-suins-gray-90/80 z-50 flex justify-center items-start pt-[10vh]" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="bg-white dark:bg-[var(--ifm-background-color)] w-full max-w-4xl rounded-lg shadow-md max-h-[600px] flex flex-col">
        <div ref={scrollContainerRef} className="flex-1 overflow-y-auto">
          <InstantSearch searchClient={searchClient} indexName={activeIndex}>
            <div className="bg-white dark:bg-[var(--ifm-background-color)] rounded-t sticky top-0 z-10 px-6">
              <div className="bg-white dark:bg-[var(--ifm-background-color)] h-8 flex justify-end">
                <button
                  onClick={onClose}
                  className="bg-transparent border-none outline-none text-xs text-suins-gray-50 hover:text-suins-gray-60 cursor-pointer"
                >
                  ESC
                </button>
              </div>
              <ControlledSearchBox
                placeholder={`Search`}
                query={query}
                onChange={setQuery}
                inputRef={searchBoxRef}
              />
              {query.length < 3 && (
                <p className="text-xs text-suins-gray-50 dark:text-suins-gray-50 pl-4 mb-2 -mt-6">
                  Type at least 3 characters to search
                </p>
              )}
              <TabbedResults
                activeTab={activeIndex}
                onChange={setActiveIndex}
                showTooltips={false}
                tabs={indices.map((tab) => ({
                  ...tab,
                  count: tabCounts[tab.indexName] || 0,
                }))}
              />
            </div>
            <div className="px-6 pb-4">
              {indices.map((index) => (
                <Index indexName={index.indexName} key={index.indexName}>
                  <ResultsUpdater
                    indexName={index.indexName}
                    onUpdate={(indexName, count) =>
                      setTabCounts((prev) => ({ ...prev, [indexName]: count }))
                    }
                  />
                  {index.indexName === activeIndex && (
                    <>
                      <HitsList scrollContainerRef={scrollContainerRef} />
                      <EmptyState label={index.label} />
                    </>
                  )}
                </Index>
              ))}
            </div>
          </InstantSearch>
        </div>
        <div className="h-12 bg-[var(--ifm-background-color)] flex items-center justify-between text-xs border-t border-solid border-suins-gray-50 border-b-transparent border-l-transparent border-r-transparent px-6">
          <a
            href={`/search?q=${encodeURIComponent(query)}`}
            className="wal-link-hover dark:text-suins-link dark:hover:text-suins-green underline"
          >
            View all results
          </a>
          {activeMeta && (
            <a
              href={activeMeta.url}
              target="_blank"
              rel="noopener noreferrer"
              className="text-suins-link dark:text-suins-link-hover dark:hover:text-suins-green underline"
            >
              Visit {activeMeta.label} →
            </a>
          )}
        </div>
      </div>
    </div>
  );
}
