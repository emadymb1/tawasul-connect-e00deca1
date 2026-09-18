import 'package:flutter/widgets.dart';

/// Hand-written localisation so no code generation step is needed.
/// Arabic is the primary language; English is the second.
class S {
  S(this.locale);

  final Locale locale;

  static S of(BuildContext context) =>
      Localizations.of<S>(context, S) ?? S(const Locale('ar'));

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  static const supportedLocales = [Locale('ar'), Locale('en')];

  bool get isArabic => locale.languageCode == 'ar';

  String _(String key) =>
      (isArabic ? _ar[key] : _en[key]) ?? _en[key] ?? key;

  String get appName => _('appName');
  String get appTagline => _('appTagline');
  String get signIn => _('signIn');
  String get signInHint => _('signInHint');
  String get usernameLabel => _('usernameLabel');
  String get passwordLabel => _('passwordLabel');
  String get signingIn => _('signingIn');
  String get signOut => _('signOut');
  String get signInFailed => _('signInFailed');
  String get requiredField => _('requiredField');
  String get language => _('language');
  String get retry => _('retry');
  String get loading => _('loading');
  String get nothingHere => _('nothingHere');
  String get noPermission => _('noPermission');
  String get offline => _('offline');
  String get showingSavedData => _('showingSavedData');
  String get offlineNoSavedData => _('offlineNoSavedData');
  String get pullToRefresh => _('pullToRefresh');
  String get hiddenByPermissions => _('hiddenByPermissions');
  String get deviceNotifications => _('deviceNotifications');
  String get lastUpdated => _('lastUpdated');
  String get exitApp => _('exitApp');
  String get exitAppQuestion => _('exitAppQuestion');
  String get yes => _('yes');
  String get no => _('no');

  String get dashboard => _('dashboard');
  String get timetable => _('timetable');
  String get attendance => _('attendance');
  String get markbook => _('markbook');
  String get behaviour => _('behaviour');
  String get homework => _('homework');
  String get mySchool => _('mySchool');
  String get myChildren => _('myChildren');
  String get invoices => _('invoices');
  String get people => _('people');
  String get school => _('school');
  String get notices => _('notices');

  String get studentPortal => _('studentPortal');
  String get parentPortal => _('parentPortal');
  String get teacherPortal => _('teacherPortal');
  String get adminPortal => _('adminPortal');

