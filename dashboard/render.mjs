// Pure rendering (geen Firebase). Maze-geïnspireerd testverslag:
// overzicht + tevredenheid + gedrag/drop-off + onboarding-keuzes + chat + sessies.
// Styling volgt de shadcn/ui design-taal.

export const RATING_KEYS = [
  ['ease', 'Gebruiksgemak'],
  ['findability', 'Vindbaarheid'],
  ['clarity', 'Duidelijkheid taal'],
  ['looks', 'Uiterlijk'],
];

const SCREEN_LABEL = {
  home: 'Home', regelen: 'Regelen', buurt: 'Buurt', hulp: 'Hulp',
  buurt_detail: 'Buurt-detail', settings: 'Instellingen',
};
const TILE_LABEL = {
  parkeren: 'Parkeerbezoek', afval: 'Afval', grofvuil: 'Grofvuil', zwemmen: 'Zwemmen',
  ooievaarspas: 'Ooievaarspas', afvalkalender: 'Afvalkalender', overlast: 'Overlast melden',
  buurt: 'Mijn buurt', afspraak: 'Afspraak / ID',
};

export const esc = (s) => String(s ?? '')
  .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;');

const fmtDur = (sec) => {
  if (sec == null) return '–';
  const m = Math.floor(sec / 60), s = Math.round(sec % 60);
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
};
const mmss = (sec) => {
  const m = Math.floor((sec || 0) / 60), s = (sec || 0) % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
};
const fmtDate = (iso) => {
  if (!iso) return '–';
  try { return new Date(iso).toLocaleString('nl-NL', { dateStyle: 'medium', timeStyle: 'short' }); }
  catch { return iso; }
};
const pct = (n, d) => d ? Math.round((n / d) * 100) : 0;
const label = (map, key) => map[key] || key;

// ---------- Analyse ----------

function analyze(sessions) {
  const n = sessions.length;
  const withFb = sessions.filter(s => s.feedback);

  const ratingAvg = {}, ratingDist = {};
  for (const [key] of RATING_KEYS) {
    const dist = [0, 0, 0, 0, 0];
    withFb.forEach(s => { const v = s.feedback[key]; if (v >= 1 && v <= 5) dist[v - 1]++; });
    ratingDist[key] = dist;
    const vals = withFb.map(s => s.feedback[key]).filter(v => typeof v === 'number');
    ratingAvg[key] = vals.length ? vals.reduce((a, b) => a + b, 0) / vals.length : null;
  }
  const allRatings = withFb.flatMap(s => RATING_KEYS.map(([k]) => s.feedback[k]).filter(v => typeof v === 'number'));
  const satisfaction = allRatings.length ? Math.round((allRatings.reduce((a, b) => a + b, 0) / allRatings.length) / 5 * 100) : null;

  const wouldUse = { Ja: 0, Misschien: 0, Nee: 0 };
  withFb.forEach(s => { if (s.feedback.wouldUse in wouldUse) wouldUse[s.feedback.wouldUse]++; });

  const finished = sessions.filter(s => (s.events || []).some(e => e.type === 'onboarding_finish' && !(e.props && e.props.skipped))).length;
  const skipped = sessions.filter(s => (s.events || []).some(e => e.type === 'onboarding_finish' && e.props && e.props.skipped)).length;

  const durations = sessions.map(s => s.durationSeconds).filter(v => typeof v === 'number');
  const avgDur = durations.length ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length) : null;
  const totalEvents = sessions.reduce((a, s) => a + (s.events?.length || 0), 0);

  const screenVisits = {}, screenTime = {}, tileTaps = {}, tabUse = {}, dropOff = {};
  const gemeente = {}, buurt = {};
  const chatQuestions = [], openAnswers = [];
  let chatCount = 0;

  sessions.forEach(s => {
    const evs = s.events || [];
    evs.forEach(e => {
      const p = e.props || {};
      if (e.type === 'screen_view' && p.name) screenVisits[p.name] = (screenVisits[p.name] || 0) + 1;
      if (e.type === 'screen_exit' && p.name && typeof p.seconds === 'number') (screenTime[p.name] = screenTime[p.name] || []).push(p.seconds);
      if (e.type === 'tap_tile' && p.dest) tileTaps[p.dest] = (tileTaps[p.dest] || 0) + 1;
      if (e.type === 'tab_switch' && p.tab) tabUse[p.tab] = (tabUse[p.tab] || 0) + 1;
      if (e.type === 'chat_user' && p.text) { chatQuestions.push({ name: s.name || 'anoniem', text: p.text }); chatCount++; }
    });
    const seen = evs.filter(e => e.type === 'screen_view').map(e => e.props?.name).filter(Boolean);
    const last = seen[seen.length - 1];
    if (last) dropOff[last] = (dropOff[last] || 0) + 1;
    (s.gemeenteTaken || []).forEach(t => gemeente[t] = (gemeente[t] || 0) + 1);
    (s.buurtTopics || []).forEach(t => buurt[t] = (buurt[t] || 0) + 1);
    if (s.feedback && s.feedback.improve) openAnswers.push({ name: s.name || 'anoniem', text: s.feedback.improve });
  });

  const avg = (arr) => arr && arr.length ? Math.round(arr.reduce((a, b) => a + b, 0) / arr.length) : null;
  const screenStats = Object.keys(screenVisits)
    .map(k => ({ key: k, label: label(SCREEN_LABEL, k), visits: screenVisits[k], avgTime: avg(screenTime[k]) }))
    .sort((a, b) => b.visits - a.visits);

  const named = sessions.filter(s => s.name && s.name.trim()).length;

  return {
    n, withFb: withFb.length, satisfaction, ratingAvg, ratingDist, wouldUse,
    finished, skipped, avgDur, totalEvents, screenStats, tileTaps, tabUse, dropOff,
    gemeente, buurt, named, chatQuestions, chatCount, openAnswers,
  };
}

