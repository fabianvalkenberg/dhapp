// Genereert een zelf-bevattend HTML-testverslag uit de Firestore-analytics.
//
// Gebruik:
//   1) Zet een service-account-key als ./serviceAccount.json (zie README.md)
//   2) npm install
//   3) npm run build   →  schrijft dashboard.html  →  open in je browser
//
// Het script leest alleen (read-only) uit `sessions` + `sessions/{id}/events`.

import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { renderHTML } from './render.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SA_PATH = join(__dirname, 'serviceAccount.json');
const OUT_PATH = join(__dirname, 'dashboard.html');

function initFirebase() {
  if (existsSync(SA_PATH)) {
    initializeApp({ credential: cert(JSON.parse(readFileSync(SA_PATH, 'utf8'))) });
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    initializeApp({ credential: applicationDefault() });
  } else {
    console.error('\n❌ Geen service-account gevonden.');
    console.error('   Download een private key (Firebase Console → Projectinstellingen →');
    console.error('   Service-accounts → Nieuwe private key) en sla op als:');
    console.error('   ' + SA_PATH + '\n');
    process.exit(1);
  }
}

async function fetchData(db) {
  const sessionsSnap = await db.collection('sessions').orderBy('startTime', 'desc').get();
  const sessions = [];
  for (const doc of sessionsSnap.docs) {
    const data = doc.data();
    const evSnap = await db.collection('sessions').doc(doc.id)
      .collection('events').orderBy('timestamp', 'asc').get();
    data.id = doc.id;
    data.events = evSnap.docs.map(e => e.data());
    sessions.push(data);
  }
  return sessions;
}

(async () => {
  initFirebase();
  const db = getFirestore();
  console.log('Sessies ophalen…');
  const sessions = await fetchData(db);
  const html = renderHTML(sessions);
  writeFileSync(OUT_PATH, html);
  console.log(`✅ ${sessions.length} sessies → ${OUT_PATH}`);
})().catch(err => { console.error(err); process.exit(1); });