  String get goodMorning => _('goodMorning');
  String get hello => _('hello');
  String get attendanceRate => _('attendanceRate');
  String get gradeAverage => _('gradeAverage');
  String get lessonsToday => _('lessonsToday');
  String get myStudents => _('myStudents');
  String get todaysLessons => _('todaysLessons');
  String get classRoster => _('classRoster');
  String get schoolNotices => _('schoolNotices');
  String get myTimetable => _('myTimetable');
  String get unreadNotices => _('unreadNotices');
  String get overdue => _('overdue');
  String get due => _('due');
  String get students => _('students');
  String get staff => _('staff');
  String get schoolYear => _('schoolYear');
  String get open => _('open');
  String get classes => _('classes');
  String get lessons => _('lessons');
  String get lessonPlanner => _('lessonPlanner');
  String get newLesson => _('newLesson');
  String get homeworkDetails => _('homeworkDetails');
  String get dueDate => _('dueDate');
  String get submissions => _('submissions');
  String get progress => _('progress');
  String get completed => _('completed');
  String get notCompleted => _('notCompleted');
  String get addBehaviour => _('addBehaviour');
  String get positive => _('positive');
  String get negative => _('negative');
  String get save => _('save');
  String get saving => _('saving');
  String get saved => _('saved');
  String get name => _('name');
  String get description => _('description');
  String get summary => _('summary');
  String get teachersNotes => _('teachersNotes');
  String get date => _('date');
  String get startTime => _('startTime');
  String get endTime => _('endTime');
  String get comment => _('comment');
  String get grade => _('grade');
  String get assessments => _('assessments');
  String get newAssessment => _('newAssessment');
  String get newColumn => _('newColumn');
  String get type => _('type');
  String get level => _('level');
  String get descriptor => _('descriptor');
  String get hasHomework => _('hasHomework');
  String get visibleToStudents => _('visibleToStudents');
  String get visibleToParents => _('visibleToParents');
  String get outOf => _('outOf');
  String get selectStudent => _('selectStudent');
  String get history => _('history');
  String get takeAttendance => _('takeAttendance');
  String get weeklyTimetable => _('weeklyTimetable');
  String get more => _('more');
  String get reports => _('reports');
  String get house => _('house');
  String get housePoints => _('housePoints');
  String get markDone => _('markDone');
  String get markNotDone => _('markNotDone');
  String get upcoming => _('upcoming');
  String get past => _('past');
  String get subjects => _('subjects');
  String get average => _('average');
  String get points => _('points');
  String get reason => _('reason');
  String get issued => _('issued');
  String get couldNotSave => _('couldNotSave');
  String get finance => _('finance');
  String get payments => _('payments');
  String get amount => _('amount');
  String get status => _('status');
  String get total => _('total');
  String get balance => _('balance');
  String get bookings => _('bookings');
  String get meetTheTeacher => _('meetTheTeacher');
  String get myDetails => _('myDetails');
  String get familyDetails => _('familyDetails');
  String get updateRequests => _('updateRequests');
  String get requestChange => _('requestChange');
  String get pending => _('pending');
  String get sendRequest => _('sendRequest');
  String get requestSent => _('requestSent');
  String get phone => _('phone');
  String get email => _('email');
  String get address => _('address');
  String get invoiceDetails => _('invoiceDetails');
  String get feeItems => _('feeItems');
  String get noChildSelected => _('noChildSelected');
  String get childOverview => _('childOverview');
  String get users => _('users');
  String get roles => _('roles');
  String get yearGroups => _('yearGroups');
  String get formGroups => _('formGroups');
  String get departments => _('departments');
  String get spaces => _('spaces');
  String get schoolStructure => _('schoolStructure');
  String get registersTaken => _('registersTaken');
  String get missingRegisters => _('missingRegisters');
  String get fees => _('fees');
  String get budgets => _('budgets');
  String get expenses => _('expenses');
  String get staffAbsence => _('staffAbsence');
  String get cover => _('cover');
  String get substitutes => _('substitutes');
  String get systemLogs => _('systemLogs');
  String get apiLogs => _('apiLogs');
  String get search => _('search');
  String get operations => _('operations');
  String get today => _('today');

  // Step 13 — API v2 capabilities (system, exports, bulk, webhooks)
  String get system => _('system');
  String get serverHealth => _('serverHealth');
  String get serverStats => _('serverStats');
  String get apiAnalytics => _('apiAnalytics');
  String get resourceRegistry => _('resourceRegistry');
  String get resourcesAvailable => _('resourcesAvailable');
  String get writableResources => _('writableResources');
  String get myPermissions => _('myPermissions');
  String get credential => _('credential');
  String get webhooks => _('webhooks');
  String get addWebhook => _('addWebhook');
  String get webhookUrl => _('webhookUrl');
  String get webhookEvents => _('webhookEvents');
  String get exportCsv => _('exportCsv');
  String get exportedRows => _('exportedRows');

  // Step 9 — admin Manage browser (all server resources)
  String get manage => _('manage');
  String get manageSubtitle => _('manageSubtitle');
  String get searchResources => _('searchResources');
  String get readOnly => _('readOnly');
  String get create => _('create');
  String get edit => _('edit');
  String get delete => _('delete');
  String get deleted => _('deleted');
  String get deleteQuestion => _('deleteQuestion');
  String get cancel => _('cancel');
  String get filters => _('filters');
  String get applyFilters => _('applyFilters');
  String get clearFilters => _('clearFilters');
  String get previousPage => _('previousPage');
  String get nextPage => _('nextPage');
  String get records => _('records');
  String get record => _('record');
  String get module => _('module');
  String get copied => _('copied');
  String get noSchema => _('noSchema');
  String get noSchemaNoRecord => _('noSchemaNoRecord');
  String get numberExpected => _('numberExpected');

  /// Localised name for an API catalogue category.
  String categoryName(String category) => _('category_$category');

  // Step 10 — school year switcher and bulk actions
  String get myOwnYear => _('myOwnYear');
  String get currentYear => _('currentYear');
  String get yearChanged => _('yearChanged');
  String get select => _('select');
  String get selectAll => _('selectAll');
  String get clearSelection => _('clearSelection');
  String get selectedCount => _('selectedCount');
  String get deleteSelected => _('deleteSelected');
  String get bulkDeleteQuestion => _('bulkDeleteQuestion');
  String get bulkDone => _('bulkDone');
  String get bulkFailed => _('bulkFailed');
  String get noIdField => _('noIdField');

