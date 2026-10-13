/** Deterministic dependency-free bundle: tested modules, same code for Railway. */
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
const root=new URL('../',import.meta.url);
const files=['policy.mjs','upstream.mjs','web.mjs','gateway.mjs'];
const code=files.map(name=>readFileSync(new URL(`src/${name}`,root),'utf8').replace(/^import .* from .*;\n/gm,'')).join('\n');
const entry=`\n// Railway Bun entry; source modules also run under Node's native test runner.\nconst env=globalThis.Bun?.env??{};\nconst domain=env.RAILWAY_PUBLIC_DOMAIN;\nexport default {port:Number(env.PORT??8080),hostname:'0.0.0.0',maxRequestBodySize:4096,fetch:createGateway({enabled:env.CHAIN_READS_ENABLED!=='false',origins:domain?[\`https://\${domain}\`]:[]})};\n`;
mkdirSync(new URL('dist/',root),{recursive:true});
writeFileSync(new URL('dist/railway.mjs',root),code+entry);
