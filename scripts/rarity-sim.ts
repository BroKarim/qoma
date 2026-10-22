import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';

const tiers = ['common', 'uncommon', 'rare', 'legendary'] as const;
type Config = {
  name: string; base: number[]; counts: number[]; weights: number[][];
  rarePlus: [number, number]; legendary: [number, number];
};
const seed = 20261022;
const players = 10_000;
const fractions = [.25, .5, .75, .9, 1];

// Mulberry32; each player has independent interval/tier/item streams.
function rng(value: number) {
  return () => {
    value = (value + 0x6D2B79F5) >>> 0;
    let n = value;
    n = Math.imul(n ^ n >>> 15, n | 1);
    n ^= n + Math.imul(n ^ n >>> 7, n | 61);
    return ((n ^ n >>> 14) >>> 0) / 4294967296;
  };
}
function stream(player: number, channel: number) {
  return rng((seed ^ Math.imul(player + 1, 0x9E3779B1) ^ Math.imul(channel, 0x85EBCA6B)) >>> 0);
}
export function pityBoost(count: number, start: number, hard: number) {
  if (count >= hard - 1) return 1;
  if (count < start) return 0;
  return (count - start) / (hard - start);
}
export function probabilities(c: Config, rareCount: number, legendCount: number) {
  if (legendCount >= c.legendary[1] - 1) return [0, 0, 0, 1];
  const rarePlusBase = c.base[2] + c.base[3];
  const rarePlusTarget = rarePlusBase + (1 - rarePlusBase) * pityBoost(rareCount, ...c.rarePlus);
  // Preserve base Rare during soft Legendary pity; hard Legendary is the sole override.
  const legend = Math.min(1 - c.base[2], c.base[3] + (1 - c.base[3]) * pityBoost(legendCount, ...c.legendary));
  const rare = Math.max(c.base[2], rarePlusTarget - legend);
  const remainder = Math.max(0, 1 - rare - legend);
  const low = c.base[0] + c.base[1];
  return [remainder * c.base[0] / low, remainder * c.base[1] / low, rare, legend];
}
function weighted(cdf: number[], roll: number) {
  for (let i = 0; i < cdf.length - 1; i++) if (roll < cdf[i]) return i;
  return cdf.length - 1;
}
function cumulative(weights: number[]) {
  const total = weights.reduce((a, b) => a + b, 0);
  let sum = 0;
  return weights.map(w => sum += w / total);
}
function nextCounter(count: number, tier: number, minimumTier: number) {
  return tier >= minimumTier ? 0 : count + 1;
}
const varied = (n: number) => Array.from({ length: n }, (_, i) => 1 + (i % 3));
function config(
  name: string,
  counts: number[],
  base: number[],
  legendary: [number, number],
  itemWeights?: number[][],
  rarePlus: [number, number] = [30, 60]
): Config {
  return { name, counts, base, rarePlus, legendary,
    weights: itemWeights ?? counts.map(varied) };
}
const production = JSON.parse(readFileSync('Qoma/Resources/rarity-config.json', 'utf8')) as {
  intervalSeconds: { min: number; max: number };
  baseOdds: Record<typeof tiers[number], number>;
  pity: { rarePlus: { start: number; hard: number }; legendary: { start: number; hard: number } };
  itemCounts: Record<typeof tiers[number], number>;
  itemWeights: { cycle: number[]; legendaryStart: number; legendaryStep: number };
};
const productionCounts = tiers.map(tier => production.itemCounts[tier]);
const productionWeights = productionCounts.map((count, tierIndex) => Array.from({ length: count }, (_, index) =>
  tierIndex === 3
    ? production.itemWeights.legendaryStart + index * production.itemWeights.legendaryStep
    : production.itemWeights.cycle[index % production.itemWeights.cycle.length]
));
const candidates = [
  config('baseline-100', [60, 25, 12, 3], [.70, .24, .055, .005], [180, 360]),
  config('bottleneck-150', [90, 36, 18, 6], [.70, .24, .055, .005], [180, 360],
    [Array.from({ length: 90 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 36 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 18 }, (_, i) => 1 + (i % 3)),
      [12, 10, 8, 6, 3, .2]]),
  config('spread-150', [84, 36, 18, 12], [.7042, .24, .055, .0008], [1000, 2000],
    [Array.from({ length: 84 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 36 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 18 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 12 }, (_, i) => 1 + i * .03)]),
  config('tuned-spread-150', [84, 36, 18, 12], [.7039, .24, .055, .0011], [730, 1460],
    [Array.from({ length: 84 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 36 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 18 }, (_, i) => 1 + (i % 3)),
      Array.from({ length: 12 }, (_, i) => 1 + i * .03)]),
  config('progressive-150', productionCounts,
    tiers.map(tier => production.baseOdds[tier]),
    [production.pity.legendary.start, production.pity.legendary.hard],
    productionWeights,
    [production.pity.rarePlus.start, production.pity.rarePlus.hard]),
];

