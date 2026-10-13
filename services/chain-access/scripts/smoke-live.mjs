/** Active public-endpoint checks. Only public reads and deliberately forbidden requests. */
import assert from 'node:assert/strict';
const base='https://fluuix-chain-access-testnet.up.railway.app';
const checks=[];
async function check(name,path,expected,body,validate=()=>{}) {
  const started=Date.now();
  try {
    const response=await fetch(base+path,{signal:AbortSignal.timeout(15000),redirect:'error',...(body?{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(body)}:{})});
    const text=await response.text();
    const data=response.headers.get('content-type')?.includes('application/json')?JSON.parse(text):text;
    assert.equal(response.status,expected);validate(data);
    const result={name,status:'PASS',http_status:response.status,duration_ms:Date.now()-started,request_id:response.headers.get('x-request-id'),observed_at:new Date().toISOString(),data};
    checks.push(result);console.log(JSON.stringify(result));
  } catch(e) {const result={name,status:'FAIL',duration_ms:Date.now()-started,error:String(e)};checks.push(result);console.log(JSON.stringify(result));}
}
await check('liveness','/healthz',200,null,b=>assert.equal(b.scope,'process-liveness-only'));
await check('capabilities','/v1/capabilities',200,null,b=>{assert.equal(b.primary,'Fluuix');assert.equal(b.backup.configured,false);assert.equal(b.broadcast,false);assert.equal(b.mcp,false);});
await check('console','/',200,null,b=>assert.ok(b.includes('integración con el APK AW está pendiente')));
await check('RPC readiness','/readyz',200,null,b=>{assert.equal(b.ok,true);assert.deepEqual(b.chains.map(c=>c.chain_id),[5042002,10143]);});
for(const[key,id]of [['arc-testnet',5042002],['monad-testnet',10143]]) {
  await check(`${key} identity`,`/v1/rpc/${key}`,200,{jsonrpc:'2.0',id:1,method:'eth_chainId',params:[]},b=>assert.equal(BigInt(b.result),BigInt(id)));
  await check(`${key} public balance`,'/v1/balance',200,{chain:key,address:'0x0000000000000000000000000000000000000000'},b=>{assert.equal(b.chain_id,id);assert.match(b.balance_units,/^\d+$/);});
}
await check('broadcast denied','/v1/rpc/arc-testnet',403,{jsonrpc:'2.0',id:1,method:'eth_sendRawTransaction',params:[]},b=>assert.equal(b.error.code,-32601));
await check('arbitrary URL denied','/v1/rpc/arc-testnet',400,{jsonrpc:'2.0',id:1,method:'eth_chainId',params:[],url:'http://127.0.0.1'},b=>assert.equal(b.error.code,-32600));
console.log(JSON.stringify({summary:{total:checks.length,pass:checks.filter(c=>c.status==='PASS').length,failed:checks.filter(c=>c.status==='FAIL').length},scope:'public HTTP from this runner, not Android or signed payments'}));
if(checks.some(c=>c.status==='FAIL'))process.exitCode=1;
