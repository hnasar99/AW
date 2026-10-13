/** Reviewed public testnets. Callers cannot supply URLs, contracts or mainnet IDs. */
export const CHAINS = Object.freeze({
  'arc-testnet': Object.freeze({id: 5042002, symbol: 'USDC', decimals: 18, rpc: 'https://rpc.testnet.arc.io'}),
  'monad-testnet': Object.freeze({id: 10143, symbol: 'MON', decimals: 18, rpc: 'https://testnet-rpc.monad.xyz'}),
});
export const VERSION = '0.1.0';
export class Fault extends Error {
  constructor(code, message, status = 400) { super(message); this.code = code; this.status = status; }
}
export const object = x => x !== null && typeof x === 'object' && !Array.isArray(x);
export const exact = (re, x) => typeof x === 'string' && re.exec(x)?.[0] === x;
export const address = x => exact(/^0x[0-9a-fA-F]{40}$/, x);
export const hash = x => exact(/^0x[0-9a-fA-F]{64}$/, x);
export const quantity = x => exact(/^0x(?:0|[1-9a-fA-F][0-9a-fA-F]{0,63})$/, x);
export const validId = x => (Number.isSafeInteger(x) && x >= 0) || exact(/^[A-Za-z0-9_-]{1,64}$/, x);
export const METHODS = Object.freeze(['eth_chainId', 'eth_blockNumber', 'eth_getBalance', 'eth_gasPrice', 'eth_getBlockByNumber', 'eth_getTransactionByHash', 'eth_getTransactionReceipt']);
export function validateRpc(key, body) {
  if (!Object.hasOwn(CHAINS, key)) throw new Fault(-32602, 'Unsupported testnet.', 404);
  if (!object(body) || Object.keys(body).some(k => !['jsonrpc','id','method','params'].includes(k)) || body.jsonrpc !== '2.0' || !validId(body.id) || !Array.isArray(body.params)) throw new Fault(-32600, 'Invalid JSON-RPC request.');
  const p = body.params;
  let valid = false;
  switch (body.method) {
    case 'eth_chainId': case 'eth_blockNumber': case 'eth_gasPrice': valid = p.length === 0; break;
    case 'eth_getBalance': valid = p.length === 2 && address(p[0]) && (p[1] === 'latest' || quantity(p[1])); break;
    case 'eth_getBlockByNumber': valid = p.length === 2 && p[0] === 'latest' && p[1] === false; break;
    case 'eth_getTransactionByHash': case 'eth_getTransactionReceipt': valid = p.length === 1 && hash(p[0]); break;
    default: throw new Fault(-32601, 'Method disabled. No simulation, signing or broadcasting.', 403);
  }
  if (!valid) throw new Fault(-32602, 'Invalid or forbidden parameters.');
  return body;
}
export const CAPABILITIES = Object.freeze({
  service: 'fluuix-chain-access', version: VERSION, environment: 'testnet', transport: 'http-jsonrpc',
  primary: 'Fluuix', backup: {name: 'ZonaFranca', configured: false, automatic_failover: false},
  authentication: 'none-public-testnet-data-only', mcp: false, signing: false, broadcast: false,
  custody: false, private_business_data: false, simulation: false, cross_chain_transfers: false,
  mobile_integration: 'pending', limits_scope: 'per-process-not-enterprise-policy',
  chains: Object.entries(CHAINS).map(([key,c]) => ({key,chain_id:c.id,symbol:c.symbol,decimals:c.decimals,path:`/v1/rpc/${key}`,methods:METHODS})),
});
