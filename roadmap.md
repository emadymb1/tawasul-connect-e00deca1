# Tawasul School OS — Flutter mobile app roadmap

Source lives in `flutter_app/`. Nothing is run or hosted here; you build it locally with the Flutter SDK.

Server: `https://se.fiksutilitoimisto.fi/modules/Rest%20API/api.php/v2`
Auth: per-user login via `POST /auth/login` → `tok_...`, identity via `GET /auth/me`, renewal via `POST /auth/refresh`, sign-out via `POST /auth/logout`.
All data is live from the API. No mock data anywhere.

## Step 1 — Foundation (DONE)
- [x] Flutter project skeleton, dependencies, folder structure
- [x] Design system from the supplied screens (dark green / cream / red / gold, rounded cards)
- [x] Arabic first + English second, RTL/LTR switching, in-app language toggle
- [x] API client: base URL, bearer token, pagination (`page`, `pageSize`, `sort`, `search`, `fields`), dotted filter params, `gibbonSchoolYearID`, error envelope handling, 401 auto-refresh
- [x] Secure token storage, session restore on launch, logout
- [x] Real login screen wired to `/auth/login`
- [x] Role resolution from `/auth/me` → Student / Parent / Teacher / Admin portal routing
- [x] Portal shells with per-role bottom navigation
- [x] Student portal: timetable, homework, markbook, attendance (live)
- [x] Teacher, parent, admin dashboards: live first screens (lessons, children, notices, school stats)

## Step 2 — Teacher portal depth (DONE — code complete, not yet compiled)
- [x] Today's timetable from `/timetables`, `/timetable-days`, `/timetable-slots`, `/lessons`
- [x] Class roster from `/class-enrolments` + `/classes` + `/courses`
- [x] Take attendance: read `/attendance-codes`, write `/attendance` per student, class log via `/attendance-class-logs`
- [x] Markbook: `/markbook-columns` create + list, `/markbook-entries` read + PATCH grades and comments
- [x] Homework: create/edit `/planner-entry-homeworks`, review `/planner-entry-student-homeworks`, submissions files/links
- [x] Behaviour: record and list `/behaviour` with current school year
- [x] Lesson planner entries (create/edit)
- [x] Internal assessments: create columns + enter marks
- [x] Class hub reachable from the "Classes" tab in the teacher bottom bar
- [ ] First `flutter pub get && flutter analyze` locally — fix any small compile errors (no Flutter SDK in this workspace)

## Step 3 — Student portal depth (DONE — code complete, not yet compiled)
- [x] Full weekly timetable from `/timetables`, `/timetable-days`, `/timetable-slots`, grouped per cycle day
- [x] Homework list split into upcoming / past, tick-off via PATCH `/planner-entry-student-homeworks`
- [x] Markbook grouped per subject with per-subject average and `/grade-scales` + `/grade-scale-grades` descriptors
- [x] Attendance history with `/attendance-codes` names, reasons and attendance rate
- [x] Behaviour list plus positive/negative tally, house from `/students` + `/houses`
- [x] Reports from `/report-archive-entries` + `/report-archives`
- [x] Student bottom bar: Dashboard, Timetable, Homework, Markbook, More (attendance / behaviour / reports)

## Step 4 — Parent portal depth (DONE — code complete, not yet compiled)
- [x] Child switcher from `/family-adults` + `/family-children`, auto-selects the first child
- [x] Family record from `/families`
- [x] Per-child record page reusing the student screens: timetable, homework, markbook, attendance, behaviour, reports
- [x] Child summary cards: attendance rate, grade average, positive/negative behaviour
- [x] Invoices `/invoices` (filtered by `gibbonFinanceInvoicee.gibbonPersonID`), detail with `/invoice-fees`, and `/payments`
- [x] Meet the teacher bookings `/meet-the-teacher-bookings` (narrowed client-side to child + parent)
- [x] Data updater requests: POST `/person-updates` and `/family-updates` with status Pending, plus request history
- [x] Parent bottom bar: Dashboard, My children, Finance, Bookings, More

