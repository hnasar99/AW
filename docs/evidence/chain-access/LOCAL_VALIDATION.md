# Local validation — 2026-10-13

Node v22.16.0, Linux container. 43 automated cases, 43 PASS, 0 FAIL, 0 skipped. Elapsed in final local run: 708.998435 ms. Source and generated bundle were both tested with synthetic upstream responses. This is NOT a mobile acceptance test or evidence of live RPC availability.

Initial run: 42 PASS, 1 FAIL. The final bundle-import assertion shadowed JavaScript's URL constructor with a string constant. It was corrected to globalThis.URL. No production control or assertion was removed; all 43 cases then passed. Original failure and final logs are retained in this conversation's working files.

Covered: chain identities, exact integer balances, pinned block, no retry, denied signing/broadcast/simulations/debug methods, no batches/notifications/caller URL, field validation, body bounds and timeouts, malformed or mismatched upstream, rate/concurrency, operator disable, headers, scope disclosure and bundle execution. Synthetic failure tests do not prove all real-provider behavior.

Deployment at this cut: Railway reports SUCCESS for 4ba790b7-b71a-4504-9419-de4bd3dcbfaf, Bun server started at 0.0.0.0:8080. Browser tool could not access the new public domain and the local container could not resolve external hosts. Live public verification must therefore use the separate smoke job, with its result reported independently.