// ---------- Chart-helpers ----------

const DIST_COLORS = ['#ef4444', '#f97316', '#eab308', '#84cc16', '#16a34a'];

function kpi(value, label, hint = '') {
  return `<div class="card kpi"><div class="kpi-v">${value}</div><div class="kpi-l">${esc(label)}</div>${hint ? `<div class="kpi-h">${esc(hint)}</div>` : ''}</div>`;
}

function hbar(items, opts = {}) {
  if (!items.length) return '<div class="muted">Geen data.</div>';
  const max = Math.max(1, ...items.map(i => i.value));
  return `<div class="bars">${items.map(i => `
    <div class="bar-row">
      <div class="bar-label" title="${esc(i.label)}">${esc(i.label)}</div>
      <div class="bar-track"><div class="bar-fill" style="width:${(i.value / max) * 100}%;${opts.color ? `background:${opts.color}` : ''}"></div></div>
      <div class="bar-val">${i.value}${i.suffix || ''}</div>
    </div>`).join('')}</div>`;
}

function ratingRow(key, name, avgVal, dist) {
  const total = dist.reduce((a, b) => a + b, 0);
  const segs = dist.map((c, i) => c > 0
    ? `<div class="seg" style="width:${(c / total) * 100}%;background:${DIST_COLORS[i]}" title="${i + 1}: ${c}×"></div>` : '').join('');
  return `<div class="rating-row">
    <div class="rating-name">${esc(name)}</div>
    <div class="rating-bar">${total ? segs : '<div class="seg empty"></div>'}</div>
    <div class="rating-avg">${avgVal != null ? avgVal.toFixed(1) : '–'}<span>/5</span></div>
  </div>`;
}

function segbar(parts) {
  // parts: [{label, value, color}]
  const total = parts.reduce((a, p) => a + p.value, 0) || 1;
  return `<div class="segbar">${parts.map(p =>
    `<div class="segbar-seg" style="width:${(p.value / total) * 100}%;background:${p.color}" title="${esc(p.label)}: ${p.value}"></div>`).join('')}</div>
    <div class="legend">${parts.map(p => `<span><i style="background:${p.color}"></i>${esc(p.label)} ${p.value}</span>`).join('')}</div>`;
}