## Step 5 — Administrator portal (DONE — code complete, not yet compiled)
- [x] People tab with four searchable lists: `/students`, `/staff`, `/users`, `/roles`
- [x] School structure: `/school-years`, `/year-groups`, `/form-groups`, `/departments`, `/spaces`
- [x] Attendance overview: today's `/attendance-class-logs` against `/classes` → registers taken vs missing, with a rate card on the dashboard
- [x] Finance overview `/fees`, `/budgets`, `/expenses`
- [x] Staff absence and cover `/staff-absences`, `/staff-coverage`, `/substitutes`
- [x] `/logs` and `/api-logs` with status colouring
- [x] Admin bottom bar: Dashboard, People, School, Finance, Operations

## Step 6 — Cross-cutting school life (DONE — code complete, not yet compiled)
- [x] Messaging `/messages` list + detail, read receipts `/message-receipts`, targets `/messenger-targets`
- [x] Notifications `/notifications` with mark-as-read (PATCH status Archived) and unread badge on the bell icon in every portal's top bar
- [x] Notice stream `/stream-posts`
- [x] Calendar: upcoming `/calendar-events` and `/special-days`
- [x] Library: my loans + searchable catalogue `/library-items`, `/library-events`
- [x] Activities `/activities` with sign-up via POST `/activity-students`, my sign-ups status
- [x] Trips `/trips`, `/trip-days`
- [x] Help desk `/helpdesk-issues` list + new ticket (POST)
- [x] Person photo widget (`widgets/person_avatar.dart`)
- [x] Arabic + English strings for all of the above in `l10n/strings.dart`
- [x] Navigation: bell + "School life" hub buttons in the shared top bar (all four portals); extra "School life" section in the student and parent More tabs
- [ ] First compile locally: `cd flutter_app && flutter pub get && flutter analyze`

## Step 7 — Hardening and release (DONE — code complete, not yet compiled)
- [x] Permission-driven UI: every 403 is recorded in `core/permissions.dart`; `AsyncCard` hides the whole card, the school-life hub drops the refused rows and explains why
- [x] Offline cache (`core/offline_cache.dart`): last successful GET per request kept 3 days, served automatically when the phone cannot reach the server, cleared on sign-out
- [x] Offline banner in every portal top area plus `widgets/refreshable.dart`; pull-to-refresh works on short screens too (`AlwaysScrollableScrollPhysics` everywhere)
- [x] Device notifications: `core/local_notifications.dart` + `core/notification_watcher.dart` poll `/notifications` every 3 minutes while the app is open and raise a device notification for new items (no Firebase)
- [x] Arabic + English checked for every key in `l10n/strings.dart` (new: offline, showingSavedData, offlineNoSavedData, pullToRefresh, hiddenByPermissions, deviceNotifications, lastUpdated)
- [x] App icon `assets/icon/app_icon.png`, `flutter_launcher_icons` + `flutter_native_splash` config in `pubspec.yaml`
- [x] Release guide and draft store metadata in `docs/RELEASE.md`
- [ ] Local run: `cd flutter_app && flutter create . --platforms=android,ios --org fi.fiksutilitoimisto --project-name tawasul && flutter pub get && flutter analyze`
- [ ] Background push while the app is closed (needs a push service + a server-side hook) — decide if you want it

## Step 8 — Your call next
- [x] Apply the supplied Tawasul icon while preserving the previous icon
- [x] Animated in-app splash using the supplied icon
- [x] English app name `Tawasul School OS` and Arabic app name `نظام تواصل المدرسي`
- [x] Mobile back history plus bilingual close-app confirmation on the main tab
- [ ] Generate native icons/splash and install the supplied Android/iOS localised-name resources during the first local build
- [ ] First device build and a walk-through of each portal with a real account per role
- [ ] Anything missing from the four portals after that walk-through

