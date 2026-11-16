# Organization provisioning (v1.8)

## Wizard (Admin web → Organizations → New organization)

1. **Profile:** names (ka/en/ru), legal name, registration number, type
   (sports school, club, children's academy, independent coach, other),
   funding (government, private, nonprofit, mixed, other), address, city,
   contact email and phone, logo URL, description, sports, time zone, default
   language, primary color (WCAG 4.5:1 contrast with white text is required).
2. **Template and package:** optional template, package, initial
   subscription (trial or active). Funding type never switches payments on
   or off by itself.
3. **Initial features:** only features of the package can be chosen; missing
   dependencies are listed with an explicit "Enable required features".
4. **Initial administrator:** phone and/or email. An invitation is created
   and its link/code is shown **once** to the Super Admin.

Validation codes (`ProvisionRequest.validate`, mirrored by the callable):
`orgName`, `orgAddress`, `orgCity`, `orgEmail`, `orgPhone`, `orgSports`,
`orgAdminMissing`, `featureDependencies`, `brandContrast`, `notInPackage:*`,
`templateArchived`.

## Atomic / recoverable

- **Stable unique id:** `org-<slug of the English name>-<suffix>` (random hex on
  Firebase, a sequence in the demo); fixed at creation and never reused.
- **Two phases:** everything is written with `provisioning: provisioning`
  (not usable: rules and app treat the organization as off), then flipped to
  `ready` in a versioned write with history `org.provision`.
- Demo backend: a snapshot is restored if any step fails (nothing
  half-created remains).
- Firebase: the club, the configuration and the invitation are created in
  one batch; a failure before the flip leaves an organization in
  `provisioning`, which the Overview reports as **Provisioning not
  finished** so it can be completed or archived. Nothing is ever usable
  half-provisioned.

## Templates

Built-ins: Government Sports School (payments off; rooms, student accounts,
Brain Academy on), Private Sports Club (payments on), Children's Sports
Academy, Independent Coach. Admin web → **Organization templates**: create,
edit, duplicate, archive/restore. Archived templates cannot be used for new
organizations.

Applying a template to an **existing** organization (Organization →
Settings → Apply template) first shows a preview (`TemplateDiff`: features
added/removed, package change), then requires a reason and is a versioned
change. Historical data is not deleted.

## Administrator invitations

- Token: 256-bit random; only its hash is stored (`SHA-256` on the server,
  FNV-1a in the demo). Valid 7 days.
- Bound to the invited phone when one is given.
- Accept → organization-admin claims for **that** organization only;
  single use. Reject, revoke, resend (new token, old one invalid), expiry.
- Transfer: an invitation with `transferFrom` removes the previous admin's
  role on acceptance; an organization admin may only hand over their own
  role.
- Accept/reject UI: the admin web permission-denied page has an
  "invitation code" field; the invitation link pre-fills it
  (`?token=`).
- Delivery: no email/SMS is sent (no provider configured) — the Super Admin
  shares the link.

Demo: Nino (demo parent) has a pending invitation to Saburtalo Sports Club
with the code `demo-invite-saburtalo-2026`.