function quotes(items, empty) {
  if (!items.length) return `<div class="muted">${empty}</div>`;
  return `<div class="quotes">${items.map(q =>
    `<div class="quote"><div class="quote-t">${esc(q.text)}</div><div class="quote-a">— ${esc(q.name)}</div></div>`).join('')}</div>`;
}

// ---------- Secties ----------

function section(title, desc, body) {
  return `<div class="card panel">
    <div class="panel-h"><h3>${esc(title)}</h3>${desc ? `<p>${esc(desc)}</p>` : ''}</div>
    ${body}
  </div>`;
}

function sortedBars(obj, labelMap) {
  return Object.entries(obj)
    .map(([k, v]) => ({ label: labelMap ? label(labelMap, k) : k, value: v }))
    .sort((a, b) => b.value - a.value);
}

// ---------- Sessie-detail ----------

function eventLabel(ev) {
  const p = ev.props || {};
  switch (ev.type) {
    case 'session_start': return ['🟢', 'Sessie gestart', ''];
    case 'session_end': return ['🔴', 'Sessie afgesloten', fmtDur(p.seconds)];
    case 'screen_view': return ['📺', `Scherm: ${label(SCREEN_LABEL, p.name)}`, ''];
    case 'screen_exit': return ['⏱️', `Verliet ${label(SCREEN_LABEL, p.name)}`, `${p.seconds}s`];
    case 'tab_switch': return ['🗂️', `Tab → ${p.tab}`, ''];
    case 'tap_tile': return ['🟨', 'Tegel getikt', label(TILE_LABEL, p.dest)];
    case 'open_settings': return ['⚙️', 'Instellingen geopend', ''];
    case 'open_customize_home': return ['🧩', 'Startscherm aanpassen', ''];
    case 'open_appointment': return ['📅', 'Afspraak geopend', ''];
    case 'open_kwijtschelding': return ['📄', 'Kwijtschelding geopend', ''];
    case 'open_ooievaarspas': return ['🎫', 'Ooievaarspas getoond', ''];
    case 'open_feedback': return ['⭐', 'Feedback geopend', ''];
    case 'open_buurt_detail': return ['📍', 'Buurt-detail', p.title];
    case 'buurt_filter': return ['🔎', 'Buurt-filter', p.filter];
    case 'buurt_location': return ['🏠', 'Buurt-locatie', p.mode];
    case 'digid_login': return ['🔐', 'DigiD ingelogd', ''];
    case 'onboarding_step': return ['👉', `Onboarding stap ${p.step}`, ''];
    case 'onboarding_finish': return ['✅', 'Onboarding afgerond', p.skipped ? 'overgeslagen' : ''];
    case 'chat_suggestion': return ['💡', 'Chat-suggestie', p.title];
    case 'feedback_submit': return ['📝', 'Feedback verstuurd', ''];
    case 'chat_user': return ['💬', 'Vraag (gebruiker)', null];
    case 'chat_ai': return ['🤖', 'Antwoord (AI)', null];
    default: return ['•', ev.type, ''];
  }
}

function renderTimeline(events) {
  return events.map(ev => {
    const [icon, lab, detail] = eventLabel(ev);
    const p = ev.props || {};
    let body = '';
    if (ev.type === 'chat_user' || ev.type === 'chat_ai') {
      body = `<div class="chat-bubble ${ev.type === 'chat_user' ? 'chat-user' : 'chat-ai'}">${esc(p.text)}</div>`;
    } else if (detail) body = `<span class="ev-detail">${esc(detail)}</span>`;
    return `<div class="ev"><span class="ev-time">${mmss(ev.sinceStart)}</span><span class="ev-icon">${icon}</span><div class="ev-main"><span class="ev-label">${esc(lab)}</span> ${body}</div></div>`;
  }).join('');
}

