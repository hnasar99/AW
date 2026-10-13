import {CHAINS,CAPABILITIES,Fault,object,address,validId,validateRpc} from './policy.mjs';
import {boundedJson,createRpc} from './upstream.mjs';
import {PAGE,CSS,CLIENT} from './web.mjs';
/** Stateless public read gateway. All limits are process-local, not tenant quotas. */
export function createGateway({fetcher=globalThis.fetch,now=Date.now,timeoutMs=10000,rpm=60,burst=12,maxConcurrent=4,enabled=true,origins=[]}={}) {
  const rpc=createRpc(fetcher);
  let tokens=burst,tick=now(),active=0;
  const json=(x,status=200)=>new Response(JSON.stringify(x),{status,headers:{'content-type':'application/json; charset=utf-8'}});
  return async request=>{
    const requestId=crypto.randomUUID();
    let acquired=false,isRpc=false,rpcId=null,timer;
    const headers={'x-request-id':requestId,'cache-control':'no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer','x-frame-options':'DENY','permissions-policy':'camera=(), microphone=(), geolocation=()','content-security-policy':"default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'"};
    const finish=r=>{for(const[k,v]of Object.entries(headers))r.headers.set(k,v);if(r.status===429)r.headers.set('retry-after','5');return r;};
    try {
      const url=new URL(request.url),path=url.pathname,method=request.method;
      if(url.protocol==='https:')headers['strict-transport-security']='max-age=31536000';
      if(url.search||path.includes('%'))throw new Fault(-32600,'Query strings and encoded paths disabled.');
      const origin=request.headers.get('origin');
      if(origin&&origin!==url.origin&&!origins.includes(origin))throw new Fault(-32003,'Origin not allowed.',403);
      if(origin){headers['access-control-allow-origin']=origin;headers.vary='Origin';}
      if(method==='OPTIONS'){headers['access-control-allow-methods']='GET, POST, OPTIONS';headers['access-control-allow-headers']='content-type';return finish(new Response(null,{status:204}));}
      if(method==='GET') {
        if(path==='/healthz')return finish(json({ok:true,service:CAPABILITIES.service,version:CAPABILITIES.version,scope:'process-liveness-only',reads_enabled:enabled}));
        if(path==='/v1/capabilities')return finish(json({...CAPABILITIES,reads_enabled:enabled}));
        if(path==='/')return finish(new Response(PAGE,{headers:{'content-type':'text/html; charset=utf-8'}}));
        if(path==='/ui.css')return finish(new Response(CSS,{headers:{'content-type':'text/css; charset=utf-8'}}));
        if(path==='/ui.js')return finish(new Response(CLIENT,{headers:{'content-type':'text/javascript; charset=utf-8'}}));
      }
      isRpc=method==='POST'&&path.startsWith('/v1/rpc/');
      const status=method==='GET'&&['/readyz','/v1/chains/status'].includes(path);
      const balance=method==='POST'&&path==='/v1/balance';
      if(!isRpc&&!status&&!balance)throw new Fault(-32601,'Route not found.',404);
      if(!enabled)throw new Fault(-32004,'Chain reads disabled by operator.',503);
      const time=now();tokens=Math.min(burst,tokens+Math.max(0,time-tick)*rpm/60000);tick=time;
      if(tokens<1||active>=maxConcurrent)throw new Fault(-32005,'Read budget reached. Retry later.',429);
      tokens--;active++;acquired=true;
      const deadline=new AbortController();
      timer=setTimeout(()=>deadline.abort(),timeoutMs);
      const signal=AbortSignal.any([request.signal,deadline.signal]);
      if(status) {
        const chains=await Promise.all(Object.keys(CHAINS).map(async key=>{
          try{const block=await rpc(key,{method:'eth_blockNumber',params:[]},signal);return{key,chain_id:CHAINS[key].id,ok:true,block_number:BigInt(block).toString(),observed_at:new Date(now()).toISOString()};}
          catch(e){return{key,chain_id:CHAINS[key].id,ok:false,error:e instanceof Fault?e.message:'Unknown upstream state.',observed_at:new Date(now()).toISOString()};}
        }));
        const ok=chains.every(c=>c.ok);
        return finish(json({ok,chains,source:'rpc-observation',automatic_failover:false},path==='/readyz'&&!ok?503:200));
      }
      if(!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(request.headers.get('content-type')??'')||request.headers.has('content-encoding'))throw new Fault(-32600,'Uncompressed application/json required.',415);
      const body=await boundedJson(request,4096,signal);
      if(balance) {
        if(!object(body)||Object.keys(body).length!==2||typeof body.chain!=='string'||!Object.hasOwn(CHAINS,body.chain)||!address(body.address))throw new Fault(-32602,'Expected a supported testnet and public EVM address.');
        const block=await rpc(body.chain,{method:'eth_blockNumber',params:[]},signal);
        const units=await rpc(body.chain,{method:'eth_getBalance',params:[body.address,block]},signal);
        const chain=CHAINS[body.chain];
        return finish(json({chain:body.chain,chain_id:chain.id,address:body.address,balance_units:BigInt(units).toString(),decimals:chain.decimals,symbol:chain.symbol,block_number:BigInt(block).toString(),observed_at:new Date(now()).toISOString(),source:'rpc-observation'}));
      }
      if(object(body)&&validId(body.id))rpcId=body.id;
      const key=path.slice('/v1/rpc/'.length);
      const valid=validateRpc(key,body);
      return finish(json({jsonrpc:'2.0',id:rpcId,result:await rpc(key,valid,signal)}));
    } catch(error) {
      const e=error instanceof Fault?error:new Fault(-32603,'Request failed.',500);
      return finish(json(isRpc?{jsonrpc:'2.0',id:rpcId,error:{code:e.code,message:e.message}}:{error:{code:e.code,message:e.message}},e.status));
    } finally {clearTimeout(timer);if(acquired)active--;}
  };
}
