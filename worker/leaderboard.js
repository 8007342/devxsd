const modes = new Set(['timed', 'unlimited']);
export function validateEntry(value) {
  if (!value || !(modes.has(value.mode) || value.mode === 'run') || typeof value.name !== 'string' || !/^[A-Z]{3}$/.test(value.name)) return false;
  return Number.isFinite(value.seconds) && value.seconds > 0 && value.seconds <= 31536000 &&
    Number.isInteger(value.rings) && value.rings >= 0 && value.rings <= 10000000 &&
    Number.isFinite(value.height) && value.height >= 0 && value.height <= 1000000000 &&
    (value.mode !== 'timed' || value.rings >= 30) &&
    (value.time30 == null || (Number.isFinite(value.time30) && value.time30 > 0 &&
      value.time30 <= value.seconds && value.rings >= 30)) &&
    (value.mode !== 'run' || ((value.rings >= 30) === (value.time30 != null)));
}
export function rankEntries(mode, entries) {
  return entries.sort(mode === 'timed'
    ? (a, b) => (a.time30 ?? a.seconds) - (b.time30 ?? b.seconds) || b.rings - a.rings
    : (a, b) => b.rings - a.rings || b.height - a.height || a.seconds - b.seconds).slice(0, 10);
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
      mode = entry.mode === 'run' ? entry.view : entry.mode;
    } else if (request.method !== 'GET') return json({error: 'Method not allowed'}, 405);
    if (!modes.has(mode)) return json({error: 'Invalid mode'}, 400);
    const entries = await this.ctx.storage.transaction(async storage => {
      if (entry?.mode === 'run') {
        const {name, seconds, rings, height, time30} = entry;
        const result = {name, seconds, rings, height, time30: time30 ?? null};
        for (const ranking of modes) {
          if (ranking === 'timed' && time30 == null) continue;
          const existing = await storage.get(ranking) ?? [];
          await storage.put(ranking, rankEntries(ranking, [...existing, result]));
        }
        return await storage.get(mode) ?? [];
      }
      const existing = await storage.get(mode) ?? [];
      if (!entry) return rankEntries(mode, existing);
      const {name, seconds, rings, height, time30} = entry;
      const ranked = rankEntries(mode, [...existing, {name, seconds, rings, height, time30: time30 ?? (mode === 'timed' ? seconds : null)}]);
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
