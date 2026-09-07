# Troubleshooting

## "It just hangs / times out" — your cloud provider is probably blocking the port

This is, by far, the most common reason a first attempt fails, and it has
nothing to do with ZeroSMTP configuration. Many cloud and hosting providers
block outbound SMTP ports by default on new accounts, specifically to fight
spam:

| Provider | Default outbound SMTP behavior |
| --- | --- |
| AWS EC2 / Lightsail | Port 25 blocked by default on all accounts; a support ticket ("EC2 email sending limit removal") is required to lift it. Ports 587/465 are generally not blocked. |
| Google Cloud (GCE) | Port 25 blocked; 587/465 generally allowed. |
| Microsoft Azure | Port 25 blocked on most subscription types; 587/465 generally allowed. |
| DigitalOcean | Port 25 blocked by default for new accounts; can be requested to be lifted via support. 587/465 generally allowed. |
| Hetzner | Similar default restrictions on port 25; open a support ticket if outbound mail is core to your use case. |
| Home / office network (ISP) | Residential ISPs very commonly block outbound 25, and sometimes 587, to stop compromised machines from spamming. Check your ISP's Acceptable Use Policy. |

**This is why every example in this repository defaults to port `465`
(implicit SSL/TLS) or `587` (STARTTLS), never port `25`.** If a script hangs
until it times out rather than failing immediately, this is the first thing
to check. Run the connectivity-only check — no credentials needed, no email
sent, and the conversation stops after `EHLO`:

```bash
npx zerosmtp-check
```

Nothing to install and nothing to clone. It tests 25, 587 and 465 from the
machine that is actually failing, which is the only place the answer means
anything. Port 25 is included because it is the one this table is mostly
about — it is checked for reachability, not as a route to send by, and the
output says so.

Already have the repository checked out, or working on a box with no Node?

```bash
./check-connection.sh
```

```powershell
./check-connection.ps1
```

