// Vercel serverless functie: leest live uit Firestore en rendert het dashboard.
// Vereist de env-var FIREBASE_SERVICE_ACCOUNT (volledige service-account-JSON).

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { renderHTML } from '../render.mjs';

function getDb() {
  if (!getApps().length) {
    const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    initializeApp({ credential: cert(sa) });
  }
  return getFirestore();
}

async function fetchData(db) {
  const snap = await db.collection('sessions').orderBy('startTime', 'desc').get();
  const sessions = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    const ev = await db.collection('sessions').doc(doc.id)
      .collection('events').orderBy('timestamp', 'asc').get();
    data.id = doc.id;
    data.events = ev.docs.map(e => e.data());
    sessions.push(data);
  }
  return sessions;
}

const configPage = `<!doctype html><html lang="nl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DH App — Testverslag</title>
<body style="font-family:-apple-system,sans-serif;max-width:640px;margin:60px auto;padding:0 22px;color:#1a1a1a;line-height:1.5">
<h1 style="color:#248641">DH App — Testverslag</h1>
<p>Het dashboard staat live, maar mist nog de lees-credentials.</p>
<ol>
<li>Download een service-account-key: Firebase Console → projectinstellingen → Service-accounts → <b>Nieuwe private key</b>.</li>
<li>Voeg in Vercel een environment variable <code>FIREBASE_SERVICE_ACCOUNT</code> toe met de <b>volledige inhoud</b> van dat JSON-bestand.</li>
<li>Deploy opnieuw (of <code>vercel --prod</code>).</li>
</ol>
<p style="color:#888">Daarna verschijnen hier automatisch de sessies en scores.</p>
</body></html>`;

export default async function handler(req, res) {
  res.setHeader('content-type', 'text/html; charset=utf-8');
  res.setHeader('cache-control', 'no-store');
  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    return res.status(200).send(configPage);
  }
  try {
    const sessions = await fetchData(getDb());
    return res.status(200).send(renderHTML(sessions));
  } catch (e) {
    return res.status(500).send(`<pre style="padding:20px;font-family:monospace">Fout bij ophalen: ${String(e)}</pre>`);
  }
}