function validate(c: Config) {
  assert.equal(c.counts.length, 4);
  assert.equal(c.base.length, 4);
  assert.ok(Math.abs(c.base.reduce((a, b) => a + b, 0) - 1) < 1e-12);
  assert.ok(c.base.every(x => Number.isFinite(x) && x > 0));
  assert.equal(c.weights.length, 4);
  assert.ok(c.base[0] + c.base[1] > 0);
  for (const [start, hard] of [c.rarePlus, c.legendary]) assert.ok(Number.isInteger(start) && start >= 0 && Number.isInteger(hard) && hard > start);
  c.counts.forEach((n, i) => {
    assert.ok(Number.isInteger(n) && n > 0);
    assert.equal(c.weights[i].length, n);
    assert.ok(c.weights[i].every(w => Number.isFinite(w) && w > 0));
  });
}
function summary(values: number[]) {
  const sorted = values.toSorted((a, b) => a - b);
  const quantile = (p: number) => {
    const position = (sorted.length - 1) * p;
    const lower = Math.floor(position);
    return sorted[lower] + (sorted[Math.ceil(position)] - sorted[lower]) * (position - lower);
  };
  return { mean: values.reduce((a, b) => a + b, 0) / values.length,
    p10: quantile(.1), median: quantile(.5), p90: quantile(.9) };
}
function firstLegendary(c: Config, withPity: boolean) {
  const hours: number[] = [];
  for (let player = 0; player < players; player++) {
    const timeRng = stream(player, 1), tierRng = stream(player, 2);
    let seconds = 0, count = 0;
    while (true) {
      seconds += production.intervalSeconds.min
        + (production.intervalSeconds.max - production.intervalSeconds.min) * timeRng();
      const p = withPity ? probabilities(c, 0, count)[3] : c.base[3];
      if (tierRng() >= 1 - p) break;
      count++;
    }
    hours.push(seconds / 3600);
  }
  return summary(hours);
}
function simulate(c: Config, population = players) {
  validate(c);
  const total = c.counts.reduce((a, b) => a + b, 0);
  const offsets = c.counts.map((_, i) => c.counts.slice(0, i).reduce((a, b) => a + b, 0));
  const cdfs = c.weights.map(cumulative);
  const milestones: number[][] = fractions.map(() => []);
  const tierTimes: number[][] = tiers.map(() => []);
  const tierCatchCounts = [0, 0, 0, 0];
  let duplicates = 0, maxCatches = 0;
  for (let player = 0; player < population; player++) {
    const timeRng = stream(player, 1), tierRng = stream(player, 2), itemRng = stream(player, 3);
    const seen = new Uint8Array(total), discoveredByTier = [0, 0, 0, 0];
    let discovered = 0, seconds = 0, catches = 0, rareCount = 0, legendCount = 0, milestone = 0;
    while (discovered < total) {
      seconds += production.intervalSeconds.min
        + (production.intervalSeconds.max - production.intervalSeconds.min) * timeRng();
      const p = probabilities(c, rareCount, legendCount);
      const roll = tierRng();
      const tier = roll < p[0] ? 0 : roll < p[0] + p[1] ? 1 : roll < 1 - p[3] ? 2 : 3;
      const item = offsets[tier] + weighted(cdfs[tier], itemRng());
      rareCount = nextCounter(rareCount, tier, 2);
      legendCount = nextCounter(legendCount, tier, 3);
      catches++;
      tierCatchCounts[tier]++;
      if (!seen[item]) {
        seen[item] = 1;
        discovered++;
        discoveredByTier[tier]++;
        if (discoveredByTier[tier] === c.counts[tier]) tierTimes[tier].push(seconds / 3600);
        while (milestone < fractions.length && discovered >= Math.ceil(total * fractions[milestone])) {
          milestones[milestone++].push(seconds / 3600);
        }
      }
    }
    duplicates += catches - total;
    maxCatches = Math.max(maxCatches, catches);
  }
  const allCatches = tierCatchCounts.reduce((a, b) => a + b, 0);
  return { milestones: Object.fromEntries(fractions.map((f, i) => [f, summary(milestones[i])])),
    tierCompletionHours: Object.fromEntries(tiers.map((t, i) => [t, summary(tierTimes[i])])),
    meanDuplicates: duplicates / population, maxCatches, censored: 0,
    effectiveTierRates: tierCatchCounts.map(n => n / allCatches) };
}
function selfCheck() {
  assert.equal(pityBoost(29, 30, 60), 0);
  assert.equal(pityBoost(30, 30, 60), 0);
  assert.equal(pityBoost(31, 30, 60), 1 / 30);
  assert.equal(pityBoost(59, 30, 60), 1);
  assert.equal(nextCounter(40, 2, 2), 0);
  assert.equal(nextCounter(40, 2, 3), 41);
  assert.equal(nextCounter(40, 3, 2), 0);
  assert.equal(nextCounter(40, 3, 3), 0);
  for (const c of candidates) {
    validate(c);
    for (let r = 0; r <= c.rarePlus[1]; r++) for (let l = 0; l <= c.legendary[1]; l++) {
      const p = probabilities(c, r, l);
      assert.ok(p.every(x => x >= -1e-12 && x <= 1));
      assert.ok(Math.abs(p.reduce((a, b) => a + b, 0) - 1) < 1e-12);
      if (l < c.legendary[1] - 1) assert.ok(p[2] >= c.base[2]);
      if (r >= c.rarePlus[1] - 1) assert.ok(Math.abs(p[2] + p[3] - 1) < 1e-12);
    }
  }
  const a = rng(seed), b = rng(seed);
  for (let i = 0; i < 100; i++) assert.equal(a(), b());
  const draws = rng(seed), cdf = cumulative([1, 3]), counts = [0, 0];
  for (let i = 0; i < 100_000; i++) counts[weighted(cdf, draws())]++;
  assert.ok(Math.abs(counts[0] / 100_000 - .25) < .01);
  assert.deepEqual(simulate(candidates[0], 10), simulate(candidates[0], 10));
}
type Result = ReturnType<typeof simulate> & {
  config: Config;
  firstLegendaryHours: { withPity: ReturnType<typeof summary>; withoutPity: ReturnType<typeof summary> };
};
async function writeReport(results: Result[]) {
  const f = (n: number) => n.toFixed(2);
  const lines = [
    '# Simulasi rarity dan koleksi — 22 Oktober 2026', '',
    'Status: progressive-150 disetujui dan dipakai oleh game. Setiap kandidat memakai 10.000 pemain, seed 20261022, Bun 1.3.10. Semua pemain disimulasikan sampai lengkap, tanpa censoring.', '',
    'Satu catch memakai interval uniform 50–70 detik yang benar-benar dijumlahkan. Hanya jam fokus aktif; semua hasil dianggap banked, tanpa kehilangan provisional. Tidak ada bantuan item baru. Pity hanya menjamin tier.', '',
    'P10 berarti 10% pemain mencapai milestone sebelum waktu itu; P90 berarti 90% sudah mencapainya. Quantile menggunakan interpolasi linear pada posisi (n−1) × p.', '',
    '## Perbandingan penyelesaian 100%', '',
    '| Kandidat | Item | P10 jam | Median jam | P90 jam | Mean duplikat |',
    '|---|---:|---:|---:|---:|---:|',
    ...results.map(r => `| ${r.config.name} | ${r.config.counts.reduce((a,b)=>a+b,0)} | ${f(r.milestones['1'].p10)} | ${f(r.milestones['1'].median)} | ${f(r.milestones['1'].p90)} | ${f(r.meanDuplicates)} |`), '',
    '## Konfigurasi produksi yang disetujui', '',
    '**progressive-150**: 60 Common, 36 Uncommon, 24 Rare, 30 Legendary. Dibanding tuned-spread-150, lebih banyak jenis Legendary membuat penemuan item baru tersebar lebih lama; bukan satu item dengan bobot ekstrem yang menahan completion. Legendary tetap jarang per catch walau jumlah jenisnya 20% katalog.', '',
    'Peluang dasar C/U/R/L: **70,1% / 24% / 5,5% / 0,4%**. Rare+ soft/hard **30/60**, Legendary **220/440**. Bobot C/U/R berulang **1,2,3** menurut indeks nol; bobot Legendary **1 + indeks × 0,01**, dari 1 sampai 1,29. ID sintetis: tier + indeks nol; mapping spesies/art belum diputuskan.', '',
    'Ini tetap memiliki ekor panjang: banyak duplikat dan sebagian besar jam akhir mengejar Legendary tersisa. Pity tidak membatasi waktu menuju spesies baru; tidak ada jaminan 100% katalog selesai pada jam tertentu.', '',
    '## Kebijakan pity yang diterapkan', '',
    'Counter adalah kegagalan sebelum undian. Formula ramp mengikuti pengguna. Rare+ menghitung target peluang gabungan Rare+Legendary; Rare mereset counter Rare+ saja, Legendary mereset keduanya. Peluang Legendary soft dibatasi 1−baseRare, lalu Rare=max(baseRare,targetRarePlus−Legendary). Sisa peluang dibagi Common/Uncommon secara proporsional. Hard Legendary menang dan menetapkan Legendary=1, Rare=0 sebagai pengecualian eksplisit. Hard Rare+ dipenuhi oleh Rare atau Legendary.', '',
    '## Hasil lengkap setiap kandidat', '',
  ];
  for (const r of results) {
    lines.push(`### ${r.config.name}`, '',
      `Jumlah C/U/R/L: ${r.config.counts.join(' / ')}. Base (%): ${r.config.base.map(p=>f(p*100)).join(' / ')}. Pity Rare+ ${r.config.rarePlus.join('/')} dan Legendary ${r.config.legendary.join('/')}.`, '',
      '| Koleksi | P10 jam | Median jam | P90 jam |', '|---|---:|---:|---:|',
      ...fractions.map(q=> { const s=r.milestones[String(q)]; return `| ${q*100}% | ${f(s.p10)} | ${f(s.median)} | ${f(s.p90)} |`; }), '',
      '| Tier lengkap | Mean jam dari awal |', '|---|---:|',
      ...tiers.map(t=>`| ${t} | ${f(r.tierCompletionHours[t].mean)} |`), '',
      '| Legendary pertama | Mean jam | P10 jam | Median jam | P90 jam |', '|---|---:|---:|---:|---:|',
      ...(['withPity','withoutPity'] as const).map(k=> { const s=r.firstLegendaryHours[k]; return `| ${k} | ${f(s.mean)} | ${f(s.p10)} | ${f(s.median)} | ${f(s.p90)} |`; }), '',
      `Mean duplikat: **${f(r.meanDuplicates)}**. Censored: **${r.censored}**. Frekuensi tier efektif sepanjang simulasi (% C/U/R/L): **${r.effectiveTierRates.map(p=>f(p*100)).join(' / ')}**. Frekuensi ini mencakup penghentian pemain saat lengkap, bukan estimasi steady-state tanpa batas.`, '');
  }
  lines.push('## Reproduksi dan validasi', '',
    '`bun scripts/rarity-sim.ts --check` menjalankan assert checks. `bun scripts/rarity-sim.ts` menjalankan semua kandidat. `bun scripts/rarity-sim.ts --only=progressive-150` mengganti hasil kandidat itu dalam laporan existing.', '',
    'Jalankan dari root repository. PRNG Mulberry32 dengan stream terpisah interval/tier/item. Seed stream = seed XOR imul(player+1,0x9E3779B1) XOR imul(channel,0x85EBCA6B), channel 1/2/3. Pemain di setiap kandidat memakai seed yang sama. Perbandingan Legendary pertama memakai stream interval/tier sama dengan dan tanpa pity.', '',
    'Seluruh bobot, parameter, hasil presisi penuh dan statistik disimpan di [results.json](results.json). [rarity-config.json](../../Qoma/Resources/rarity-config.json) menjadi sumber parameter untuk game, Help dan kandidat progressive-150 di simulator.', '');
  await Bun.write('design/rarity-simulation/README.md', lines.join('\n'));
}
selfCheck();
if (process.argv.includes('--check')) {
  console.log('Self-checks passed');
} else {
  const only = process.argv.find(arg => arg.startsWith('--only='))?.slice(7);
  assert.ok(!only || candidates.some(c => c.name === only), 'Unknown candidate');
  const output = Bun.file('design/rarity-simulation/results.json');
  const results: Result[] = only && await output.exists() ? (await output.json()).results.filter((r: { config: Config }) => r.config.name !== only) : [];
  for (const c of candidates.filter(c => !only || c.name === only)) {
    console.error(`Simulating ${c.name}: ${players} players`);
    results.push({ config: c, ...simulate(c), firstLegendaryHours: {
      withPity: firstLegendary(c, true), withoutPity: firstLegendary(c, false) } });
  }
  await Bun.write('design/rarity-simulation/results.json', JSON.stringify({
    seed, players, rng: 'Mulberry32; seed XOR imul(player+1,0x9E3779B1) XOR imul(channel,0x85EBCA6B)',
    intervalSeconds: [production.intervalSeconds.min, production.intervalSeconds.max],
    sourceConfig: 'Qoma/Resources/rarity-config.json',
    pityPolicy: 'Preserve base Rare during soft pity; hard Legendary overrides all tiers',
    results }, null, 2) + '\n');
  await writeReport(results);
  console.log(results.map(r => ({ name: r.config.name, complete: r.milestones['1'], duplicates: r.meanDuplicates })));
}