function renderSession(s) {
  const name = (s.name && s.name.trim()) ? s.name : 'anoniem';
  const fb = s.feedback;
  const badges = fb
    ? RATING_KEYS.filter(([k]) => typeof fb[k] === 'number').map(([k, l]) => `<span class="badge badge-secondary">${esc(l)} ${fb[k]}</span>`).join('')
      + (fb.wouldUse ? `<span class="badge ${fb.wouldUse === 'Ja' ? 'badge-good' : fb.wouldUse === 'Nee' ? 'badge-bad' : 'badge-mid'}">${esc(fb.wouldUse)}</span>` : '')
    : '<span class="badge badge-outline">geen feedback</span>';
  const fbBody = fb
    ? RATING_KEYS.map(([k, l]) => `<div class="kv"><span>${esc(l)}</span><b>${typeof fb[k] === 'number' ? fb[k] + '/5' : '–'}</b></div>`).join('')
      + (fb.improve ? `<div class="quote" style="margin-top:8px"><div class="quote-t">${esc(fb.improve)}</div></div>` : '')
    : '<div class="muted">Geen feedback ingevuld.</div>';
  return `<details class="card session">
    <summary>
      <div class="s-head"><div class="s-name">${esc(name)}<svg class="chev" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m9 18 6-6-6-6"/></svg></div>
      <div class="s-meta">${fmtDate(s.startLocal)} &middot; ${esc(s.deviceModel || '?')} &middot; ${fmtDur(s.durationSeconds)} &middot; ${s.events?.length || 0} events</div></div>
      <div class="s-badges">${badges}</div>
    </summary>
    <div class="s-content"><div class="s-cols">
      <div><div class="ctitle">Onboarding</div>
        <div class="kv"><span>Naam</span><b>${esc(name)}</b></div>
        <div class="kv"><span>Taken</span><b>${esc((s.gemeenteTaken || []).join(', ') || '–')}</b></div>
        <div class="kv"><span>Buurt-onderwerpen</span><b>${esc((s.buurtTopics || []).join(', ') || '–')}</b></div>
      </div>
      <div><div class="ctitle">Feedback</div>${fbBody}</div>
    </div>
    <div class="ctitle" style="margin-top:20px">Tijdlijn</div>
    <div class="timeline">${renderTimeline(s.events || [])}</div></div>
  </details>`;
}

// ---------- Hoofd ----------