  // Step 11 — administrator module hub
  String get modules => _('modules');
  String get modulesSubtitle => _('modulesSubtitle');
  String get searchModules => _('searchModules');
  String get resources => _('resources');
  String get editable => _('editable');
  String get pages => _('pages');
  String get openModules => _('openModules');
  String get personDetails => _('personDetails');
  String get accountDetails => _('accountDetails');
  String get personalDetails => _('personalDetails');
  String get dateOfBirth => _('dateOfBirth');
  String get gender => _('gender');
  String get primaryRole => _('primaryRole');
  String get canLogin => _('canLogin');
  String get studentIdLabel => _('studentIdLabel');
  String get enrolments => _('enrolments');
  String get noEnrolments => _('noEnrolments');
  String get rollOrder => _('rollOrder');
  String get enrolStudent => _('enrolStudent');
  String get editEnrolment => _('editEnrolment');
  String get classEnrolments => _('classEnrolments');
  String get noClassEnrolments => _('noClassEnrolments');
  String get addToClass => _('addToClass');
  String get removeFromClass => _('removeFromClass');
  String get removeQuestion => _('removeQuestion');
  String get removed => _('removed');
  String get newUser => _('newUser');
  String get editUser => _('editUser');
  String get titleLabel => _('titleLabel');
  String get firstName => _('firstName');
  String get surname => _('surname');
  String get preferredName => _('preferredName');
  String get officialName => _('officialName');
  String get male => _('male');
  String get female => _('female');
  String get other => _('other');
  String get unspecified => _('unspecified');
  String get passwordKeepHint => _('passwordKeepHint');
  String get userCreated => _('userCreated');
  String get pickPerson => _('pickPerson');
  String get enrolmentSaved => _('enrolmentSaved');
  String get enrolmentYearHint => _('enrolmentYearHint');
  String get searchPeople => _('searchPeople');
  String get searchClasses => _('searchClasses');
  String get roleInClass => _('roleInClass');
  String get classMembers => _('classMembers');
  String get openPerson => _('openPerson');

  // Step 6 — shared school life
  String get schoolLife => _('schoolLife');
  String get notifications => _('notifications');
  String get messages => _('messages');
  String get calendar => _('calendar');
  String get library => _('library');
  String get activities => _('activities');
  String get trips => _('trips');
  String get helpdesk => _('helpdesk');
  String get markRead => _('markRead');
  String get readReceipts => _('readReceipts');
  String get upcomingEvents => _('upcomingEvents');
  String get specialDays => _('specialDays');
  String get myLoans => _('myLoans');
  String get catalogue => _('catalogue');
  String get available => _('available');
  String get signUp => _('signUp');
  String get signUpSent => _('signUpSent');
  String get newTicket => _('newTicket');
  String get subject => _('subject');
  String get ticketCreated => _('ticketCreated');

