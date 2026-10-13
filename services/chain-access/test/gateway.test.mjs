import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Script} from 'node:vm';
import {createGateway} from '../src/gateway.mjs';
import {createGateway as bundledGateway} from '../dist/railway.mjs';
import {CHAINS,validateRpc,quantity,address} from '../src/policy.mjs';
import {CLIENT} from '../src/web.mjs';
const URL='https://fluuix.example';
const ADDRESS='0x'+'1'.repeat(40),HASH='0x'+'a'.repeat(64);
const request=(path,body,headers={})=>new Request(URL+path,body===undefined?{headers}:{method:'POST',headers:{'content-type':'application/json',...headers},body:JSON.stringify(body)});
const payload=(method='eth_chainId',params=[])=>({jsonrpc:'2.0',id:7,method,params});
function fixture({chainMismatch=false,mutate=x=>x}={}) {
  const calls=[];
  const fetcher=async(url,options)=>{
    calls.push({url,options});
    const {id,method,params}=JSON.parse(options.body);
    const chain=Object.values(CHAINS).find(c=>c.rpc===url);
    assert.ok(chain); assert.equal(options.redirect,'error'); assert.ok(options.signal);
    assert.equal(Object.hasOwn(options.headers,'authorization'),false);
    const values={eth_chainId:'0x'+(chainMismatch?1:chain.id).toString(16),eth_blockNumber:'0x100',eth_getBalance:'0xde0b6b3a7640000',eth_gasPrice:'0x1',eth_getBlockByNumber:{hash:HASH,number:'0x100'},eth_getTransactionByHash:null,eth_getTransactionReceipt:null};
    return new Response(JSON.stringify(mutate({jsonrpc:'2.0',id,result:values[method]},method,params)),{headers:{'content-type':'application/json'}});
  };
  return {fetcher,calls};
}
for(const [label,factory] of [['source',createGateway],['bundle',bundledGateway]]) {
  test(`${label}: liveness has no upstream and is not readiness`,async()=>{
    const f=fixture(),g=factory(f),r=await g(request('/healthz'));
    assert.equal(r.status,200);assert.equal((await r.json()).scope,'process-liveness-only');assert.equal(f.calls.length,0);
  });
  test(`${label}: reads both testnet identities and blocks`,async()=>{
    const f=fixture(),r=await factory(f)(request('/readyz')),b=await r.json();
    assert.equal(r.status,200);assert.ok(b.ok);assert.deepEqual(b.chains.map(c=>c.chain_id),[5042002,10143]);assert.equal(f.calls.length,4);
  });
  test(`${label}: returns exact integer balance pinned to observed block`,async()=>{
    const f=fixture(),r=await factory(f)(request('/v1/balance',{chain:'monad-testnet',address:ADDRESS}));
    const b=await r.json();assert.equal(b.balance_units,'1000000000000000000');assert.equal(b.symbol,'MON');assert.equal(b.decimals,18);assert.equal(b.block_number,'256');
    assert.deepEqual(JSON.parse(f.calls.at(-1).options.body).params,[ADDRESS,'0x100']);
  });
  test(`${label}: chain mismatch stops before balance lookup`,async()=>{
    const f=fixture({chainMismatch:true}),r=await factory(f)(request('/v1/rpc/arc-testnet',payload('eth_getBalance',[ADDRESS,'latest'])));
    assert.equal(r.status,502);assert.equal((await r.json()).error.code,-32001);assert.equal(f.calls.length,1);
  });
  test(`${label}: network failure is not zero and never retries`,async()=>{
    let calls=0;const g=factory({fetcher:async()=>{calls++;throw Error('CANARY_PRIVATE_DATA');}});
    const r=await g(request('/v1/rpc/arc-testnet',payload()));const text=await r.text();assert.equal(r.status,502);assert.equal(calls,1);assert.ok(!text.includes('CANARY'));
  });
}
for(const method of ['eth_sendTransaction','eth_sendRawTransaction','eth_sign','personal_sign','eth_call','eth_estimateGas','debug_traceTransaction','wallet_addEthereumChain']) {
  test(`denies ${method} before any upstream call`,async()=>{
    const f=fixture(),r=await createGateway(f)(request('/v1/rpc/arc-testnet',payload(method)));
    assert.equal(r.status,403);assert.equal(f.calls.length,0);
  });
}
for(const [name,body] of [['batch',[payload()]],['notification',{jsonrpc:'2.0',method:'eth_chainId',params:[]}],['custom URL',{...payload(),url:'http://169.254.169.254/'}],['invalid ID',{...payload(),id:9007199254740992}],['invalid balance',payload('eth_getBalance',['x','latest'])]]) {
  test(`rejects ${name}`,async()=>{const f=fixture();assert.equal((await createGateway(f)(request('/v1/rpc/arc-testnet',body))).status,400);assert.equal(f.calls.length,0);});
}
test('mainnet and prototype names are not registered',()=>{for(const key of ['arc-mainnet','monad-mainnet','__proto__','constructor'])assert.throws(()=>validateRpc(key,payload()));});
test('strict address and integer bounds',()=>{assert.ok(!address(ADDRESS+'\n'));assert.ok(!quantity('0x01'));assert.ok(!quantity('0x'+'f'.repeat(65)));assert.ok(quantity('0x0'));});
test('rejects bad origin without treating CORS as identity',async()=>{const f=fixture(),g=createGateway(f);assert.equal((await g(request('/v1/rpc/arc-testnet',payload(),{origin:'https://evil.example'}))).status,403);assert.equal(f.calls.length,0);});
test('operator domain is allowed when Railway uses an internal host',async()=>{const f=fixture(),g=createGateway({...f,origins:[URL]});const r=await g(new Request('http://internal/healthz',{headers:{origin:URL}}));assert.equal(r.headers.get('access-control-allow-origin'),URL);});
test('rejects query-based endpoints',async()=>{assert.equal((await createGateway()(request('/healthz?url=http://localhost'))).status,400);});
test('operator kill switch preserves liveness, blocks chain work',async()=>{const f=fixture(),g=createGateway({...f,enabled:false});assert.equal((await g(request('/healthz'))).status,200);assert.equal((await g(request('/v1/chains/status'))).status,503);assert.equal(f.calls.length,0);});
test('malformed JSON and oversized client payloads fail before upstream',async()=>{
  const f=fixture(),g=createGateway(f);
  for(const[body,status]of [['{',400],[' '.repeat(4097),413]]) {const r=await g(new Request(URL+'/v1/rpc/arc-testnet',{method:'POST',headers:{'content-type':'application/json'},body}));assert.equal(r.status,status);}
  assert.equal(f.calls.length,0);
});
test('content type and compression are not silently accepted',async()=>{const g=createGateway();assert.equal((await g(request('/v1/balance',{}, {'content-type':'text/plain'}))).status,415);assert.equal((await g(request('/v1/balance',{}, {'content-encoding':'gzip'}))).status,415);});
for(const[name,mutate]of [['wrong id',b=>({...b,id:'wrong'})],['upstream error',b=>({...b,error:{message:'CANARY'}})],['bad quantity',b=>({...b,result:'0x01'})]]) {
  test(`sanitizes ${name}`,async()=>{const r=await createGateway(fixture({mutate}))(request('/v1/rpc/arc-testnet',payload()));assert.equal(r.status,502);assert.ok(!(await r.text()).includes('CANARY'));});
}
test('oversized upstream response is rejected',async()=>{const r=await createGateway({fetcher:async()=>new Response(' '.repeat(262145))})(request('/v1/rpc/arc-testnet',payload()));assert.equal(r.status,502);});
test('deadline interrupts stalled upstream body',async()=>{
  let cancelled=false;
  const fetcher=async()=>new Response(new ReadableStream({pull(){},cancel(){cancelled=true;}}));
  const r=await createGateway({fetcher,timeoutMs:20})(request('/v1/rpc/arc-testnet',payload()));assert.equal(r.status,504);assert.ok(cancelled);
});
test('deadline interrupts stalled client body',async()=>{
  const f=fixture(),g=createGateway({...f,timeoutMs:20});
  const r=await g(new Request(URL+'/v1/rpc/arc-testnet',{method:'POST',headers:{'content-type':'application/json'},body:new ReadableStream({pull(){}}),duplex:'half'}));
  assert.equal(r.status,504);assert.equal(f.calls.length,0);
});
test('global burst budget and refill are enforced',async()=>{let clock=0;const g=createGateway({...fixture(),burst:1,rpm:60,now:()=>clock});assert.equal((await g(request('/v1/rpc/arc-testnet',payload()))).status,200);const r=await g(request('/v1/rpc/arc-testnet',payload()));assert.equal(r.status,429);assert.ok(r.headers.get('retry-after'));clock=1000;assert.equal((await g(request('/v1/rpc/arc-testnet',payload()))).status,200);});
test('concurrency limit releases after a timeout',async()=>{
  const fetcher=async()=>new Response(new ReadableStream({pull(){}}));const g=createGateway({fetcher,maxConcurrent:1,timeoutMs:20});
  const a=g(request('/v1/rpc/arc-testnet',payload()));await new Promise(r=>setTimeout(r,2));assert.equal((await g(request('/v1/rpc/arc-testnet',payload()))).status,429);assert.equal((await a).status,504);assert.equal((await g(request('/v1/rpc/arc-testnet',payload()))).status,504);
});
test('readiness reports failures rather than claiming health from a running process',async()=>{const g=createGateway({fetcher:async()=>{throw Error('offline');}});const r=await g(request('/readyz'));assert.equal(r.status,503);const b=await r.json();assert.ok(!b.ok);assert.ok(b.chains.every(c=>!c.ok));});
test('capabilities disclose limits and no active backup',async()=>{const b=await(await createGateway()(request('/v1/capabilities'))).json();assert.equal(b.primary,'Fluuix');for(const k of ['broadcast','signing','mcp','custody','simulation'])assert.equal(b[k],false);assert.equal(b.backup.configured,false);assert.equal(b.mobile_integration,'pending');});
test('console has security headers, no external assets and valid JS',async()=>{const r=await createGateway()(request('/'));assert.equal(r.status,200);assert.ok(r.headers.get('content-security-policy').includes("script-src 'self'"));assert.equal(r.headers.get('cache-control'),'no-store');assert.ok((await r.text()).includes('integración con el APK AW está pendiente'));new Script(CLIENT);});
test('bundle contains no local or package imports',()=>{assert.ok(!/^import /m.test(readFileSync(new globalThis.URL('../dist/railway.mjs',import.meta.url),'utf8')));});
