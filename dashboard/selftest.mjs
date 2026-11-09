// Rendert het dashboard met verzonnen data (geen Firebase): `node selftest.mjs`.
import { writeFileSync } from 'fs';
import { renderHTML } from './render.mjs';

const ev = (type, sinceStart, props) => ({ type, sinceStart, props });

function makeSession(o) {
  return {
    deviceModel: 'iPhone', appVersion: '1.0.0', build: '15',
    startLocal: o.start, durationSeconds: o.dur,
    name: o.name || '', gemeenteTaken: o.gem || [], buurtTopics: o.buurt || [],
    feedback: o.fb, events: o.events,
  };
}

const sessions = [
  makeSession({
    name: 'Fabian', start: '2026-06-04T14:12:00', dur: 214,
    gem: ['afspraak', 'parkeren', 'ooievaarspas'], buurt: ['bouwplannen', 'evenementen'],
    fb: { ease: 4, findability: 3, clarity: 5, looks: 4, wouldUse: 'Ja', improve: 'De kaart laadde eerst traag.' },
    events: [
      ev('session_start', 0), ev('onboarding_step', 3, { step: 1 }), ev('digid_login', 6),
      ev('onboarding_finish', 40, { skipped: false }),
      ev('screen_view', 41, { name: 'home' }), ev('tap_tile', 55, { dest: 'parkeren' }),
      ev('screen_exit', 60, { name: 'home', seconds: 19 }),
      ev('tab_switch', 70, { tab: 'regelen' }), ev('screen_view', 70, { name: 'regelen' }),
      ev('chat_user', 78, { text: 'Hoe vraag ik een nieuw paspoort aan?' }),
      ev('chat_ai', 82, { text: 'Je kunt online een afspraak maken bij het stadhuis.' }),
      ev('tab_switch', 120, { tab: 'buurt' }), ev('screen_view', 120, { name: 'buurt' }),
      ev('buurt_filter', 126, { filter: 'evenementen' }), ev('open_buurt_detail', 133, { title: 'Beach Cleanup' }),
      ev('screen_view', 133, { name: 'buurt_detail' }), ev('open_feedback', 190),
      ev('feedback_submit', 205, {}), ev('session_end', 214, { seconds: 214 }),
    ],
  }),
  makeSession({
    name: 'Sara', start: '2026-06-04T15:02:00', dur: 162,
    gem: ['zwemmen', 'afspraak'], buurt: ['sport', 'wegwerk'],
    fb: { ease: 5, findability: 4, clarity: 4, looks: 5, wouldUse: 'Ja', improve: 'Heel duidelijk!' },
    events: [
      ev('session_start', 0), ev('digid_login', 5), ev('onboarding_finish', 35, { skipped: false }),
      ev('screen_view', 36, { name: 'home' }), ev('tap_tile', 50, { dest: 'zwemmen' }),
      ev('screen_exit', 55, { name: 'home', seconds: 19 }),
      ev('tab_switch', 80, { tab: 'buurt' }), ev('screen_view', 80, { name: 'buurt' }),
      ev('chat_user', 100, { text: 'Waar kan ik zwemmen in de buurt?' }), ev('chat_ai', 104, { text: '...' }),
      ev('feedback_submit', 150, {}), ev('session_end', 162, { seconds: 162 }),
    ],
  }),
  makeSession({
    name: '', start: '2026-06-04T13:40:00', dur: 58,
    gem: ['overlast'], buurt: [],
    events: [
      ev('session_start', 0), ev('onboarding_finish', 30, { skipped: true }),
      ev('screen_view', 31, { name: 'home' }), ev('tab_switch', 45, { tab: 'hulp' }),
      ev('screen_view', 45, { name: 'hulp' }), ev('session_end', 58, { seconds: 58 }),
    ],
  }),
  makeSession({
    name: 'Mehmet', start: '2026-06-04T16:20:00', dur: 121,
    gem: ['parkeren', 'grofvuil', 'ooievaarspas'], buurt: ['evenementen', 'participatie'],
    fb: { ease: 3, findability: 2, clarity: 4, looks: 4, wouldUse: 'Misschien', improve: 'Ik kon de afvalkalender niet vinden.' },
    events: [
      ev('session_start', 0), ev('digid_login', 4), ev('onboarding_finish', 38, { skipped: false }),
      ev('screen_view', 39, { name: 'home' }), ev('tap_tile', 55, { dest: 'grofvuil' }),
      ev('tap_tile', 70, { dest: 'ooievaarspas' }), ev('open_ooievaarspas', 70),
      ev('screen_exit', 80, { name: 'home', seconds: 41 }),
      ev('open_feedback', 100), ev('feedback_submit', 115, {}), ev('session_end', 121, { seconds: 121 }),
    ],
  }),
];

writeFileSync(new URL('./dashboard.html', import.meta.url), renderHTML(sessions));
console.log('✅ test-dashboard geschreven naar dashboard.html');