## Step 9 — Admin "Manage" browser: every server resource (DONE — code complete, not yet compiled)
- [x] `features/admin/resource_catalog.dart` generated from `docs/api_docs.txt`: all 343 resources with module, methods and filters
- [x] `core/openapi_schema.dart` reads `/openapi.json` once and gives each resource its form fields (type, enum, required) and primary key
- [x] `features/admin/manage_repository.dart` generic list / read / create / update (PATCH or PUT) / delete
- [x] `features/admin/manage_pages.dart`: category home with search, resource list with server search + documented filters + paging, record detail (long-press copies a value), create / edit form, delete with confirmation
- [x] `ApiClient.put` and `ApiClient.getRaw`
- [x] New "Manage" tab in the admin bottom bar; 403 hides a resource from the list
- [x] Arabic + English strings for all of the above
- [ ] Compile locally, then open Manage → People → Users and confirm the create form shows the fields from `/openapi.json`
- [ ] Decide which resources deserve a hand-designed screen on top of the generic browser (suggested first: users, students, staff, classes, class-enrolments, courses, invoices, messages)

## Step 10 — School year switcher + bulk actions (DONE — code complete, not yet compiled)
- [x] `core/school_year.dart`: `SchoolYear` model, `apiSchoolYearsProvider` (`/school-years`), `selectedSchoolYearProvider`, `setSchoolYear()`
- [x] `ApiClient.defaultSchoolYearId` keeps the account's own year so the switcher can return to it
- [x] Every repository provider (admin, manage, community, parent, school, student, teacher) watches `selectedSchoolYearProvider`, so switching the year reloads all open screens
- [x] `widgets/school_year_switcher.dart`: top-bar button + dialog, shown only in the admin portal; the icon turns red while working outside your own year
- [x] Bulk actions in the Manage browser: select mode in the resource list, per-row checkboxes, "select all on this page", bottom bar with the count and a bulk delete that reports how many succeeded and keeps the failures selected
- [x] Arabic + English strings for all of the above
- [ ] Compile locally, then: admin → year switcher → Manage → any deletable resource → select → delete
- [ ] Curated admin screens for the top resources (person editor with role picker, class enrolment with student search, invoice creation with fee items) — still open, the generic Manage forms cover them meanwhile
- [ ] Server side: the 81 GET-only resources (settings, permissions, timetable structure, school terms, messages, modules …) cannot be edited from any app until the API gains write methods — see `docs/ADMIN_COVERAGE.md`

## Step 11 — Administrator portal: a page for every server module (DONE — code complete, not yet compiled)
- [x] `features/admin/module_pages.dart`: module hub listing all 51 server modules as tiles with resource counts, bilingual module names (Arabic map) and an icon each
- [x] Module search across module name, page name, path and description
- [x] `AdminModulePage`: one page per module with "pages" and "editable" totals and every resource in that module, each showing a live record count badge and a read-only pill where the API has no write methods
- [x] Every module page opens the shared Manage engine (list, search, filters, paging, create, edit, delete, bulk delete) — nothing duplicated
- [x] 403 responses hide a resource from its module page and from the count, so each admin only sees what the server allows
- [x] Entry points: a "Browse by module" card at the top of the Manage tab and on the admin dashboard
- [x] Arabic + English strings for all of the above
- [ ] Compile locally, then: admin → dashboard → Browse by module → e.g. Finance → Invoices

## Step 12 — Curated people screens for administrators (DONE — code complete, not yet compiled)
- [x] Fixed three duplicate getters/keys in `l10n/strings.dart` (`save`, `saved`, `schoolYear`) that would have failed `flutter analyze`
- [x] `features/admin/people_repository.dart`: `/users` create + PATCH, `/students` enrolment create / PATCH / DELETE, `/class-enrolments` add / change role / remove, lookups for `/roles`, `/houses`, `/year-groups`, `/form-groups`, person and class search
- [x] `features/admin/people_pages.dart`:
  - `PersonDetailPage` — hero, account details, student enrolments card, class enrolments card (add / remove)
  - `PersonFormPage` — new / edit user with role picker from `/roles`, status, can-login switch, house, date-of-birth picker; PATCH sends only changed fields
  - `StudentEnrolmentFormPage` — person picker, year group + form group dropdowns, roll order; created in the working school year
  - `PersonPickerSheet`, `ClassPickerSheet` (server search) and `ClassMembersPage` (everyone in a class, add / remove)