  static const Map<String, String> _en = {
    'appName': 'Tawasul School OS',
    'appTagline': 'School platform',
    'signIn': 'Sign in',
    'signInHint': 'Use your school Tawasul username and password.',
    'usernameLabel': 'Username or email',
    'passwordLabel': 'Password',
    'signingIn': 'Signing in…',
    'signOut': 'Sign out',
    'signInFailed': 'Those details were not accepted.',
    'requiredField': 'Required',
    'language': 'Language',
    'retry': 'Try again',
    'loading': 'Loading…',
    'nothingHere': 'Nothing to show yet.',
    'noPermission': 'Your account does not have access to this.',
    'dashboard': 'Dashboard',
    'timetable': 'Timetable',
    'attendance': 'Attendance',
    'markbook': 'Markbook',
    'behaviour': 'Behaviour',
    'homework': 'Homework',
    'mySchool': 'My school',
    'myChildren': 'My children',
    'invoices': 'Invoices',
    'people': 'People',
    'school': 'School',
    'notices': 'Notices',
    'studentPortal': 'Student portal',
    'parentPortal': 'Parent portal',
    'teacherPortal': 'Teacher portal',
    'adminPortal': 'Administration',
    'goodMorning': 'Good morning,',
    'hello': 'Hello,',
    'attendanceRate': 'Attendance rate',
    'gradeAverage': 'Grade average',
    'lessonsToday': 'Lessons today',
    'myStudents': 'My students',
    'todaysLessons': "Today's lessons",
    'classRoster': 'Class roster',
    'schoolNotices': 'School notices',
    'myTimetable': 'My timetable',
    'unreadNotices': 'Unread notices',
    'overdue': 'Overdue',
    'due': 'Due',
    'students': 'Students',
    'staff': 'Staff',
    'schoolYear': 'School year',
    'open': 'Open',
    'classes': 'Classes',
    'lessons': 'Lessons',
    'lessonPlanner': 'Lesson planner',
    'newLesson': 'New lesson',
    'homeworkDetails': 'Homework details',
    'dueDate': 'Due date',
    'submissions': 'Submissions',
    'progress': 'Progress',
    'completed': 'Completed',
    'notCompleted': 'Not completed',
    'addBehaviour': 'Record behaviour',
    'positive': 'Positive',
    'negative': 'Negative',
    'save': 'Save',
    'saving': 'Saving…',
    'saved': 'Saved',
    'name': 'Name',
    'description': 'Description',
    'summary': 'Summary',
    'teachersNotes': "Teacher's notes",
    'date': 'Date',
    'startTime': 'Start time',
    'endTime': 'End time',
    'comment': 'Comment',
    'grade': 'Grade',
    'assessments': 'Assessments',
    'newAssessment': 'New assessment',
    'newColumn': 'New grade column',
    'type': 'Type',
    'level': 'Level',
    'descriptor': 'Descriptor',
    'hasHomework': 'Includes homework',
    'visibleToStudents': 'Visible to students',
    'visibleToParents': 'Visible to parents',
    'outOf': 'Out of',
    'selectStudent': 'Select a student',
    'history': 'History',
    'takeAttendance': 'Take attendance',
    'weeklyTimetable': 'Weekly timetable',
    'more': 'More',
    'reports': 'Reports',
    'house': 'House',
    'housePoints': 'House points',
    'markDone': 'Mark as done',
    'markNotDone': 'Mark as not done',
    'upcoming': 'Upcoming',
    'past': 'Past',
    'subjects': 'Subjects',
    'average': 'Average',
    'points': 'points',
    'reason': 'Reason',
    'issued': 'Issued',
    'couldNotSave': 'Could not save. Please try again.',
    'finance': 'Finance',
    'payments': 'Payments',
    'amount': 'Amount',
    'status': 'Status',
    'total': 'Total',
    'balance': 'Balance',
    'bookings': 'Bookings',
    'meetTheTeacher': 'Meet the teacher',
    'myDetails': 'My details',
    'familyDetails': 'Family details',
    'updateRequests': 'Data update requests',
    'requestChange': 'Request a change',
    'pending': 'Pending',
    'sendRequest': 'Send request',
    'requestSent': 'Your request was sent to the school.',
    'phone': 'Phone',
    'email': 'Email',
    'address': 'Address',
    'invoiceDetails': 'Invoice details',
    'feeItems': 'Invoice items',
    'noChildSelected': 'Choose a child first.',
    'childOverview': 'Child overview',
    'users': 'Users',
    'roles': 'Roles',
    'yearGroups': 'Year groups',
    'formGroups': 'Form groups',
    'departments': 'Departments',
    'spaces': 'Spaces',
    'schoolStructure': 'School structure',
    'registersTaken': 'Registers taken',
    'missingRegisters': 'Missing registers',
    'fees': 'Fees',
    'budgets': 'Budgets',
    'expenses': 'Expenses',
    'staffAbsence': 'Staff absence',
    'cover': 'Cover',
    'substitutes': 'Substitutes',
    'systemLogs': 'System log',
    'apiLogs': 'API log',
    'search': 'Search',
    'operations': 'Operations',
    'today': 'Today',
    'schoolLife': 'School life',
    'notifications': 'Notifications',
    'messages': 'Messages',
    'calendar': 'Calendar',
    'library': 'Library',
    'activities': 'Activities',
    'trips': 'Trips',
    'helpdesk': 'Help desk',
    'markRead': 'Mark as read',
    'readReceipts': 'Read receipts',
    'upcomingEvents': 'Upcoming events',
    'specialDays': 'Special days',
    'myLoans': 'My loans',
    'catalogue': 'Catalogue',
    'available': 'Available',
    'signUp': 'Sign up',
    'signUpSent': 'Your sign-up request was sent.',
    'newTicket': 'New ticket',
    'subject': 'Subject',
    'ticketCreated': 'Your ticket was created.',
    'offline': 'Offline',
    'showingSavedData': 'showing the last saved data',
    'offlineNoSavedData': 'No connection and no saved copy of this screen yet.',
    'pullToRefresh': 'Pull down to refresh',
    'hiddenByPermissions': 'Some sections are hidden because your account has no access to them.',
    'deviceNotifications': 'Device notifications',
    'lastUpdated': 'Last updated',
    'exitApp': 'Close app',
    'exitAppQuestion': 'Do you want to close the app?',
    'yes': 'Yes',
    'no': 'No',
    'manage': 'Manage',
    'manageSubtitle':
        'Every record on the school server, by module. What you can open, add or change follows your role exactly.',
    'searchResources': 'Search modules and resources',
    'readOnly': 'Read only',
    'create': 'Add',
    'edit': 'Edit',
    'delete': 'Delete',
    'deleted': 'Deleted.',
    'deleteQuestion':
        'Delete this record from the school server? This cannot be undone.',
    'cancel': 'Cancel',
    'filters': 'Filters',
    'applyFilters': 'Apply',
    'clearFilters': 'Clear',
    'previousPage': 'Previous',
    'nextPage': 'Next',
    'records': 'Records',
    'record': 'Record',
    'module': 'Module',
    'copied': 'Copied.',
    'noSchema':
        'The server did not describe this form, so fields are taken from the existing record.',
    'noSchemaNoRecord':
        'The server did not describe this form and there is no record to copy fields from. Open an existing record first, or add the resource description to the server specification.',
    'numberExpected': 'Enter a number.',
    'category_Academics': 'Academics',
    'category_Operations': 'Operations',
    'category_People': 'People',
    'category_School': 'School',
    'category_System': 'System',
    'category_Wellbeing': 'Wellbeing',
    'myOwnYear': 'My own school year',
    'currentYear': 'Current year',
    'yearChanged': 'School year changed. Screens reloaded.',
    'select': 'Select',
    'selectAll': 'Select all on this page',
    'clearSelection': 'Clear selection',
    'selectedCount': 'selected',
    'deleteSelected': 'Delete selected',
    'bulkDeleteQuestion':
        'Delete every selected record? This cannot be undone.',
    'bulkDone': 'Deleted',
    'bulkFailed': 'could not be deleted',
    'noIdField': 'These records have no identifier, so they cannot be selected.',
    'modules': 'Modules',
    'modulesSubtitle':
        'Every module the school server offers, the same way the browser menu shows them.',
    'searchModules': 'Search modules and pages',
    'resources': 'pages',
    'editable': 'Editable',
    'pages': 'Pages',
    'openModules': 'Browse by module',
    'personDetails': 'Person details',
    'accountDetails': 'Account',
    'personalDetails': 'Personal details',
    'dateOfBirth': 'Date of birth',
    'gender': 'Gender',
    'primaryRole': 'Primary role',
    'canLogin': 'Can sign in',
    'studentIdLabel': 'Student ID',
    'enrolments': 'Student enrolments',
    'noEnrolments': 'Not enrolled as a student in this school year.',
    'rollOrder': 'Roll order',
    'enrolStudent': 'Enrol as student',
    'editEnrolment': 'Edit enrolment',
    'classEnrolments': 'Classes',
    'noClassEnrolments': 'No class enrolments yet.',
    'addToClass': 'Add to class',
    'removeFromClass': 'Remove from class',
    'removeQuestion': 'Remove this record? You can add it again later.',
    'removed': 'Removed',
    'newUser': 'New user',
    'editUser': 'Edit user',
    'titleLabel': 'Title',
    'firstName': 'First name',
    'surname': 'Surname',
    'preferredName': 'Preferred name',
    'officialName': 'Official name',
    'male': 'Male',
    'female': 'Female',
    'other': 'Other',
    'unspecified': 'Unspecified',
    'passwordKeepHint': 'Leave empty to keep the current password.',
    'userCreated': 'User created on the server.',
    'pickPerson': 'Choose a person',
    'enrolmentSaved': 'Enrolment saved.',
    'enrolmentYearHint': 'The enrolment is created in the school year you are working in (see the year switcher).',
    'searchPeople': 'Search people by name or username',
    'searchClasses': 'Search classes',
    'roleInClass': 'Role in class',
    'classMembers': 'Class members',
    'openPerson': 'Open record',
  };

