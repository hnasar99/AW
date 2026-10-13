import { CHAINS, Fault, object, quantity, hash } from './policy.mjs';
/** The deadline covers headers AND the bounded response body. */
export async function boundedJson(message, limit, signal) {
  const length = message.headers.get('content-length');
  if (length !== null && (!/^\d+$/.test(length) || Number(length) > limit)) throw new Fault(-32600, 'Payload too large.', 413);
  const reader = message.body?.getReader();
  if (!reader) throw new Fault(-32700, 'Missing JSON body.');
  const chunks = [];
  let size = 0;
  const cancel = () => { void reader.cancel().catch(() => {}); };
  signal.addEventListener('abort', cancel, {once:true});
  try {
    if (signal.aborted) throw new Fault(-32000, 'Request timed out.', 504);
    while (true) {
      const {value,done} = await reader.read();
      if (signal.aborted) throw new Fault(-32000, 'Request timed out.', 504);
      if (done) break;
      size += value.byteLength;
      if (size > limit) throw new Fault(-32600, 'Payload too large.', 413);
      chunks.push(value);
    }
    const bytes = new Uint8Array(size);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk,offset); offset += chunk.byteLength; }
    try { return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes)); }
    catch { throw new Fault(-32700, 'Malformed JSON.'); }
  } finally {
    signal.removeEventListener('abort',cancel);
    void reader.cancel().catch(() => {});
    reader.releaseLock();
  }
}
/** Trust a fixed RPC for data, not cryptographic attestation. Never retry/fail over. */
export function createRpc(fetcher = globalThis.fetch) {
  async function call(chain, method, params, signal) {
    const id = crypto.randomUUID();
    try {
      const response = await fetcher(chain.rpc, {
        method:'POST', redirect:'error', signal,
        headers:{'content-type':'application/json',accept:'application/json'},
        body:JSON.stringify({jsonrpc:'2.0',id,method,params}),
      });
      if (!response.ok) { void response.body?.cancel().catch(() => {}); throw Error('upstream-http'); }
      const body = await boundedJson(response,262144,signal);
      if (!object(body) || body.jsonrpc !== '2.0' || body.id !== id || !Object.hasOwn(body,'result') || Object.hasOwn(body,'error')) throw Error('upstream-envelope');
      const value = body.result;
      if (['eth_chainId','eth_blockNumber','eth_gasPrice','eth_getBalance'].includes(method) && !quantity(value)) throw Error('upstream-quantity');
      if (method === 'eth_getBlockByNumber' && (!object(value) || !hash(value.hash) || !quantity(value.number))) throw Error('upstream-block');
      if (['eth_getTransactionByHash','eth_getTransactionReceipt'].includes(method) && value !== null && (!object(value) || (value.hash ?? value.transactionHash)?.toLowerCase() !== params[0].toLowerCase())) throw Error('upstream-transaction');
      return value;
    } catch { throw new Fault(-32000, signal.aborted ? 'Upstream timed out.' : 'Upstream unavailable or invalid.', signal.aborted ? 504 : 502); }
  }
  return async (key, request, signal) => {
    const chain = CHAINS[key];
    const actual = await call(chain,'eth_chainId',[],signal);
    if (BigInt(actual) !== BigInt(chain.id)) throw new Fault(-32001,'Upstream chain mismatch.',502);
    return request.method === 'eth_chainId' ? actual : call(chain,request.method,request.params,signal);
  };
}
