// Avisa IndexNow (Bing, Yandex, Seznam, Naver…) de totes les URLs dels
// sitemaps. Executa-ho després de `npx wrangler deploy`: `node indexnow.mjs`.
import { readFileSync } from 'node:fs';

const KEY = '1504bf62f085357ad72c277ac57c94fa'; // publicada a /<KEY>.txt
const urls = ['sitemap.xml', 'sitemap-vademecum.xml']
  .flatMap((f) => [...readFileSync(f, 'utf8').matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]));
for (let i = 0; i < urls.length; i += 10000) {
  const res = await fetch('https://api.indexnow.org/indexnow', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify({ host: 'instriq.org', key: KEY, keyLocation: `https://instriq.org/${KEY}.txt`, urlList: urls.slice(i, i + 10000) }),
  });
  console.log(`IndexNow: ${Math.min(urls.length - i, 10000)} URLs -> HTTP ${res.status}`);
}