export function renderHTML(sessions) {
  const a = analyze(sessions);
  const generated = new Date().toLocaleString('nl-NL', { dateStyle: 'full', timeStyle: 'short' });
  const completion = pct(a.finished, a.n);
  const scoreColor = a.satisfaction == null ? 'var(--muted-foreground)'
    : a.satisfaction >= 70 ? '#16a34a' : a.satisfaction >= 50 ? '#eab308' : '#ef4444';

  const overview = `
    <div class="scoregrid">
      <div class="card score">
        <div class="score-l">Tevredenheidsscore</div>
        <div class="score-v" style="color:${scoreColor}">${a.satisfaction != null ? a.satisfaction : '–'}<span>/100</span></div>
        <div class="progress big"><div style="width:${a.satisfaction || 0}%;background:${scoreColor}"></div></div>
        <div class="score-h">Gemiddelde van alle feedback-scores</div>
      </div>
      <div class="kpis">
        ${kpi(a.n, 'Sessies')}
        ${kpi(completion + '%', 'Onboarding afgerond', `${a.finished}/${a.n}`)}
        ${kpi(fmtDur(a.avgDur), 'Gem. sessieduur')}
        ${kpi(a.withFb, 'Feedback gegeven', `${pct(a.withFb, a.n)}% respons`)}
        ${kpi(a.chatCount, 'Chat-vragen')}
        ${kpi(a.totalEvents, 'Events totaal')}
      </div>
    </div>`;

  const feedback = section('Tevredenheid', 'Hoe beoordeelden deelnemers de app (1–5).',
    `<div class="ratings">${RATING_KEYS.map(([k, l]) => ratingRow(k, l, a.ratingAvg[k], a.ratingDist[k])).join('')}</div>
     <div class="rating-scale"><span>1 — slecht</span><span>5 — goed</span></div>
     <div class="ctitle" style="margin-top:22px">Zou je de app gebruiken?</div>
     ${segbar([
       { label: 'Ja', value: a.wouldUse.Ja, color: '#16a34a' },
       { label: 'Misschien', value: a.wouldUse.Misschien, color: '#eab308' },
       { label: 'Nee', value: a.wouldUse.Nee, color: '#ef4444' },
     ])}
     <div class="ctitle" style="margin-top:22px">Wat zou je verbeteren?</div>
     ${quotes(a.openAnswers, 'Nog geen open antwoorden.')}`);

  const behavior = section('Gebruik & gedrag', 'Welke schermen en functies gebruikten deelnemers, en waar eindigden sessies.',
    `<div class="two">
      <div><div class="ctitle">Schermen — bezoeken &amp; gem. tijd</div>
        ${hbar(a.screenStats.map(s => ({ label: s.label, value: s.visits, suffix: s.avgTime != null ? ` · ${fmtDur(s.avgTime)}` : '' })))}</div>
      <div><div class="ctitle">Meest getikte tegels</div>
        ${hbar(sortedBars(a.tileTaps, TILE_LABEL))}</div>
     </div>
     <div class="two" style="margin-top:18px">
      <div><div class="ctitle">Tab-wissels</div>${hbar(sortedBars(a.tabUse))}</div>
      <div><div class="ctitle">Waar eindigden sessies (laatste scherm)</div>${hbar(sortedBars(a.dropOff, SCREEN_LABEL))}</div>
     </div>`);

  const onboarding = section('Onboarding-keuzes', 'Wat kozen deelnemers bij de twee voorkeuren-vragen.',
    `<div class="two">
      <div><div class="ctitle">Gemeente-taken (→ home-tegels)</div>${hbar(sortedBars(a.gemeente, TILE_LABEL))}</div>
      <div><div class="ctitle">Buurt-onderwerpen (→ kaart)</div>${hbar(sortedBars(a.buurt))}</div>
     </div>
     <div class="two" style="margin-top:18px">
      <div><div class="ctitle">Afgerond vs. overgeslagen</div>
        ${segbar([{ label: 'Afgerond', value: a.finished, color: 'var(--good)' }, { label: 'Overgeslagen', value: a.skipped, color: 'var(--mid)' }])}</div>
      <div><div class="ctitle">Naam ingevuld</div>
        ${segbar([{ label: 'Met naam', value: a.named, color: '#3f3f46' }, { label: 'Anoniem', value: a.n - a.named, color: '#d4d4d8' }])}</div>
     </div>`);

  const chat = section('Wat vroegen mensen?', 'Alle vragen die deelnemers in de Regelen-assistent typten — rijke kwalitatieve data.',
    quotes(a.chatQuestions, 'Nog geen chat-vragen.'));

  return `<!doctype html>
<html lang="nl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>DH App — Testverslag</title>
<style>${STYLE}</style></head>
<body><div class="wrap">
  <header><h1>DH App — Testverslag</h1><div class="sub">Gegenereerd op ${generated} · ${a.n} sessies</div></header>
  ${a.n === 0 ? '<div class="card panel"><div class="muted">Nog geen sessies gevonden.</div></div>' : `
  ${overview}
  ${feedback}
  ${behavior}
  ${onboarding}
  ${chat}
  <h2 class="section-h">Sessies <span>(${a.n})</span></h2>
  ${sessions.map(renderSession).join('')}
  `}
</div></body></html>`;
}

