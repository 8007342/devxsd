const modes = new Set(['timed', 'unlimited']);
export function validateEntry(value) {
  if (!value || !modes.has(value.mode) || typeof value.name !== 'string' || !/^[A-Z]{3}$/.test(value.name)) return false;
  return Number.isFinite(value.seconds) && value.seconds > 0 && value.seconds <= 31536000 &&
    Number.isInteger(value.rings) && value.rings >= 0 && value.rings <= 10000000 &&
    Number.isFinite(value.height) && value.height >= 0 && value.height <= 1000000000 &&
    (value.mode !== 'timed' || value.rings >= 30);
}
export function rankEntries(mode, entries) {
  return entries.sort(mode === 'timed'
    ? (a, b) => a.seconds - b.seconds || b.rings - a.rings
    : (a, b) => b.height - a.height || b.rings - a.rings || a.seconds - b.seconds).slice(0, 10);
}
const json = (data, status = 200) => Response.json(data, {status, headers: {'Cache-Control': 'no-store'}});
export class Leaderboard {
  constructor(ctx) { this.ctx = ctx; }
  async fetch(request) {
    const url = new URL(request.url);
    let mode = url.searchParams.get('mode');
    let entry;
    if (request.method === 'POST') {
      if (Number(request.headers.get('content-length')) > 4096) return json({error: 'Payload too large'}, 413);
      const body = await request.text();
      if (body.length > 4096) return json({error: 'Payload too large'}, 413);
      try { entry = JSON.parse(body); } catch { return json({error: 'Invalid JSON'}, 400); }
      if (!validateEntry(entry)) return json({error: 'Invalid score'}, 400);
      mode = entry.mode;
    } else if (request.method !== 'GET') return json({error: 'Method not allowed'}, 405);
    if (!modes.has(mode)) return json({error: 'Invalid mode'}, 400);
    const entries = await this.ctx.storage.transaction(async storage => {
      const existing = await storage.get(mode) ?? [];
      if (!entry) return existing;
      const {name, seconds, rings, height} = entry;
      const ranked = rankEntries(mode, [...existing, {name, seconds, rings, height}]);
      await storage.put(mode, ranked);
      return ranked;
    });
    return json({entries, source: 'shared'});
  }
}
export default {
  async fetch(request, env) {
    if (new URL(request.url).pathname === '/api/leaderboard') {
      return env.LEADERBOARD.get(env.LEADERBOARD.idFromName('global')).fetch(request);
    }
    return env.ASSETS.fetch(request);
  },
};
