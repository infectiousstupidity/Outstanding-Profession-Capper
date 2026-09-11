# Task 03 — TSM AuctionDB integration

Status: QUEUED  
Phase: 1 — Character and price foundations  
Depends on: Task 02

## Goal

Use locally available TSM / AuctionDB data from the player's 3.3.5 client as the first dynamic price source.

## Required behavior

Detect compatible TSM/AuctionDB globals at runtime without making TSM a hard dependency.

Read, where the installed version supports it:

- current/minimum buyout
- DB market/historical value
- last scan/update time

Return those values through the Task 02 provider interface.

## Price selection rules

- Prefer current minimum buyout for "gold needed now" when fresh.
- Keep DB market as a sanity/reference value.
- Flag suspicious current prices when minimum buyout is far from market value; do not silently rewrite the raw source values.
- Mark stale scan data clearly.
- Do not claim that minimum buyout multiplied by quantity is exact market depth.

## Compatibility

TSM API/global differences between 3.3.5 builds must be feature-detected. Do not assume one modern Retail TSM API.

If no compatible API is found, fall back cleanly to the null provider.

## Acceptance criteria

- Addon loads with TSM absent.
- Addon loads with supported TSM/AuctionDB present.
- Known item prices can be retrieved through the neutral provider.
- Scan age is available when the installed AuctionDB exposes it.
- Bad/missing TSM values do not crash route calculations.

## Manual checks

Record the installed TSM/AuctionDB version used for testing and sample values for at least three materials.

## Commit

Suggested message: `feat: integrate local TSM AuctionDB pricing`
