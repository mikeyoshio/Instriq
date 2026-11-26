// Genera /es/index.html i /en/index.html a partir de index.html (català) i
// del diccionari DICT que ja porta la pàgina, perquè els cercadors i els
// agents d'IA (que no executen JavaScript) vegin el castellà i l'anglès.
// S'executa sol amb `npx wrangler deploy` (build.command a wrangler.jsonc);
// també es pot llançar a mà: `node build-langs.mjs`.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { parseHTML } from 'linkedom';

const SITE = 'https://instriq.org';
const source = readFileSync('index.html', 'utf8');
const dictMatch = source.match(/var DICT = (\{[\s\S]*?\n {2}\});/);
if (!dictMatch) throw new Error('No trobo el DICT a index.html');
const DICT = Function(`return ${dictMatch[1]};`)();
const LOCALES = { es: 'es_ES', en: 'en_US' };

for (const lang of Object.keys(LOCALES)) {
  const { document } = parseHTML(source);
  const t = DICT[lang] || {};
  const root = document.documentElement;
  root.setAttribute('lang', lang);
  root.setAttribute('data-static-lang', lang);

  for (const el of document.querySelectorAll('[data-i18n]')) {
    const value = t[el.getAttribute('data-i18n')];
    if (value == null) continue; // sense traducció: es queda el català, com fa applyLang
    const attr = el.getAttribute('data-i18n-attr');
    if (attr) el.setAttribute(attr, value);
    else el.innerHTML = value;
  }
  if (t['meta.title']) document.querySelector('title').textContent = t['meta.title'];
  document.getElementById('canonicalLink')?.setAttribute('href', `${SITE}/${lang}/`);
  document.getElementById('ogLocale')?.setAttribute('content', LOCALES[lang]);
  document.querySelector('meta[property="og:url"]')?.setAttribute('content', `${SITE}/${lang}/`);
  for (const a of document.querySelectorAll('a[data-vdm]')) a.setAttribute('href', `/vademecum/${lang}/`);
  for (const i of document.querySelectorAll('img[data-shot]')) i.setAttribute('src', `/screenshots/${lang}/${i.getAttribute('data-shot')}.webp`);
  for (const so of document.querySelectorAll('source[data-shot-m]')) so.setAttribute('srcset', `/screenshots/${lang}/m_${so.getAttribute('data-shot-m')}.webp`);
  document.getElementById('deckStage')?.setAttribute('aria-roledescription', lang === 'en' ? 'carousel' : 'carrusel');
  for (const b of document.querySelectorAll('#langSwitch button')) {
    const active = b.getAttribute('data-lang') === lang;
    b.classList.toggle('active', active);
    b.setAttribute('aria-pressed', String(active));
  }
  // Rutes relatives -> absolutes: la pàgina viu a /es/ però els fitxers a l'arrel.
  for (const el of document.querySelectorAll('[src], [href], [srcset]')) {
    for (const attr of ['src', 'href', 'srcset']) {
      const v = el.getAttribute(attr);
      if (v && !/^(\/|#|[a-z]+:|data:)/i.test(v)) el.setAttribute(attr, `/${v}`);
    }
  }
  mkdirSync(lang, { recursive: true });
  writeFileSync(`${lang}/index.html`, '<!doctype html>\n' + root.outerHTML + '\n');
  console.log(`${lang}/index.html`);
}
