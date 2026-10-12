// Cloudflare Worker entry: /api/save goes to the save backend; everything else is the game in public/.
import { onRequest as save } from './functions/api/save.js';

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === '/api/save') return save({ request, env, ctx });
    return env.ASSETS.fetch(request);
  },
};
