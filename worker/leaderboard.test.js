import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Leaderboard, validateEntry} from './leaderboard.js';
const score = (name, seconds, height, mode = 'timed') => ({mode, name, seconds, height, rings: 30});
function board() {
  const data = new Map();
  const storage = {get: async key => data.get(key), put: async (key, value) => data.set(key, value)};
  storage.transaction = async fn => fn(storage);
  return new Leaderboard({storage});
}
const post = (board, value) => board.fetch(new Request('https://game/api/leaderboard', {method:'POST', body:JSON.stringify(value)}));
test('validates names, completion and finite numeric bounds', () => {
  assert.equal(validateEntry(score('ABC', 60, 30)), true);
  for (const mutation of [{name:['ABC']}, {name:'abC'}, {name:'ABCD'}, {name:'ÄBC'}, {seconds:0}, {seconds:Infinity}, {rings:29}, {rings:30.5}, {height:-1}]) {
    assert.equal(validateEntry({...score('ABC',60,30), ...mutation}), false);
  }
});
test('persists ascending timed ten and keeps modes separate', async () => {
  const first = board();
  for (let index=12; index>=1; index--) assert.equal((await post(first,score('ABC',index,30))).status,200);
  const result = await (await first.fetch(new Request('https://game/api/leaderboard?mode=timed'))).json();
  assert.deepEqual(result.entries.map(entry => entry.seconds),[1,2,3,4,5,6,7,8,9,10]);
  assert.equal(result.source,'shared');
  assert.deepEqual((await (await first.fetch(new Request('https://game/api/leaderboard?mode=unlimited'))).json()).entries,[]);
});
test('unlimited ranks height descending and rejects invalid submissions', async () => {
  const first=board();
  for (const height of [12,2,88]) await post(first, score('XYZ',60,height,'unlimited'));
  assert.deepEqual((await (await first.fetch(new Request('https://game/api/leaderboard?mode=unlimited'))).json()).entries.map(entry=>entry.height),[88,12,2]);
  assert.equal((await post(first,score('bad',60,30))).status,400);
  assert.equal((await first.fetch(new Request('https://game/api/leaderboard?mode=other'))).status,400);
});
