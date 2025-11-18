// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import React from "react";

export default function TabbedResults({
  activeTab,
  onChange,
  tabs,
  showTooltips = true,
}) {
  const suitooltip = "Search results from the official Sui Docs";
  const suinstooltip = "Search results from Sui Name Service";
  const movetooltip = "Search results from The Move Book";
  const dapptooltip = "Search results from the Sui ecosystem SDKs";
  const walrustooltip =
    "Search results from the Walrus decentralized storage platform";
  return (
    <div className="mb-4 flex justify-start border-2 border-solid border-transparent rounded-t-lg border-b-suins-gray-50 dark:border-b-suins-white-30">
      {tabs.map(({ label, indexName, count }) => (
        <div className="relative group inline-block" key={indexName}>
          <button
            className={`mr-4 flex items-center font-semibold text-sm lg:text-md xl:text-lg bg-[var(--ifm-background-color)] cursor-pointer dark:text-suins-white-80 ${activeTab === indexName ? "text-suins-gray-80 font-bold border-2 border-solid border-transparent border-b-suins-link-hover dark:border-b-suins-link" : "border-transparent text-suins-grey-40"}`}
            onClick={() => onChange(indexName)}
          >
            {label}{" "}
            <span
              className={`dark:text-suins-white-80 text-xs rounded-full ml-1 py-1 px-2 border border-solid ${activeTab === indexName ? "dark:!text-suins-green bg-transparent border-suins-gray-80 dark:border-suins-white-80" : "bg-suins-gray-10 dark:bg-suins-white-30 border-transparent"}`}
            >
              {count}
            </span>
          </button>
          {showTooltips && (
            <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-max max-w-xs px-2 py-1 text-sm text-white bg-gray-800 rounded tooltip-delay">
              {label === "Sui"
                ? suitooltip
                : label === "SuiNS"
                  ? suinstooltip
                  : label === "The Move Book"
                    ? movetooltip
                    : label === "SDKs"
                      ? dapptooltip
                      : walrustooltip}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