- [x] People tab: every student / staff / user row opens the person page; "New user" and "Enrol as student" buttons; new "Classes" tab → class members
- [x] Arabic + English strings for all of the above
- [ ] Compile locally: `cd flutter_app && flutter pub get && flutter analyze`, then People → Users → New user
- [ ] Next curated screens (still served by the generic Manage forms meanwhile): courses + classes creation, family links (`/families`, `/family-adults`, `/family-children`), staff records (`/staff` POST), activity and trip management

## Open items needing you
- [ ] Rotate the API key that was pasted in chat (Manage API Keys) — treat the old one as exposed.
- [ ] Confirm which roles in `/roles` map to Teacher vs Support Staff vs Admin at your school if the defaults differ.

## Step 13 — API v2 capabilities from the new documentation (DONE — code complete, not yet compiled)
Source: `docs/api_docs_v2.txt` (Gibbon REST API 3.3.00 developer reference, uploaded 2026-09-18).
The old `docs/api_docs.txt` is kept unchanged for reference.

What is new on the server compared with the first documentation:
- PUT (full replace) on nearly every resource, and many previously GET-only resources are now writable
- `POST /{resource}/bulk` — up to 500 creates / updates / deletes in one transaction
- `GET /{resource}/export` — whole-resource CSV export
- `GET /{resource}/distinct?field=` and `GET /{resource}/aggregate?by=` — filter values and grouped counts
- `GET /{resource}/{id}/{relation}` — relation traversal
- `/files/{resource}/{id}/{field}` — list, download, upload and delete attachments (when the admin enables file transfer)
- Composite endpoints: `/students/{id}/profile`, `/staff/{id}/profile`, `/families/{id}/profile`,
  `/courses/{id}/overview`, `/students/{id}/finance`, `/students/{id}/timetable`, `/classes/{id}/roster`
- Webhooks (`/webhooks`, `/events`) and `POST /batch`
- Meta endpoints: `/health`, `/stats`, `/dashboard`, `/permissions`, `/analytics`, `/resources`, `/scopes`
- New error envelope `{"error":{"code","message"},"meta":{"requestID"}}`

Done in the app:
- [x] `core/api_client.dart`: v2 error envelope parsing; `bulk`, `bulkDelete`, `exportCsv`, `distinct`,
      `aggregate`, `relation`, all seven composite helpers, `batch`, file list/upload/delete/url,
      `health`, `stats`, `dashboard`, `permissions`, `analytics`, `me`, `resources`, `scopes`,
      `webhookEvents`, `logout`
- [x] `core/server_capabilities.dart`: live providers for all meta endpoints plus `LiveResource`,
      and a merged catalogue (live `/resources` overlaid on the bundled catalogue)
- [x] Manage browser now lists resources from the live registry, so new server resources appear
      without an app update; each resource list has a CSV export action
- [x] `features/admin/system_pages.dart`: admin System screen (health, school statistics, API activity,
      resource registry totals, my permissions, current credential, webhook subscriptions with add/delete)
      reachable from the admin app bar
- [x] Arabic + English strings for all of the above
- [ ] Compile locally: `cd flutter_app && flutter pub get && flutter analyze`
- [ ] Next: use the composite endpoints to replace multi-call profile screens (student, staff, family,
      class roster), bulk attendance / markbook saving via `/bulk`, and attachment upload where the
      server has file fields

## Step 14 — APK delivery (added 2026-09-19)
- Added GitHub Actions workflow `.github/workflows/android-apk.yml` that builds a release APK artifact.
- Added `docs/BUILD_APK.md` with both the GitHub and local build routes.
- No Flutter/Android toolchain exists in Lovable, so the APK is produced on GitHub or locally.
