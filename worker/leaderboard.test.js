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
test('one run atomically records milestone and same-run survival values', async () => {
  const first = board();
  const run = {mode:'run', view:'timed', name:'RUN', seconds:600, time30:123.4, rings:92, height:101};
  assert.equal((await post(first,run)).status,200);
  const get = async mode => (await (await first.fetch(new Request(`https://game/api/leaderboard?mode=${mode}`))).json()).entries;
  assert.deepEqual(await get('timed'),await get('unlimited'));
  assert.equal((await get('timed'))[0].time30,123.4);
  assert.equal((await get('timed'))[0].rings,92);
  await post(first,{...run,name:'FAST',time30:100,rings:40}); // Invalid initials.
  assert.equal((await get('timed')).length,1);
  await post(first,{...run,name:'ABC',time30:110,rings:40,height:500});
  assert.equal((await get('timed'))[0].name,'ABC');
  assert.equal((await get('unlimited'))[0].name,'RUN');
});
test('incomplete run records only survival and rejects inconsistent milestones', async () => {
  const first=board();
  const run={mode:'run',view:'unlimited',name:'NEW',seconds:20,time30:null,rings:3,height:3};
  assert.equal((await post(first,run)).status,200);
  const timed=await (await first.fetch(new Request('https://game/api/leaderboard?mode=timed'))).json();
  assert.deepEqual(timed.entries,[]);
  for (const patch of [{rings:30},{time30:10},{rings:30,time30:21},{rings:30,time30:-1},{rings:30,time30:Infinity}]) {
    assert.equal(validateEntry({...run,...patch}),false);
  }
});
test('legacy timed seconds coexist with new milestone times', async () => {
  const first=board();
  await post(first,score('OLD',120,30));
  await post(first,{mode:'run',view:'timed',name:'NEW',seconds:900,time30:100,rings:80,height:80});
  const result=await (await first.fetch(new Request('https://game/api/leaderboard?mode=timed'))).json();
  assert.deepEqual(result.entries.map(e=>e.name),['NEW','OLD']);
  assert.deepEqual(result.entries.map(e=>e.time30),[100,120]);
});
