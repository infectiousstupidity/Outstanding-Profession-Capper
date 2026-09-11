# Task 03 — TSM AuctionDB integration

Status: DONE  
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

## Implementation notes

Implemented:
- Added `TSMPriceProvider.lua` and registered it through the Task 02 provider interface with dynamic runtime availability detection.
- Added optional TOC dependencies on `TradeSkillMaster` and `TradeSkillMaster_AuctionDB`; neither is a hard dependency.
- Prefer TSM's public `TSM_API.GetCustomPriceValue()` for `DBMinBuyout`, `DBMarket`, `DBHistorical`, and `DBRecent` when that API exists.
- Supplement public prices with `TSM_AuctionDB_GetRealmData()` to obtain per-item last-scan timestamp and auction count on the Keoo88/hugetiny 3.3.5 backport.
- Fall back to the raw `TSM_AuctionDB` SavedVariable realm table when the helper API is absent.
- Support legacy numeric AuctionDB records and current v4 table records without mutating TSM data.
- Provider selection is dynamic: if TSM loads after Profession Capper, the provider becomes available on the next lookup; if TSM is absent it falls back to the null provider.
- Preserves DBMinBuyout, DBMarket, DBHistorical, and DBRecent as separate values.
- Uses the Task 02 freshness policy against the AuctionDB per-item scan timestamp.
- Flags min-buyout values at least 5x DBMarket or at most 0.2x DBMarket as suspicious. These thresholds intentionally match the v4 backport AuctionDB's own extreme-change guard; raw values are never rewritten.
- Explicitly records that AH market depth is unknown; a minimum buyout is a unit-price observation, not proof that the requested quantity is available at that price.
- Added `/pcapper price <itemID or item link>` to show provider/version/backend, min/market/historical/recent values, scan age, auction count, and suspicious-price state for live verification.

## Backport compatibility checked

On 2026-09-11:
- `Keoo88/TradeSkillMaster-3.3.5-backport` and `hugetiny/TradeSkillMaster-3.3.5-backport` use the same AuctionDB v4 record schema for this integration: `mb`, `mv`, `na`, `ts`, `mkt`, `hist`.
- Both expose `TSM_AuctionDB_GetRealmData()`.
- Both expose the TSM v4 public `TSM_API.GetCustomPriceValue()` price API.
- The hugetiny fork is 26 commits ahead of Keoo88/master while containing the upstream history. Its extra commits primarily add 3.3.5 compatibility, stability, localization, scan, and vendor fixes. Profession Capper does not depend on those fork-specific additions.

## Automated validation

Lua 5.1 tests cover:
- TSM completely absent -> null-provider fallback
- raw AuctionDB v4 min/market/historical/recent values and per-item scan age
- public TSM price API taking precedence while retaining raw scan metadata
- provider version/backend metadata
- public API errors safely falling back to raw AuctionDB
- direct SavedVariables fallback when the helper API is absent
- suspicious high and low current-price flags without rewriting values
- unscanned/invalid items returning explicit unavailable results
- dynamic provider availability when TSM appears/disappears

## Acceptance criteria

Automated:
- PASS — addon loads with TSM absent.
- PASS — supported TSM/AuctionDB API shapes load through feature detection.
- PASS — known fixture item prices are retrieved through the neutral provider.
- PASS — scan age is exposed when AuctionDB supplies a timestamp.
- PASS — bad/missing TSM values and API exceptions degrade safely rather than crashing.

Live:
- PASS — tested with TradeSkillMaster_AuctionDB `v4.14.66-wrath`.
- PASS — backend detected as `TSM_API + AuctionDB API`.
- PASS — three real Enchanting materials returned current, market, historical, recent, scan-age, and auction-count data.
- PASS — all three samples were classified fresh and none were falsely flagged suspicious.

## Manual checks

Recommended install for the live check: `hugetiny/TradeSkillMaster-3.3.5-backport`. It currently contains Keoo88 upstream plus additional 3.3.5 fixes, while the AuctionDB interface used here remains compatible with both.

Completed on 2026-09-11 with the hugetiny 3.3.5 backport and AuctionDB `v4.14.66-wrath`.

| Item | Min buyout | DBMarket | DBHistorical | DBRecent | Scan age | Auctions | Suspicious |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Infinite Dust (34054) | 2g 60s 00c | 2g 74s 79c | 2g 77s 42c | 2g 69s 39c | 14,705s | 145 | false |
| Greater Cosmic Essence (34055) | 5g 14s 99c | 5g 00s 09c | 4g 85s 25c | 5g 30s 40c | 14,913s | 94 | false |
| Dream Shard (34052) | 9g 15s 00c | 9g 86s 34c | 8g 62s 23c | 12g 40s 55c | 14,916s | 53 | false |

The live output confirms the provider selects TSM automatically, reads all four price concepts without conflating them, carries per-item scan freshness/count metadata, and applies the suspicious-price check without false positives on these samples.

## Commit

Suggested message: `feat: integrate local TSM AuctionDB pricing`
