// Markdown per a agents (content negotiation): si la portada es demana amb
// `Accept: text/markdown`, es serveix index.md en lloc de l'HTML. La resta
// del lloc no passa per aquest script (run_worker_first a wrangler.jsonc).
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const wantsMarkdown = (request.headers.get('Accept') || '').includes('text/markdown');
    if (wantsMarkdown && (url.pathname === '/' || url.pathname === '/index.html')) {
      const md = await env.ASSETS.fetch(new Request(new URL('/index.md', url), request));
      if (md.ok) {
        return new Response(md.body, {
          headers: { 'Content-Type': 'text/markdown; charset=utf-8', 'Vary': 'Accept' },
        });
      }
    }
    const response = await env.ASSETS.fetch(request);
    if (url.pathname === '/' || url.pathname === '/index.html') {
      const withVary = new Response(response.body, response);
      withVary.headers.append('Vary', 'Accept');
      return withVary;
    }
    return response;
  },
};
