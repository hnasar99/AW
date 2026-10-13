# Fluuix Chain Access 0.1.0 — testnet read pilot

Fluuix is primary. ZonaFranca is a planned backup, not configured and never selected automatically. No MCP is needed for this HTTP slice. This service extends hnasar99/AW; it is not a replacement mobile application.

## Published interface

Base URL: https://fluuix-chain-access-testnet.up.railway.app

- GET /: diagnostic console, not the AW mobile UI.
- GET /healthz: process liveness only; does not certify chain availability.
- GET /v1/capabilities: machine-readable scope, registry and unsupported capabilities.
- GET /readyz: current chain ID and block checks on both testnets; 503 when any fails.
- GET /v1/chains/status: detailed current RPC observations, including failures.
- POST /v1/balance: JSON {"chain":"arc-testnet","address":"0x..."}. Returns native balance_units as decimal string, decimals, symbol, observed block and time. Use a public TEST address.
- POST /v1/rpc/arc-testnet and /v1/rpc/monad-testnet: single JSON-RPC 2.0 requests with nonnegative safe integer or 1–64 alphanumeric/underscore/hyphen ID. No batches or notifications.

Allowed RPC: eth_chainId, eth_blockNumber, eth_getBalance, eth_gasPrice, eth_getBlockByNumber (latest, false), eth_getTransactionByHash, eth_getTransactionReceipt. Chain identity is checked for every operation. No simulation, eth_call, eth_estimateGas, signing, broadcasting, swaps or bridges. Raw receipts remain RPC evidence, not payment reconciliation.

## Security boundaries

PUBLIC DATA ONLY: this pilot has no tenant authentication and accepts no business operations, invoices or secrets. CORS is not authentication. Never pass wallets' private material. Request bodies are not logged by this code; provider/platform logs are outside that claim. Addresses submitted to /v1/balance are forwarded to the selected RPC.

Only two compile-time HTTPS destinations exist. There are no caller-chosen URLs, redirects, retries or fallback. Maximum request body 4096 bytes, upstream body 262144 bytes, end-to-end handler deadline 10 seconds, four concurrent chain requests, initial burst 12 and sustained 60 requests/minute PER PROCESS. Keep one replica for this pilot; these budgets are neither a distributed quota nor a money-spending control. Platform-level denial-of-service protection, availability objectives and business identity remain separate production work.

Arc native USDC uses 18 decimals. This endpoint does not add its ERC-20 representation to that balance. Monad native balances are MON, not USDC. No mainnet routes exist.

## Build, test, deploy

Node 22.16.0 was used for local tests. No npm dependencies or install step.

```sh
node services/chain-access/scripts/bundle.mjs
node --test services/chain-access/test/*.test.mjs
node services/chain-access/scripts/smoke-live.mjs
```

The first two commands use synthetic upstream responses. The third makes real HTTP calls to the fixed public deployment, including rejected write requests; it NEVER constructs or signs a payment.

Modular source: src/policy.mjs, src/upstream.mjs, src/web.mjs, src/gateway.mjs. scripts/bundle.mjs deterministically concatenates them and adds the Bun entry point into dist/railway.mjs. The test suite also checks that generated bundle. Do not hand-edit deployment code; regenerate from source.

Railway project b027e95f-1339-41aa-acb9-def36dd45a4e, testnet environment e77581de-dbd0-402c-bb1b-7b36275fc3f8, service ddf7215c-9565-4632-9b06-fc9d82cc8c01. Deployment uses a Railway Function, Bun 1.4.0, with no external dependencies. The complete generated file is the function source. Repository versioning and deployment updates are manual in this pilot; GitHub CI verifies but does not auto-deploy changes.

Emergency stop: set CHAIN_READS_ENABLED=false on the service and deploy that configuration. Health and capabilities stay available; chain routes return 503. Rollback: select a previous verified function deployment in Railway. No database, durable wallet state or keys live in this service.

## What this does NOT finish

Existing AW Dart/Rust RPC clients are NOT switched to this service. Do not replace their shared RPC blindly: the current payment preparation needs simulations, intentionally disabled here. Integrate a separate read-only client first, preserve AW_LAB_TEXT_ONLY, and test UI → runtime → Fluuix → RPC → UI. The ledger corruption issue identified in treasury, centralized business limits, real model acceptance, signing and mobile release acceptance are NOT fixed by this backend slice. No existing mobile code, dependencies, notices, or main branch are changed.

## Sources checked 2026-10-13

- https://docs.arc.io/arc/references/connect-to-arc — Arc Testnet 5042002, rpc.testnet.arc.io.
- https://docs.monad.xyz/ai/current-facts — Monad Testnet 10143, testnet-rpc.monad.xyz.
- https://docs.railway.com/functions — single-file Bun services and versioned deployment.

An RPC success is a current observation from a trusted provider, not independent cryptographic verification of the chain.
