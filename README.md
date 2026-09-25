# eAM load builder

A single-file browser tool for building Oracle eAM conversion data in the standard template layout, with every row checked as it is typed, pasted or imported.

Author: Joey McDougal, eAM Director

## Run it

**Online:** https://mcdougaj.github.io/eam-load-builder/ — nothing to install.

Or open `index.html` in Chrome or Edge. No install or server is needed. An internet connection is used for the spreadsheet library and fonts.

## What it does

- 31 template sheets in Oracle load order: foundation, attributes, failure analysis, meters, routes, activities and preventive maintenance
- Live checks: required fields, lengths, formats, links between sheets, duplicates and completeness
- Reference lists of valid Oracle values, scoped by organization
- "Already in Oracle" flag for records that exist but are not reloaded
- Cleaning and text rules: spacing, dates, Y/N, abbreviations, code case, repeated words
- Summary of findings page
- Ask panel: AI reads the data and proposes changes for review (claude.ai, or a provider set in AI settings)
- Exports: working workbook (full round trip), loader workbook, CSV and issue log

## Data

Files are read and checked in the browser; nothing is uploaded. Work autosaves to the browser only, so export a working workbook to keep a copy. API keys entered in AI settings stay in the browser and are never written to exported files.

## User guide

https://mcdougaj.github.io/eam-load-builder/guide/ — building workbooks, and loading them into Oracle with joeyi DataFlow Pro.
