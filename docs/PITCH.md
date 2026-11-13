# Monday: how to present this

## Before you go
- Apply on the BrighterMonday listing too (job reference KL-TECH-001), so you are in their system.
- Put the CV, a one-page printout of the architecture diagram (from the README), and the GitHub link in a folder.
- Charge the phone. Have the app running with the API and connector on your laptop **before** you walk in,
  and keep a screen recording of the full flow as a backup in case the Wi-Fi misbehaves.
- Ask at reception for the **Technology Manager** (the listing says the role reports to them). If they are not
  in, leave the CV and demo link with HR and ask for a name and email to follow up.

## Be honest about how it was built
Say it plainly: you built it over a few days, learning Flutter as you went, with an AI assistant as a pair
programmer, and you can walk through every part. That is true, increasingly normal, and much safer than
implying years of Flutter. **Only say it if you can back it up**, so before Monday read the code until you can
explain each file. Practise the "change something live" test: be able to add a field or a status yourself.

## The 2-minute pitch
1. **Why I built it (15 s):** "I saw the mobile developer role and wanted to show what I would build for you,
   not just describe it."
2. **Show the driver flow (45 s):** log in as a driver, open a trip, mark picked up, log fuel, report a delay,
   mark delivered.
3. **Show the manager view (30 s):** the overview updates, then the ERP tab shows the events syncing.
4. **The one design point (30 s):** "Every field event is saved with an outbox record in one transaction, so
   if the ERP is down, drivers are not blocked and nothing is lost. A Python connector delivers them with
   retries and idempotency."

## Questions you will probably get, with honest answers
- **"Have you used Flutter before?"** "This is my first Flutter project. I have shipped React Native apps
  (FlowPesa, tested on real Android and iOS devices), so the concepts carried over."
- **"Do you know our ERP?"** "Not yours specifically. I have integrated mobile-money APIs and written the
  mapping and retry layer here, so I would learn your ERP's API and data model first."
- **"What would you add next?"** Offline queue for poor network, GPS on each status change, proof-of-delivery
  photo, push notifications, HTTPS and a production database.
- **"Why a transactional outbox?"** Because the app and the ERP fail independently. This gives
  at-least-once delivery without blocking drivers.
- **"How would you secure it?"** HTTPS, short-lived tokens with refresh, role checks on the server (already
  done), rate limiting (login already throttled), secrets in environment variables, audit log.

## What not to do
- Don't claim logistics, ERP or Flutter experience you do not have.
- Don't badmouth other candidates or your previous employers.
- Don't leave without a next step: a name, an email, or "may I follow up on Thursday?".