Both live in the [repository](https://github.com/msgwing/ZeroSMTP). They
resolve the host, connect on 587 and 465, do the STARTTLS or implicit-TLS
handshake, check whether *this machine's* trust store accepts the
certificate, and list the `AUTH` mechanisms the server offers.

They work against any SMTP host, which is the point when you are trying to
establish whether the problem is the server or your network — pass the
hostname as an argument.

If you would rather not clone anything, the two one-liners below need nothing
installed at all:

```bash
# Bash/Linux/macOS — quick manual connectivity check
curl -v --connect-timeout 10 telnet://mx.msgwing.com:587
curl -v --connect-timeout 10 telnet://mx.msgwing.com:465
```

```powershell
# Windows PowerShell
Test-NetConnection -ComputerName mx.msgwing.com -Port 587
Test-NetConnection -ComputerName mx.msgwing.com -Port 465
```

If both time out from a cloud VM but work from your home network, contact
your provider's support to unblock outbound SMTP for your account/instance.

## Authentication failed

- Confirm you copied the login/password from [msgwing.com](https://msgwing.com)
  exactly — the password is shown once, right after activation.
- Confirm your account is activated (registration alone is not enough).
- Confirm the environment variables are actually set: a typo like `USERNAME`
  instead of `ZEROSMTP_USERNAME` will silently fall back to a placeholder
  value or (on Windows) your OS login name — see the note in
  [`.env.example`](https://github.com/msgwing/ZeroSMTP/blob/main/.env.example).

## Authentication failed against Microsoft 365, not against us

Everything above assumes the server refusing you is this relay. If you are
still pointed at `smtp.office365.com`, `smtp-mail.outlook.com` or Gmail, the
refusal is theirs and the cause is probably not your password.

Microsoft is switching off Basic authentication - username and password - for
SMTP AUTH in Exchange Online at the end of December 2026. Devices and scripts
that have worked for years start being refused on a day nobody touched them,
with the password still correct.

Find out which it is without guessing:

```bash
npx zerosmtp-check --explain "535 5.7.139 Authentication unsuccessful"
```

Paste whatever your own client printed rather than what you think it means. A
Postfix SASL line, a Python traceback, a code off a printer panel and
`curl: (67) Login denied` are frequently the same refusal, and `curl` shows
none of the server's text at all.

- [Every SMTP AUTH error and what it means](ERROR-MESSAGES.md) - seventeen
  strings, each with whether the cause can still be turned back on
- [What to do about the shutdown](EXCHANGE-ONLINE-SMTP-AUTH.md) - including the
  options that are not this project
- [Which devices have OAuth firmware](DEVICE-COMPATIBILITY.md)

Three of the four causes are still reversible before the deadline, so somebody
telling you to migrate today may be wrong. Check which case you are in first.

## `553 5.7.1 ... Sender address rejected: not owned by user`

The full refusal looks like this:

```
553 5.7.1 <root@yourhost>: Sender address rejected: not owned by user
you@msgwing.com
```

**Authentication succeeded.** The password is right and the account is fine.
What was refused is the *From* address: you logged in as one account and then
asked to send as somebody else. A shared relay cannot allow that — if it did,
anyone with an account could send as anyone.

Mail must leave as the account it was sent with. Nothing else is accepted, and
this cannot be configured per account.

### Where it usually comes from

Almost never from an application you wrote. Two situations produce nearly all
of these:

**A Linux host sending its own system mail.** `cron`, `logwatch`,
`unattended-upgrades`, `systemd` failure notifications and `mdadm` all send as
the local system user — `root@yourhost`, `pi@raspberrypi`, `backup@nas`. Postfix
in satellite mode passes that straight through unless it is told to rewrite it.
See [rewriting the sender in the system MTA guide](SYSTEM-MTA.md#making-mail-leave-as-your-account-sender-rewriting),
which is the fix.

**A device or client set to "use my real email as the From address."** Printers,
scanners, NAS boxes and DVRs often have a *From* or *Sender* field separate from
the login. Put the `@msgwing.com` account address in it, not a personal Gmail,
Outlook or company address. That personal address is what receives the replies —
which is what the `Reply-To` field is for, and that one is unrestricted.

## Certificate / TLS verification failed

> On a printer or scanner this is usually the frozen root store rather than
> anything wrong: [Printer cannot verify the mail server
> certificate](PRINTER-CERTIFICATE-ERROR.md).

- Do not disable certificate verification to "fix" this (no code example in
  this repo does, and none should) — a cert error almost always means an
  intercepting proxy, an outdated system CA bundle, or a wrong hostname, not
  a problem with `mx.msgwing.com` itself.
- Make sure you're connecting to `mx.msgwing.com` (not an IP address) so
  hostname verification succeeds.
- Update your system's CA certificate bundle if it's very old — this is
  especially common on embedded devices (printers, scanners) whose firmware
  has a fixed, non-updatable root CA store that predates Let's Encrypt's
  `ISRG Root X1` root. One confirmed case is documented in
  [PRINTERS.md](PRINTERS.md#known-exception-canon-maxify-mb2755)
  (Canon Maxify MB2755) — treat disabling verification as a last resort for
  that specific class of device, not a general fix.

## Which port should I use?

- **587 (STARTTLS)** — the safest default; supported by nearly every SMTP
  client, library, and printer.
- **465 (Implicit SSL/TLS)** — use this if your client/device offers an
  explicit "SSL" mode separate from "STARTTLS"/"TLS", or if your network
  blocks STARTTLS negotiation on 587 but allows 465. Treat 465 as a
  fallback, not a first choice, once 587 has been confirmed to work.
  (An earlier version of this note cited the Canon Maxify MB2755 as a case
  where 587 avoided a certificate issue that 465 had — that turned out to
  depend on which certificate chain the server happened to be presenting at
  the time, not the port. See the
  [current MB2755 write-up](PRINTERS.md#known-exception-canon-maxify-mb2755).)
- **25** — not supported by ZeroSMTP for client submission, and blocked by
  most providers anyway (see above).

## Sending limits (rate limiting)

Each ZeroSMTP account is rate-limited to keep the shared `msgwing.com`
domain reputation high for everyone. Current limits (subject to change):

| Window | Sustained rate | Short burst allowance |
| --- | --- | --- |
| Per minute | 5 messages/minute | up to 20 |
| Per hour | 50 messages/hour | up to 100 |
| Per day | 200 messages/day | 200 (hard cap, no extra burst) |

Additionally, a single message can address **at most 15 recipients**
(To + Cc + Bcc combined).

If you hit a limit, the server will reject or temp-fail the send — treat
that the same as any other transient SMTP error: back off and retry later
rather than looping immediately (see [RELIABILITY.md](RELIABILITY.md)).
These limits are sized for typical transactional use (notifications,
password resets, contact forms, scan-to-email); if your application needs
sustained volume above them, contact abuse@msgwing.com before you build
around it.

**We do not offer a paid tier for high-volume or bulk sending** (e.g.
tens/hundreds of thousands of messages per day) — ZeroSMTP, including any
future paid option, stays scoped to transactional email on the shared
`msgwing.com` domain. For that kind of volume, use a dedicated bulk-sending
platform instead; for example, [EmailLabs](https://emaillabs.io/) is a
Polish provider suited to that use case — a proven solution we can
personally vouch for, having used it while supporting a large
banking-sector company, primarily for marketing and sales email
campaigns.

## This project cannot receive email

ZeroSMTP is outgoing-only: there is no inbox, IMAP, or POP3 access tied to a
`@msgwing.com` account. If a test message doesn't "come back", that's
expected — send it to a mailbox you actually control (e.g. your personal
email, or a service like [mail-tester.com](https://mail-tester.com)) to
verify delivery, as shown in
[`SendEmailTest_mail-tester.com.ps1`](https://github.com/msgwing/ZeroSMTP/blob/main/SendEmailTest_mail-tester.com.ps1).

## Still stuck?

Contact abuse@msgwing.com, or open an issue on this repository with:
the language/example you're using, the exact error message, and which port
you tried.