const STYLE = `
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
  :root {
    --background: 240 6% 93%; --foreground: 240 10% 3.9%; --card: 0 0% 100%;
    --muted: 240 4.8% 95.9%; --muted-foreground: 240 4% 42%; --border: 240 5.9% 90%;
    /* Neutrale hoofdkleur (grijs/zwart). Kleur = alleen betekenis (goed/slecht). */
    --primary: 240 6% 25%; --secondary: 240 4.8% 95.9%; --secondary-foreground: 240 5.9% 12%; --radius: 1.4rem;
    --good: 142 71% 35%; --mid: 38 92% 45%; --bad: 0 84% 60%;
  }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: hsl(var(--background)); color: hsl(var(--foreground)); -webkit-font-smoothing: antialiased; }
  .wrap { max-width: 1120px; margin: 0 auto; padding: 52px 28px 110px; }
  h1 { font-size: 2rem; font-weight: 700; letter-spacing: -0.03em; margin: 0 0 6px; }
  .sub { color: hsl(var(--muted-foreground)); font-size: 0.95rem; margin-bottom: 32px; }
  .card { background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: var(--radius); box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.04); }
  .panel { padding: 28px 30px; margin-bottom: 22px; }
  .panel-h { margin-bottom: 22px; } .panel-h h3 { margin: 0; font-size: 1.1rem; font-weight: 600; letter-spacing: -0.01em; } .panel-h p { margin: 5px 0 0; color: hsl(var(--muted-foreground)); font-size: 0.875rem; }
  .ctitle { font-size: 0.72rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.07em; color: hsl(var(--muted-foreground)); margin-bottom: 14px; }
  /* overview */
  .scoregrid { display: grid; grid-template-columns: 300px 1fr; gap: 18px; margin-bottom: 22px; }
  .score { padding: 28px 30px; display: flex; flex-direction: column; justify-content: center; }
  .score-l { font-size: 0.82rem; font-weight: 500; color: hsl(var(--muted-foreground)); }
  .score-v { font-size: 3.4rem; font-weight: 700; letter-spacing: -0.04em; line-height: 1.05; margin: 6px 0 14px; }
  .score-v span { font-size: 1.1rem; color: hsl(var(--muted-foreground)); font-weight: 500; }
  .score-h { font-size: 0.78rem; color: hsl(var(--muted-foreground)); margin-top: 12px; }
  .kpis { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }
  .kpi { padding: 20px 22px; } .kpi-v { font-size: 1.7rem; font-weight: 700; letter-spacing: -0.02em; } .kpi-l { font-size: 0.82rem; color: hsl(var(--muted-foreground)); margin-top: 3px; } .kpi-h { font-size: 0.74rem; color: hsl(var(--muted-foreground)); margin-top: 5px; }
  .progress { height: 8px; background: hsl(var(--secondary)); border-radius: 999px; overflow: hidden; } .progress.big { height: 10px; } .progress > div { height: 100%; border-radius: 999px; }
  /* bars */
  .bars { display: flex; flex-direction: column; gap: 8px; }
  .bar-row { display: grid; grid-template-columns: 130px 1fr auto; align-items: center; gap: 10px; font-size: 0.82rem; }
  .bar-label { color: hsl(var(--foreground)); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .bar-track { height: 20px; background: hsl(var(--secondary)); border-radius: 999px; overflow: hidden; }
  .bar-fill { height: 100%; background: hsl(var(--primary)); border-radius: 999px; min-width: 4px; }
  .bar-val { color: hsl(var(--muted-foreground)); font-variant-numeric: tabular-nums; font-size: 0.78rem; white-space: nowrap; }
  /* ratings */
  .ratings { display: flex; flex-direction: column; gap: 10px; }
  .rating-row { display: grid; grid-template-columns: 140px 1fr 52px; align-items: center; gap: 12px; }
  .rating-name { font-size: 0.85rem; color: hsl(var(--muted-foreground)); }
  .rating-bar { height: 15px; border-radius: 999px; overflow: hidden; display: flex; background: hsl(var(--secondary)); }
  .rating-bar .seg { height: 100%; } .rating-bar .seg.empty { width: 100%; }
  .rating-avg { font-weight: 600; font-size: 0.875rem; text-align: right; } .rating-avg span { color: hsl(var(--muted-foreground)); font-weight: 400; font-size: 0.7rem; }
  .rating-scale { display: flex; justify-content: space-between; margin-top: 8px; font-size: 0.72rem; color: hsl(var(--muted-foreground)); padding-left: 152px; }
  /* segbar */
  .segbar { height: 24px; border-radius: 999px; overflow: hidden; display: flex; background: hsl(var(--secondary)); }
  .segbar-seg { height: 100%; } .legend { display: flex; gap: 18px; margin-top: 10px; font-size: 0.8rem; color: hsl(var(--muted-foreground)); flex-wrap: wrap; }
  .legend i { display: inline-block; width: 10px; height: 10px; border-radius: 999px; margin-right: 6px; vertical-align: -1px; }
  /* quotes */
  .quotes { display: flex; flex-direction: column; gap: 11px; }
  .quote { background: hsl(var(--muted)); border-radius: 16px; padding: 13px 16px; }
  .quote-t { font-size: 0.875rem; } .quote-t::before { content: '“'; } .quote-t::after { content: '”'; }
  .quote-a { font-size: 0.75rem; color: hsl(var(--muted-foreground)); margin-top: 4px; }
  .two { display: grid; grid-template-columns: 1fr 1fr; gap: 28px; }
  /* sessions */
  .section-h { font-size: 1.05rem; font-weight: 600; margin: 28px 0 12px; } .section-h span { color: hsl(var(--muted-foreground)); font-weight: 400; }
  details.session { margin-bottom: 10px; overflow: hidden; }
  summary { list-style: none; cursor: pointer; padding: 20px 24px; display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; transition: background .12s; }
  summary:hover { background: #fafafa; } summary::-webkit-details-marker { display: none; }
  details[open] > summary { border-bottom: 1px solid hsl(var(--border)); }
  .s-name { font-weight: 600; font-size: 1rem; display: flex; align-items: center; gap: 5px; }
  .chev { color: hsl(var(--muted-foreground)); transition: transform .15s; } details[open] .chev { transform: rotate(90deg); }
  .s-meta { color: hsl(var(--muted-foreground)); font-size: 0.8rem; margin-top: 2px; }
  .s-badges { display: flex; gap: 6px; flex-wrap: wrap; }
  .s-content { padding: 20px; } .s-cols { display: grid; grid-template-columns: 1fr 1fr; gap: 28px; }
  .badge { display: inline-flex; align-items: center; border-radius: 999px; padding: 3px 11px; font-size: 0.73rem; font-weight: 600; line-height: 1.45; }
  .badge-secondary { background: hsl(var(--secondary)); color: hsl(var(--secondary-foreground)); }
  .badge-outline { border: 1px solid hsl(var(--border)); color: hsl(var(--muted-foreground)); }
  .badge-good { background: hsl(var(--good) / 0.14); color: hsl(var(--good)); }
  .badge-mid { background: hsl(var(--mid) / 0.18); color: hsl(38 92% 33%); }
  .badge-bad { background: hsl(var(--bad) / 0.13); color: hsl(var(--bad)); }
  .kv { display: flex; justify-content: space-between; gap: 12px; font-size: 0.85rem; padding: 5px 0; border-bottom: 1px solid hsl(var(--border) / 0.6); }
  .kv span { color: hsl(var(--muted-foreground)); }
  .timeline { display: flex; flex-direction: column; }
  .ev { display: grid; grid-template-columns: 46px 22px 1fr; align-items: start; gap: 10px; padding: 5px 0; font-size: 0.875rem; }
  .ev-time { color: hsl(var(--muted-foreground)); font-variant-numeric: tabular-nums; font-size: 0.75rem; padding-top: 2px; }
  .ev-icon { text-align: center; } .ev-label { font-weight: 500; } .ev-detail { color: hsl(var(--muted-foreground)); }
  .chat-bubble { display: inline-block; margin-top: 5px; padding: 8px 12px; border-radius: 10px; max-width: 580px; white-space: pre-wrap; font-size: 0.85rem; line-height: 1.45; }
  .chat-bubble.chat-user { background: hsl(240 5% 90%); } .chat-bubble.chat-ai { background: hsl(var(--muted)); }
  .muted { color: hsl(var(--muted-foreground)); font-size: 0.875rem; }
  @media (max-width: 720px){ .scoregrid, .two, .s-cols, .kpis { grid-template-columns: 1fr; } .kpis { grid-template-columns: repeat(2,1fr); } }
`;
