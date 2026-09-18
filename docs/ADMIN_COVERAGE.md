# هل يغطي التطبيق كل السيرفر؟ / Does the app cover the whole server?

_آخر تحديث: الخطوة 12 — Last updated: Step 12_

**الخطوة 12:** شاشات مصممة يدوياً للأشخاص (إنشاء/تعديل مستخدم مع اختيار الدور، تسجيل الطالب في الصف والفصل الإرشادي، إضافة/إزالة من الفصول الدراسية) فوق محرك الإدارة الشاملة. / **Step 12:** hand-designed people screens (user create/edit with role picker, student enrolment, class membership) on top of the generic Manage engine.

## الجواب المختصر (عربي)

**قبل الخطوة 9:** لا. كانت الشاشات المصممة يدوياً تستخدم 62 مورداً من أصل 343 (حوالي 18%)، وكانت بوابة الإداري **للقراءة فقط** (بدون أي إضافة أو تعديل أو حذف). لم يكن التطبيق يغني عن المتصفح.

**بعد الخطوة 9:** أصبح لدى الإداري تبويب **"الإدارة الشاملة"** يفتح **كل الموارد الـ 343** على السيرفر: عرض، بحث، تصفية، ترقيم صفحات، إضافة، تعديل، حذف — بحسب ما يسمح به كل مورد وبحسب صلاحيات دورك على السيرفر (أي 403 يُخفي المورد).

**ما لا يزال يحتاج المتصفح** (ليس عيباً في التطبيق بل حدود الـ API نفسه):

1. **81 مورداً للقراءة فقط (GET)** — لا يمكن لأي تطبيق تعديلها حتى يضيف السيرفر طرق الكتابة. أهمها: الإعدادات `/settings`، مصفوفة الصلاحيات `/permissions`، الموديولات `/modules`، هيكل الجدول الدراسي (`/timetables`, `/timetable-days`, `/timetable-periods`, `/timetable-slots`, `/tt-*`), الفصول الدراسية `/school-terms`، إرسال الرسائل `/messages`، التقارير `/reports`.
2. **أشياء غير موجودة في الـ API أصلاً:** إعدادات النظام العامة، تثبيت/تحديث الموديولات والثيمات، النسخ الاحتياطي، إعادة تعيين كلمات المرور بالبريد، رفع الملفات (الصور والمرفقات)، مُنشئ التقارير الطباعي، واستيراد البيانات بالجملة.
3. **مفاتيح الـ API نفسها** (`Manage API Keys`) تُدار من المتصفح فقط.

**الخلاصة:** للتشغيل اليومي (الأشخاص، الطلاب، الموظفون، الفصول، التسجيل، الحضور، الدرجات، السلوك، المالية، الأنشطة، الرحلات، المكتبة…) نعم يمكنك الاستغناء عن المتصفح. لإعداد النظام لأول مرة أو لتعديل الجدول الدراسي والإعدادات والصلاحيات، ستحتاج المتصفح — أو أن يُفعّل السيرفر طرق POST/PATCH لتلك الموارد، وعندها يعمل التطبيق معها تلقائياً بدون أي تعديل في الكود.

## Short answer (English)

**Before Step 9:** No. The hand-designed screens used 62 of 343 resources (~18%) and the administrator portal was **read-only**.

**After Step 9:** Administrators get a **Manage** tab that opens **all 343 resources**: list, search, documented filters, paging, add, edit and delete — exactly as far as each resource and your server role allow (a 403 hides the resource).

**Still needs the browser** (API limits, not app limits):

1. **81 read-only (GET) resources** — no app can change them until the server adds write methods. Most important: `/settings`, `/permissions`, `/modules`, timetable structure (`/timetables`, `/timetable-days`, `/timetable-periods`, `/timetable-slots`, `/tt-*`), `/school-terms`, sending `/messages`, `/reports`.
2. **Not in the API at all:** global system settings, installing modules/themes, backups, password reset e-mails, file uploads (photos, attachments), the printable report builder, bulk imports.
3. **API keys themselves** are managed in the browser only.

**Bottom line:** day-to-day running of the school can be done from the app. First-time setup, timetable building, settings and permissions still need the browser — or the server team enables POST/PATCH on those resources, after which the app handles them automatically with no code change.

## Coverage numbers

| | Resources |
|---|---|
| Total in API | 343 |
| Hand-designed screens (Steps 1–8) | 62 |
| Reachable through Manage (Step 9) | 343 |
| Writable (POST/PATCH/PUT/DELETE) | 262 |
| Read-only on the server (GET only) | 81 |

## Read-only resources (GET only)

`/report-archive-entries`, `/report-archives`, `/timetable-dates`, `/timetable-days`, `/timetable-periods`, `/timetable-slots`, `/timetables`, `/units`, `/badges`, `/clinic-students`, `/clinics`, `/enf-planned-session-teachers`, `/enf-planned-sessions`, `/enf-session-students`, `/enf-sessions`, `/free-learning-progress`, `/free-learning-units`, `/house-point-categories`, `/house-points-house`, `/ib-diploma-cas-reflections`, `/ib-diploma-cas-supervisor-feedbacks`, `/ibpyp-glossaries`, `/ibpyp-unit-working-classes`, `/mastery-transcript-journey-logs`, `/meet-the-teacher-logins`, `/pd-requests`, `/professional-development-request-logs`, `/stream-posts`, `/trip-days`, `/trip-people`, `/trip-planner-request-logs`, `/trips`, `/budgets`, `/expenses`, `/fees`, `/finance-expense-logs`, `/form-submissions`, `/forms`, `/invoice-fees`, `/invoices`, `/library-events`, `/message-receipts`, `/messages`, `/staff-absence-dates`, `/staff-absences`, `/staff-coverage`, `/staff-duties`, `/person-status-logs`, `/personal-documents`, `/roles`, `/staff-contracts`, `/calendars`, `/departments`, `/form-groups`, `/grade-scale-grades`, `/grade-scales`, `/houses`, `/school-terms`, `/school-years`, `/spaces`, `/special-days`, `/year-groups`, `/actions`, `/api-logs`, `/custom-fields`, `/logs`, `/modules`, `/outcomes`, `/permissions`, `/rubrics`, `/settings`, `/alert-levels`, `/attendance-class-logs`, `/attendance-codes`, `/attendance-form-group-logs`, `/behaviour-letters`, `/in-archives`, `/individual-needs`, `/individual-needs-descriptors`, `/medical`, `/medical-conditions`
