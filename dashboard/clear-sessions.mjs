// Maakt de analytics-database leeg voor een schone testsessie.
//
// Verwijdert ALLE documenten in:
//   - sessions/{id}            (incl. de events-subcollectie per sessie)
//   - onboarding_sessions/{id}
//
// Auth: zet een service-account-key als ./serviceAccount.json (zelfde als generate.mjs),
// of gebruik gcloud Application Default Credentials.
//
// Gebruik (vanuit de map dashboard/):
//   node clear-sessions.mjs --yes
//
// Zonder --yes doet het script NIETS (alleen een telling), zodat je niet per ongeluk wist.

import { readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SA_PATH = join(__dirname, 'serviceAccount.json');

if (existsSync(SA_PATH)) {
  initializeApp({ credential: cert(JSON.parse(readFileSync(SA_PATH, 'utf8'))) });
} else {
  initializeApp({ credential: applicationDefault() });
}

const db = getFirestore();
const confirmed = process.argv.includes('--yes');

/** Verwijder alle documenten van een (sub)collectie-referentie in batches. */
async function deleteCollection(ref, batchSize = 300) {
  let deleted = 0;
  while (true) {
    const snap = await ref.limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted += snap.size;
    if (snap.size < batchSize) break;
  }
  return deleted;
}

async function run() {
  // Tellingen vooraf.
  const sessions = await db.collection('sessions').get();
  const onboarding = await db.collection('onboarding_sessions').get();
  console.log(`Gevonden: ${sessions.size} sessies, ${onboarding.size} onboarding-sessies.`);

  if (!confirmed) {
    console.log('\nDRY RUN — er is niets verwijderd. Voer uit met --yes om echt te wissen:');
    console.log('  node clear-sessions.mjs --yes');
    return;
  }

  let events = 0;
  for (const doc of sessions.docs) {
    events += await deleteCollection(doc.ref.collection('events'));
  }
  const delSessions = await deleteCollection(db.collection('sessions'));
  const delOnboarding = await deleteCollection(db.collection('onboarding_sessions'));

  console.log(`\nVerwijderd: ${delSessions} sessies, ${events} events, ${delOnboarding} onboarding-sessies.`);
  console.log('Database is leeg — klaar voor een schone testsessie.');
}

run().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