  static const Map<String, String> _ar = {
    'appName': 'نظام تواصل المدرسي',
    'appTagline': 'منصة المدرسة',
    'signIn': 'تسجيل الدخول',
    'signInHint': 'استخدم اسم المستخدم وكلمة المرور الخاصة بمدرستك.',
    'usernameLabel': 'اسم المستخدم أو البريد',
    'passwordLabel': 'كلمة المرور',
    'signingIn': 'جارٍ تسجيل الدخول…',
    'signOut': 'تسجيل الخروج',
    'signInFailed': 'البيانات غير صحيحة.',
    'requiredField': 'مطلوب',
    'language': 'اللغة',
    'retry': 'إعادة المحاولة',
    'loading': 'جارٍ التحميل…',
    'nothingHere': 'لا توجد بيانات بعد.',
    'noPermission': 'حسابك لا يملك صلاحية الوصول.',
    'dashboard': 'الرئيسية',
    'timetable': 'الجدول',
    'attendance': 'الحضور',
    'markbook': 'الدرجات',
    'behaviour': 'السلوك',
    'homework': 'الواجبات',
    'mySchool': 'مدرستي',
    'myChildren': 'أبنائي',
    'invoices': 'الفواتير',
    'people': 'الأشخاص',
    'school': 'المدرسة',
    'notices': 'الإعلانات',
    'studentPortal': 'بوابة الطالب',
    'parentPortal': 'بوابة ولي الأمر',
    'teacherPortal': 'بوابة المعلم',
    'adminPortal': 'الإدارة',
    'goodMorning': 'صباح الخير،',
    'hello': 'مرحباً،',
    'attendanceRate': 'نسبة الحضور',
    'gradeAverage': 'معدل الدرجات',
    'lessonsToday': 'حصص اليوم',
    'myStudents': 'طلابي',
    'todaysLessons': 'حصص اليوم',
    'classRoster': 'قائمة الطلاب',
    'schoolNotices': 'إعلانات المدرسة',
    'myTimetable': 'جدولي',
    'unreadNotices': 'إعلانات غير مقروءة',
    'overdue': 'متأخر',
    'due': 'التسليم',
    'students': 'الطلاب',
    'staff': 'الموظفون',
    'schoolYear': 'العام الدراسي',
    'open': 'فتح',
    'classes': 'الصفوف',
    'lessons': 'الدروس',
    'lessonPlanner': 'تحضير الدروس',
    'newLesson': 'درس جديد',
    'homeworkDetails': 'تفاصيل الواجب',
    'dueDate': 'تاريخ التسليم',
    'submissions': 'تسليم الواجبات',
    'progress': 'المتابعة',
    'completed': 'مكتمل',
    'notCompleted': 'غير مكتمل',
    'addBehaviour': 'تسجيل سلوك',
    'positive': 'إيجابي',
    'negative': 'سلبي',
    'save': 'حفظ',
    'saving': 'جارٍ الحفظ…',
    'saved': 'تم الحفظ',
    'name': 'الاسم',
    'description': 'الوصف',
    'summary': 'الملخص',
    'teachersNotes': 'ملاحظات المعلم',
    'date': 'التاريخ',
    'startTime': 'وقت البداية',
    'endTime': 'وقت النهاية',
    'comment': 'ملاحظة',
    'grade': 'الدرجة',
    'assessments': 'الاختبارات',
    'newAssessment': 'اختبار جديد',
    'newColumn': 'عمود درجات جديد',
    'type': 'النوع',
    'level': 'المستوى',
    'descriptor': 'الوصف المختصر',
    'hasHomework': 'يشمل واجباً',
    'visibleToStudents': 'ظاهر للطلاب',
    'visibleToParents': 'ظاهر لأولياء الأمور',
    'outOf': 'من',
    'selectStudent': 'اختر طالباً',
    'history': 'السجل',
    'takeAttendance': 'تسجيل الحضور',
    'weeklyTimetable': 'الجدول الأسبوعي',
    'more': 'المزيد',
    'reports': 'التقارير',
    'house': 'البيت',
    'housePoints': 'نقاط البيت',
    'markDone': 'تحديد كمنجز',
    'markNotDone': 'تحديد كغير منجز',
    'upcoming': 'القادمة',
    'past': 'السابقة',
    'subjects': 'المواد',
    'average': 'المعدل',
    'points': 'نقطة',
    'reason': 'السبب',
    'issued': 'تاريخ الإصدار',
    'couldNotSave': 'تعذّر الحفظ. حاول مرة أخرى.',
    'finance': 'المالية',
    'payments': 'المدفوعات',
    'amount': 'المبلغ',
    'status': 'الحالة',
    'total': 'الإجمالي',
    'balance': 'المتبقي',
    'bookings': 'المواعيد',
    'meetTheTeacher': 'لقاء المعلمين',
    'myDetails': 'بياناتي',
    'familyDetails': 'بيانات الأسرة',
    'updateRequests': 'طلبات تحديث البيانات',
    'requestChange': 'طلب تعديل',
    'pending': 'قيد المراجعة',
    'sendRequest': 'إرسال الطلب',
    'requestSent': 'تم إرسال الطلب إلى المدرسة.',
    'phone': 'رقم الهاتف',
    'email': 'البريد الإلكتروني',
    'address': 'العنوان',
    'invoiceDetails': 'تفاصيل الفاتورة',
    'feeItems': 'بنود الفاتورة',
    'noChildSelected': 'اختر أحد الأبناء أولاً.',
    'childOverview': 'ملخص الابن',
    'users': 'المستخدمون',
    'roles': 'الأدوار',
    'yearGroups': 'الصفوف الدراسية',
    'formGroups': 'الفصول',
    'departments': 'الأقسام',
    'spaces': 'القاعات',
    'schoolStructure': 'هيكل المدرسة',
    'registersTaken': 'تم رصد الحضور',
    'missingRegisters': 'فصول لم يُرصد حضورها',
    'fees': 'الرسوم',
    'budgets': 'الميزانيات',
    'expenses': 'المصروفات',
    'staffAbsence': 'غياب الموظفين',
    'cover': 'التغطية البديلة',
    'substitutes': 'المعلمون البدلاء',
    'systemLogs': 'سجل النظام',
    'apiLogs': 'سجل الواجهة البرمجية',
    'search': 'بحث',
    'operations': 'التشغيل',
    'today': 'اليوم',
    'schoolLife': 'الحياة المدرسية',
    'notifications': 'الإشعارات',
    'messages': 'الرسائل',
    'calendar': 'التقويم',
    'library': 'المكتبة',
    'activities': 'الأنشطة',
    'trips': 'الرحلات',
    'helpdesk': 'الدعم الفني',
    'markRead': 'تحديد كمقروء',
    'readReceipts': 'إشعارات القراءة',
    'upcomingEvents': 'الفعاليات القادمة',
    'specialDays': 'الأيام الخاصة',
    'myLoans': 'استعاراتي',
    'catalogue': 'الفهرس',
    'available': 'متاح',
    'signUp': 'تسجيل',
    'signUpSent': 'تم إرسال طلب التسجيل.',
    'newTicket': 'طلب دعم جديد',
    'subject': 'الموضوع',
    'ticketCreated': 'تم إنشاء طلب الدعم.',
    'offline': 'غير متصل',
    'showingSavedData': 'يتم عرض آخر بيانات محفوظة',
    'offlineNoSavedData': 'لا يوجد اتصال ولا توجد نسخة محفوظة لهذه الشاشة بعد.',
    'pullToRefresh': 'اسحب للأسفل للتحديث',
    'hiddenByPermissions': 'بعض الأقسام مخفية لأن حسابك لا يملك صلاحية الوصول إليها.',
    'deviceNotifications': 'إشعارات الجهاز',
    'lastUpdated': 'آخر تحديث',
    'exitApp': 'إغلاق التطبيق',
    'exitAppQuestion': 'هل تريد إغلاق التطبيق؟',
    'yes': 'نعم',
    'no': 'لا',
    'manage': 'الإدارة الشاملة',
    'manageSubtitle':
        'كل السجلات على خادم المدرسة مرتبة حسب الموديول. ما يمكنك فتحه أو إضافته أو تعديله يتبع صلاحيات دورك تماماً.',
    'searchResources': 'ابحث في الموديولات والموارد',
    'readOnly': 'قراءة فقط',
    'create': 'إضافة',
    'edit': 'تعديل',
    'delete': 'حذف',
    'deleted': 'تم الحذف.',
    'deleteQuestion': 'حذف هذا السجل من خادم المدرسة؟ لا يمكن التراجع.',
    'cancel': 'إلغاء',
    'filters': 'التصفيات',
    'applyFilters': 'تطبيق',
    'clearFilters': 'مسح',
    'previousPage': 'السابق',
    'nextPage': 'التالي',
    'records': 'السجلات',
    'record': 'السجل',
    'module': 'الموديول',
    'copied': 'تم النسخ.',
    'noSchema':
        'لم يصف الخادم هذا النموذج، لذلك أُخذت الحقول من السجل الموجود.',
    'noSchemaNoRecord':
        'لم يصف الخادم هذا النموذج ولا يوجد سجل لنسخ الحقول منه. افتح سجلاً موجوداً أولاً، أو أضف وصف المورد إلى مواصفة الخادم.',
    'numberExpected': 'أدخل رقماً.',
    'category_Academics': 'الأكاديمي',
    'category_Operations': 'التشغيل',
    'category_People': 'الأشخاص',
    'category_School': 'المدرسة',
    'category_System': 'النظام',
    'category_Wellbeing': 'الرعاية',
    'myOwnYear': 'عامي الدراسي',
    'currentYear': 'العام الحالي',
    'yearChanged': 'تم تغيير العام الدراسي وإعادة تحميل الشاشات.',
    'select': 'تحديد',
    'selectAll': 'تحديد كل ما في الصفحة',
    'clearSelection': 'إلغاء التحديد',
    'selectedCount': 'محدد',
    'deleteSelected': 'حذف المحدد',
    'bulkDeleteQuestion': 'حذف كل السجلات المحددة؟ لا يمكن التراجع.',
    'bulkDone': 'تم الحذف',
    'bulkFailed': 'تعذّر حذفها',
    'noIdField': 'هذه السجلات بلا معرّف، لذلك لا يمكن تحديدها.',
    'modules': 'الموديولات',
    'modulesSubtitle':
        'كل موديولات السيرفر كما تظهر في قائمة المتصفح تماماً.',
    'searchModules': 'ابحث في الموديولات والصفحات',
    'resources': 'صفحة',
    'editable': 'قابلة للتعديل',
    'pages': 'الصفحات',
    'openModules': 'التصفح حسب الموديول',
    'personDetails': 'بيانات الشخص',
    'accountDetails': 'الحساب',
    'personalDetails': 'البيانات الشخصية',
    'dateOfBirth': 'تاريخ الميلاد',
    'gender': 'الجنس',
    'primaryRole': 'الدور الأساسي',
    'canLogin': 'يمكنه تسجيل الدخول',
    'studentIdLabel': 'رقم الطالب',
    'enrolments': 'تسجيلات الطالب',
    'noEnrolments': 'غير مسجّل كطالب في هذا العام الدراسي.',
    'rollOrder': 'ترتيب الكشف',
    'enrolStudent': 'تسجيل كطالب',
    'editEnrolment': 'تعديل التسجيل',
    'classEnrolments': 'الفصول',
    'noClassEnrolments': 'لا توجد تسجيلات في الفصول بعد.',
    'addToClass': 'إضافة إلى فصل',
    'removeFromClass': 'إزالة من الفصل',
    'removeQuestion': 'إزالة هذا السجل؟ يمكنك إضافته مرة أخرى لاحقاً.',
    'removed': 'تمت الإزالة',
    'newUser': 'مستخدم جديد',
    'editUser': 'تعديل المستخدم',
    'titleLabel': 'اللقب',
    'firstName': 'الاسم الأول',
    'surname': 'اسم العائلة',
    'preferredName': 'الاسم المفضّل',
    'officialName': 'الاسم الرسمي',
    'male': 'ذكر',
    'female': 'أنثى',
    'other': 'آخر',
    'unspecified': 'غير محدد',
    'passwordKeepHint': 'اتركه فارغاً للإبقاء على كلمة المرور الحالية.',
    'userCreated': 'تم إنشاء المستخدم على الخادم.',
    'pickPerson': 'اختر شخصاً',
    'enrolmentSaved': 'تم حفظ التسجيل.',
    'enrolmentYearHint': 'يُنشأ التسجيل في العام الدراسي الذي تعمل فيه حالياً (انظر مبدّل العام).',
    'searchPeople': 'ابحث عن شخص بالاسم أو اسم المستخدم',
    'searchClasses': 'ابحث في الفصول',
    'roleInClass': 'الدور في الفصل',
    'classMembers': 'أعضاء الفصل',
    'openPerson': 'فتح السجل',
  };
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) async => S(locale);

  @override
  bool shouldReload(LocalizationsDelegate<S> old) => false;
}
