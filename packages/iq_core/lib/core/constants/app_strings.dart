import '../services/locale_service.dart';

/// App-wide string constants with Arabic / English support.
///
/// Usage: `AppStrings.login` returns the string in the current locale.
/// The locale is controlled by [LocaleService] which is synced from
/// [LocaleCubit].
class AppStrings {
  AppStrings._();

  /// Translation helper – returns [ar] or [en] based on current locale.
  static String _t(String ar, String en) =>
      LocaleService.isArabic ? ar : en;

  // ─── App Names (non-translatable) ───
  static const String appNamePassenger = 'IQ Taxi';
  static const String appNameDriver = 'IQ Taxi Driver';

  // ─── Auth ───
  static String get login => _t('تسجيل دخول', 'Login');
  static String get register => _t('إنشاء حساب', 'Register');
  static String get phoneNumber => _t('رقم جوالك', 'Phone Number');
  static const String phoneHint = '123 456 7899';
  static const String countryCode = '+964';
  static String get continueButton => _t('متابعة', 'Continue');
  static String get noAccount => _t('ليس لديك حساب ؟', "Don't have an account?");
  static String get createAccount => _t('إنشاء حساب', 'Create Account');
  static String get joinUs => _t('إنضم إلينا', 'Join Us');
  static String get registrationPending =>
      _t('تم تسجيل طلبك. سيتم التواصل معك عبر واتساب',
          'Your registration request has been submitted. You will be contacted via WhatsApp');
  static String get welcomeBack => _t('مرحباً بك,', 'Welcome Back,');
  static String get loginSubtitle =>
      _t('سجّل دخولك لحسابك, عن طريق رقم جوالك',
          'Log in to your account using your phone number');
  static String get recipientSubtitle =>
      _t('ادخل بيانات استلام الطرد', 'Enter parcel recipient details');

  // ─── OTP ───
  static String get confirmCode => _t('تأكيد الكود', 'Confirm Code');
  static String get otpSubtitle => _t(
      'يرجى إدخال رمز التحقق المكون من 6 أرقام والذي تم إرساله إلى رقم جوالك',
      'Please enter the 6-digit verification code sent to your phone number');
  static String get didntGetCode => _t('لم يصلك الكود ؟', "Didn't get the code?");
  static String get resendCode => _t('إعادة إرسال', 'Resend');
  static String get confirm => _t('تأكيد', 'Confirm');

  // ─── Onboarding ───
  static String get skip => _t('تخطي', 'Skip');
  static String get getStarted => _t('متابعة', 'Continue');
  static String get onboardingTitle1 => _t('ادفع وانت مرتاح', 'Pay with Ease');
  static String get onboardingSubtitle1 => _t(
      'اختار طريقة الدفع اللي تناسبك وكمّل مشوارك بدون قلق',
      'Choose the payment method that suits you and complete your trip worry-free');
  static String get onboardingTitle2 =>
      _t('السائق قدّام عيونك', 'Track Your Driver');
  static String get onboardingSubtitle2 => _t(
      'تابع السائق خطوة بخطوة واعرف وقت وصوله بالضبط',
      'Follow your driver step by step and know exactly when they arrive');
  static String get onboardingTitle3 =>
      _t('مشوارك علينا', 'Your Ride, Our Priority');
  static String get onboardingSubtitle3 => _t(
      'اطلب سيارة فوراً وخلي الطريق أسهل وأسرع ويا IQ Taxi',
      'Request a car instantly and make your trip easier with IQ Taxi');
  static String get onboardingTitle4 => _t('وياك للأمان', 'Safety First');
  static String get onboardingSubtitle4 => _t(
      'نظام حماية متكامل وسواقين معتمدين لراحة بالك بكل مشوار',
      'Complete protection system and verified drivers for your peace of mind');

  // ─── Driver Onboarding ───
  static String get driverOnboardingTitle1 =>
      _t('اشتغل بمرونة', 'Work Flexibly');
  static String get driverOnboardingSubtitle1 => _t(
      'افتح التطبيق وقت ما تحب وابدأ استقبال الرحلات بدون التزام بمواعيد ثابتة',
      'Open the app whenever you want and start receiving trips without fixed schedules');
  static String get driverOnboardingTitle2 =>
      _t('رحلات آمنة ومضمونة', 'Safe & Guaranteed Trips');
  static String get driverOnboardingSubtitle2 => _t(
      'كل الرحلات موثّقة وبيانات العميل واضحة لحمايتك أثناء العمل',
      'All trips are documented and customer data is clear to protect you');
  static String get driverOnboardingTitle3 =>
      _t('ابدأ القيادة الآن!', 'Start Driving Now!');
  static String get driverOnboardingSubtitle3 => _t(
      'سجّل وابدأ رحلتك مع منصة تساعدك تكسب بسهولة وثبات',
      'Register and start your journey with a platform that helps you earn easily');

  // ─── Home ───
  static String get toWhere => _t('إلى أين؟', 'Where to?');
  static String get whereToGo =>
      _t('إلى أين أنت ذاهب؟', 'Where are you going?');
  static String get addStop => _t('إضافة نقطة توقف', 'Add a stop');
  static String get stopHint => _t('نقطة توقف', 'Stop');
  static String get maxStopsReached =>
      _t('الحد الأقصى نقطتين توقف', 'Maximum 2 stops allowed');
  static String get quickPlaces => _t('أماكن سريعة', 'Quick Places');
  static String get taxi => _t('تاكسي', 'Taxi');
  static String get delegate => _t('مندوب', 'Courier');
  static String get interCity => _t('سفر محافظات', 'Inter-City');
  static String get searchPlaceholder => _t('البحث عن مكان', 'Search for a place');

  // ─── Trip ───
  static String get tripSummary => _t('ملخص الرحلة', 'Trip Summary');
  static String get tripInfo => _t('معلومات الرحلة', 'Trip Info');
  static String get tripAddresses => _t('عناوين الرحلة', 'Trip Addresses');
  static String get fareDetails => _t('تفاصيل الأجرة', 'Fare Details');
  static String get duration => _t('المدة', 'Duration');
  static String get distance => _t('المسافة', 'Distance');
  static String get tripType => _t('نوع الرحلة', 'Trip Type');
  static String get tripTypes => _t('أنواع الرحلات', 'Trip Types');
  static String get enjoyYourTrip =>
      _t('استمتع برحلتك مع IQ Taxi', 'Enjoy your trip with IQ Taxi');
  static String get normal => _t('عادي', 'Normal');
  static String get baseFare => _t('سعر المسافة الأساسية', 'Base Distance Fare');
  static String get extraFare =>
      _t('سعر المسافة الإضافية', 'Extra Distance Fare');
  static String get taxes => _t('الضرائب', 'Taxes');
  static String get amount => _t('المبلغ', 'Amount');
  static String get total => _t('الإجمالي', 'Total');
  static String get choosePay => _t('اختر الدفع', 'Choose Payment');
  static String get payNow => _t('ادفع الآن', 'Pay Now');
  static String get paymentReceived => _t('تم استلام الدفع', 'Payment Received');
  static String get cash => _t('نقدي', 'Cash');
  static String get changePaymentMethod =>
      _t('تغيير طريقة الدفع', 'Change Payment Method');
  static String get orderNumber => _t('رقم الطلب', 'Order Number');
  static String get promoCode => _t('كود الخصم', 'Promo Code');
  static String get ridePreferences => _t('تفضيلات الرحلة', 'Ride Preferences');
  static String get scheduleRide => _t('جدولة الرحلة', 'Schedule Ride');
  static String get rideNow => _t('ركوب الآن', 'Ride Now');
  static String get persons => _t('أشخاص', 'Persons');
  static String get selectPaymentMethod =>
      _t('اختر طريقة الدفع', 'Select Payment Method');
  static String get walletPayment => _t('محفظة', 'Wallet');
  static String get cardPayment => _t('بطاقة', 'Card');
  static String get onlinePayment => _t('دفع إلكتروني', 'Online Payment');
  static String get loadingPaymentPage =>
      _t('جارٍ تحميل صفحة الدفع...', 'Loading payment page...');
  static String get paymentFailed => _t('فشلت عملية الدفع', 'Payment failed');
  static String get enterPromoCode => _t('أدخل كود الخصم', 'Enter promo code');
  static String get apply => _t('تطبيق', 'Apply');
  static String get remove => _t('إزالة', 'Remove');
  static String get promoApplied =>
      _t('تم تطبيق كود الخصم بنجاح', 'Promo code applied successfully');
  static String get scheduleRideFor => _t('جدولة الرحلة في', 'Schedule ride for');
  static String get selectDate => _t('اختر التاريخ', 'Select Date');
  static String get selectTime => _t('اختر الوقت', 'Select Time');
  static String get removeSchedule => _t('إلغاء الجدولة', 'Remove Schedule');
  static String get rideLater => _t('رحلة مؤجلة', 'Ride Later');
  static String get driverInstructions =>
      _t('تعليمات للسائق', 'Driver Instructions');
  static String get enterInstructions =>
      _t('أدخل تعليماتك للسائق...', 'Enter your instructions for the driver...');
  static String get noPreferencesAvailable =>
      _t('لا توجد تفضيلات متاحة', 'No preferences available');

  // ─── Searching for Driver ───
  static String get searchingForDriver =>
      _t('البحث عن سائق', 'Searching for Driver');
  static String get searchingDriverSubtitle => _t(
      'نحن نبحث عن سائق قريب لقبول رحلتك…',
      'We are looking for a nearby driver to accept your trip…');
  static String get estimatedArrivalTime =>
      _t('الوقت المتوقع للوصول', 'Estimated Arrival Time');
  static String get cancelTrip => _t('إلغاء الرحلة', 'Cancel Trip');

  // ─── Active Trip ───
  static String get driverOnWay =>
      _t('السائق في الطريق إليك', 'Driver is on the way');
  static String get driverArrived => _t('السائق وصل', 'Driver has arrived');
  static String get driverArrivingIn =>
      _t('سيصلك السائق خلال', 'Driver arriving in');
  static String get minutesPlural => _t('دقائق', 'minutes');
  static String get changeText => _t('تغيير', 'Change');
  static String get tripInProgress => _t('الرحلة جارية', 'Trip in Progress');
  static String get arrivingToDestination =>
      _t('الوصول للوجهة', 'Arriving to Destination');
  static String get waitingChargeWarning => _t(
      'سيتم احتساب رسوم الانتظار بعد مرور الوقت المجاني',
      'Waiting charges will apply after the free waiting time');

  // ─── Cancel Reasons ───
  static String get cancelReasonChangedMind =>
      _t('تغير رأيي', 'Changed my mind');
  static String get cancelReasonDriverFar =>
      _t('السائق بعيد جداً', 'Driver is too far');
  static String get cancelReasonFoundOther =>
      _t('وجدت وسيلة أخرى', 'Found another ride');
  static String get cancelReasonMistake =>
      _t('طلبت بالخطأ', 'Requested by mistake');
  static String get cancelReasonOther => _t('أخرى', 'Other');
  static String get errorOccurred => _t('حدث خطأ', 'An error occurred');

  // ─── Profile ───
  static String get profile => _t('بروفايل', 'Profile');
  static String get editProfile => _t('تعديل البروفايل', 'Edit Profile');
  static String get name => _t('الإسم', 'Name');
  static String get email => _t('البريد الإلكتروني', 'Email');
  static String get selectGender => _t('تحديد النوع', 'Select Gender');
  static String get male => _t('ذكر', 'Male');
  static String get female => _t('أنثى', 'Female');
  static String get save => _t('حفظ', 'Save');
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get profileUpdated =>
      _t('تم تحديث البروفايل بنجاح', 'Profile updated successfully');
  static String get idLabel => _t('الرقم التعريفي', 'ID');

  // ─── Package Delivery ───
  static String get sendReceivePackage =>
      _t('إرسال واستقبال الطرود', 'Send & Receive Packages');
  static String get sendReceiveSubtitle => _t(
      'خدمات الطرود لدينا تجعل إرسال واستقبال الطرود أمرًا بسيطًا ومريحًا',
      'Our delivery services make sending and receiving packages simple and convenient');
  static String get sendParcel => _t('إرسال طرد', 'Send Parcel');
  static String get receiveParcel => _t('استقبال طرد', 'Receive Parcel');
  static String get pickupAddress => _t('عنوان استلام الطرد', 'Pickup Address');
  static String get deliveryAddress => _t('عنوان التسليم', 'Delivery Address');
  static String get home => _t('البيت', 'Home');
  static String get work => _t('العمل', 'Work');
  static String get chooseFromMap => _t('اختر من الخريطة', 'Choose from Map');
  static String get packageRecipientDetails =>
      _t('تفاصيل مستلم الطرد', 'Package Recipient Details');
  static String get receiveSelf => _t('استقبل بنفسي', 'Receive Myself');
  static String get senderName => _t('إسم المرسل', 'Sender Name');
  static String get instructions => _t('تعليمات', 'Instructions');
  static String get serviceType => _t('نوع الخدمة', 'Service Type');
  static String get delegateDelivery =>
      _t('مندوب (توصيل أغراض)', 'Courier (Package Delivery)');
  static String get selectGoodsType => _t('حدد نوع البضائع', 'Select Goods Type');
  static String get quantity => _t('الكمية', 'Quantity');
  static String get specifyQuantity => _t('تحديد الكمية', 'Specify Quantity');
  static String get noQuantity =>
      _t('لا تحدد الكمية', "Don't Specify Quantity");
  static String get enterQuantity => _t('أدخل الكمية', 'Enter Quantity');
  static String get whoPays => _t('من سيدفع', 'Who Pays');
  static String get theSender => _t('المرسل', 'Sender');
  static String get theReceiver => _t('المستلم', 'Receiver');
  static String get noVehiclesAvailable =>
      _t('لا توجد مركبات متاحة لهذا المسار', 'No vehicles available for this route');
  static String get sendParcels => _t('إرسال الطرود', 'Send Parcels');
  static String get receiveParcels => _t('تلقي الطرود', 'Receive Parcels');
  static String get freeLoadingTime => _t(
      'متضمنة 20 دقيقة مجاناً من وقت التحميل والتفريغ',
      'Includes 20 minutes free loading and unloading time');
  static String get amountDue => _t('المبلغ المستحق :', 'Amount Due:');
  static String get parcelType => _t('نوع الطرد', 'Parcel Type');
  static String get invalidPromoCode =>
      _t('كود الخصم غير صالح', 'Invalid promo code');

  // ─── Driver App ───
  static String get connected => _t('متصل', 'Online');
  static String get disconnected => _t('غير متصل', 'Offline');
  static String get todayEarnings => _t('أرباح اليوم', "Today's Earnings");
  static String get completedTrips => _t('الرحلات التي تمت', 'Completed Trips');
  static String get totalDistance => _t('المسافة', 'Distance');
  static String get activityTime => _t('وقت النشاط', 'Activity Time');
  static String get joinBenefits => _t('مميزات الإنضمام', 'Joining Benefits');
  static String get youAreTheLeader =>
      _t('أنت القائد وي IQ', 'You are the Leader with IQ');

  // ─── Sidebar Items ───
  static String get notifications => _t('الاشعارات', 'Notifications');
  static String get history => _t('السجل', 'History');
  static String get wallet => _t('المحفظة', 'Wallet');
  static String get subscription => _t('الإشتراك', 'Subscription');
  static String get solveAndWin => _t('حل واكسب', 'Solve & Win');
  static String get changeLanguage => _t('تغيير اللغة', 'Change Language');
  static String get favouriteLocation =>
      _t('الموقع المفضل', 'Favourite Location');
  static String get emergency => _t('الطوارئ', 'Emergency');
  static String get technicalSupport => _t('الدعم الفني', 'Technical Support');
  static String get settings => _t('الاعدادات', 'Settings');
  static String get logout => _t('تسجيل خروج', 'Logout');
  static String get tripHistory => _t('تاريخ الرحلات', 'Trip History');
  static String get earnings => _t('الارباح', 'Earnings');
  static String get incentives => _t('الحوافز', 'Incentives');
  static String get reports => _t('التقارير', 'Reports');

  // ─── Notifications Page ───
  static String get clearAll => _t('مسح الكل', 'Clear All');
  static String get noNotifications => _t('لا توجد اشعارات', 'No notifications');
  static String get deleteNotification => _t('حذف الاشعار', 'Delete Notification');
  static String get deleteNotificationConfirm =>
      _t('هل أنت متأكد من حذف هذا الاشعار؟',
          'Are you sure you want to delete this notification?');
  static String get clearAllNotifications =>
      _t('مسح كل الاشعارات', 'Clear All Notifications');
  static String get clearAllNotificationsConfirm =>
      _t('هل أنت متأكد من مسح جميع الاشعارات؟',
          'Are you sure you want to clear all notifications?');

  // ─── Settings Page ───
  static String get darkMode => _t('الوضع الداكن', 'Dark Mode');
  static String get instructionsPage => _t('التعليمات', 'Instructions');
  static String get privacyPolicy => _t('سياسة الخصوصية', 'Privacy Policy');

  // ─── Referral Page ───
  static String get inviteFriendAndEarn =>
      _t('دعوة صديق واربح', 'Invite a Friend & Earn');
  static String get shareYourCode =>
      _t('شارك رمز الدعوة الخاص بك', 'Share your referral code');
  static String get inviteFriend => _t('دعوة صديق', 'Invite Friend');
  static String get codeCopied => _t('تم نسخ الكود', 'Code Copied');
  static String get referralShareMessage =>
      _t('استخدم كود الدعوة الخاص بي:', 'Use my referral code:');
  static String get forDiscount => _t('للحصول على خصم!', 'for a discount!');

  // ─── Favourite Location Page ───
  static String get locationNotSet =>
      _t('لم يتم تحديد الموقع بعد', 'Location not set yet');
  static String get addMorePlaces => _t('اضافة أماكن أكثر', 'Add more places');

  // ─── Reports Page ───
  static String get createReport => _t('إنشاء التقرير', 'Create Report');
  static String get filter => _t('فلتر', 'Filter');
  static String get selectedPeriod => _t('الفترة المختارة', 'Selected Period');
  static String get trips => _t('الرحلات', 'Trips');
  static String get cashLabel => _t('نقدي', 'Cash');
  static String get reportDetailsList =>
      _t('قائمة تفاصيل التقرير', 'Report Details List');
  static String get totalTripKm =>
      _t('إجمالي الرحلة بالكيلومترات :', 'Total Trip in KM:');
  static String get walletInstallment =>
      _t('محفظة قسط :', 'Wallet Installment:');
  static String get cashInstallment => _t('نقدي قسط :', 'Cash Installment:');
  static String get netEarnings => _t('الأرباح صافي :', 'Net Earnings:');
  static List<String> get months => LocaleService.isArabic
      ? const [
          'يناير', 'فبراير', 'مارس', 'ابريل', 'مايو', 'يونيو',
          'يوليو', 'اغسطس', 'سبتمبر', 'اكتوبر', 'نوفمبر', 'ديسمبر',
        ]
      : const [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];

  // ─── Incentive Page ───
  static String get daily => _t('يومي', 'Daily');
  static String get weekly => _t('أسبوعي', 'Weekly');
  static String get earnUpTo => _t('اكسب حتى', 'Earn up to');
  static String get byCompletingTrips => _t('بإكمال', 'by completing');
  static String get completeTrips => _t('أكمل', 'Complete');
  static String get gotIncentive =>
      _t('لقد حصلت على الحافز! 🎉', 'You got the incentive! 🎉');
  static String get didNotGetIncentive => _t(
      'للأسف لم تحصل على الحافز',
      "Unfortunately, you didn't get the incentive");
  static String get completeMoreForIncentive =>
      _t('أكمل المزيد للحصول على الحافز!', 'Complete more to get the incentive!');
  static String get achievedGoal =>
      _t('لقد حققت الهدف بنجاح! ✅', 'You achieved the goal! ✅');
  static String get didNotCompleteGoal =>
      _t('لم تكمل الهدف بعد', "You haven't completed the goal yet");
  static String get completeFirstTripForIncentive => _t(
      'أكمل أول رحلة لفتح الحوافز!',
      'Complete your first trip to unlock incentives!');
  static String get noIncentivesAvailable =>
      _t('لا توجد حوافز متاحة', 'No incentives available');

  // ─── Earnings Page ───
  static String get totalEarnings => _t('إجمالي الأرباح', 'Total Earnings');
  static String get loginTime => _t('وقت تسجيل الدخول', 'Login Time');
  static String get distanceTraveled =>
      _t('المسافة المقطوعة', 'Distance Traveled');
  static String get noSummaryForDay =>
      _t('لا يوجد ملخص لهذا اليوم', 'No summary for this day');

  // ─── Trip History Page ───
  static String get tripHistoryTitle => _t('سجل الرحلات', 'Trip History');
  static String get tripDetailsTitle => _t('تفاصيل الرحلة', 'Trip Details');
  static String get completed => _t('مكتمل', 'Completed');
  static String get upcoming => _t('قادم', 'Upcoming');
  static String get cancelled => _t('تم الالغاء', 'Cancelled');
  static String get driverData => _t('بيانات السائق', 'Driver Data');
  static String get tripRating => _t('تقييم الرحلة', 'Trip Rating');
  static String get baseDistancePrice =>
      _t('سعر المسافة الأساسية', 'Base Distance Price');
  static String get extraDistancePrice =>
      _t('سعر المسافة الإضافية', 'Extra Distance Price');
  static String get noTripsFound => _t('لا توجد رحلات', 'No trips found');
  static String get color => _t('اللون', 'Color');
  static String get minute => _t('دقيقة', 'min');
  static String get km => _t('كم', 'km');

  // ─── Support Chat ───
  static String get adminChat => _t('دردشة المسؤول', 'Admin Chat');
  static String get activeNow => _t('نشط الآن', 'Active now');
  static String get sendYourMessage =>
      _t('ارسال رسالتك ..', 'Send your message...');
  static String get today => _t('اليوم', 'Today');
  static String get noMessagesYet => _t('لا توجد رسائل بعد', 'No messages yet');
  static String get startConversation => _t(
      'ابدأ المحادثة بإرسال رسالة',
      'Start the conversation by sending a message');
  static String get messageSendFailed =>
      _t('فشل إرسال الرسالة', 'Failed to send message');

  // ─── Common ───
  static String get ok => _t('حسناً', 'OK');
  static String get retry => _t('إعادة المحاولة', 'Retry');
  static String get error => _t('خطأ', 'Error');
  static String get noInternet =>
      _t('لا يوجد اتصال بالإنترنت', 'No internet connection');
  static String get loading => _t('جاري التحميل...', 'Loading...');
  static String get somethingWrong => _t('حدث خطأ ما', 'Something went wrong');

  // ─── Wallet ───
  static String get walletBalance => _t('رصيد المحفظة', 'Wallet Balance');
  static String get currentBalance => _t('الرصيد الحالي', 'Current Balance');
  static String get cashPayment => _t('الدفع النقدي', 'Cash Payment');
  static String get primaryPaymentMethod =>
      _t('وسيلة الدفع الأساسية', 'Primary Payment Method');
  static String get recentTransactions =>
      _t('المعاملات الأخيرة', 'Recent Transactions');
  static String get depositAmount => _t('إيداع مبلغ', 'Deposit Amount');
  static String get transferMoney => _t('تحويل أموال', 'Transfer Money');
  static String get depositMoney => _t('إيداع أموال', 'Deposit Money');
  static String get addAmount => _t('إضافة المبلغ', 'Add Amount');
  static String get userType => _t('نوع المستخدم', 'User Type');
  static String get driver => _t('سائق', 'Driver');
  static String get user => _t('مستخدم', 'User');
  static String get theAmount => _t('المبلغ', 'Amount');
  static String get enterValueAboveZero =>
      _t('أدخل قيمة أعلى من 0', 'Enter a value above 0');
  static String get mobileNumber => _t('رقم الجوال', 'Mobile Number');
  static String get addBalance => _t('إضافة رصيد', 'Add Balance');
  static String get transfer => _t('تحويل', 'Transfer');
  static String get withdraw => _t('سحب', 'Withdraw');
  static String get addTheBalance => _t('إضافة الرصيد', 'Add Balance');
  static String get enterAmount => _t('أدخل المبلغ', 'Enter Amount');
  static String get withdrawBalance => _t('سحب الرصيد', 'Withdraw Balance');
  static String get enterWithdrawAmount =>
      _t('أدخل المبلغ المراد سحبه', 'Enter the withdrawal amount');
  static String get updatePaymentMethod =>
      _t('تحديث طريقة الدفع', 'Update Payment Method');
  static String get requestWithdraw =>
      _t('طلب سحب المبلغ', 'Request Withdrawal');
  static String get noPaymentHistory =>
      _t('لا يوجد سجل للدفع حتى الآن', 'No payment history yet');
  static String get startYourTrip =>
      _t('ابدأ رحلتك بحجز رحلة اليوم!', 'Start your trip by booking a ride today!');
  static String get depositMadeByYou =>
      _t('تم اجراء إيداع بواسطتك', 'Deposit made by you');
  static String get balanceAdded => _t('تم اضافة رصيد', 'Balance added');
  static String get balanceWithdrawn => _t('تم سحب رصيد', 'Balance withdrawn');
  static String get transferSuccess =>
      _t('تم تحويل المبلغ بنجاح', 'Transfer completed successfully');
  static String get depositSuccess =>
      _t('تم الإيداع بنجاح', 'Deposit completed successfully');
  static String get withdrawSuccess =>
      _t('تم طلب السحب بنجاح', 'Withdrawal request submitted successfully');
  static String get insufficientBalance =>
      _t('رصيد غير كافي', 'Insufficient balance');
  static String get enterValidAmount =>
      _t('أدخل مبلغ صحيح', 'Enter a valid amount');
  static String get enterValidPhone =>
      _t('أدخل رقم هاتف صحيح', 'Enter a valid phone number');

  // ─── Data Source Errors ───
  static String get failedToGetPrices =>
      _t('فشل في الحصول على الأسعار', 'Failed to get prices');
  static String get failedToCreateRequest =>
      _t('فشل في إنشاء الطلب', 'Failed to create request');
  static String get failedToCancelRequest =>
      _t('فشل في إلغاء الطلب', 'Failed to cancel request');
  static String get failedToFetchCancelReasons =>
      _t('فشل في جلب أسباب الإلغاء', 'Failed to fetch cancel reasons');
  static String get failedToLoadRecentPlaces =>
      _t('فشل في تحميل الأماكن الأخيرة', 'Failed to load recent places');
  static String get failedToSubmitRating =>
      _t('فشل في إرسال التقييم', 'Failed to submit rating');
  static String get failedToChangeDropoff =>
      _t('فشل في تغيير نقطة الوصول', 'Failed to change dropoff');
  static String get failedToChangePayment =>
      _t('فشل في تغيير طريقة الدفع', 'Failed to change payment method');
  static String get invoiceNotFound =>
      _t('لم يتم العثور على الفاتورة', 'Invoice not found');
  static String get failedToFetchTripDetails =>
      _t('فشل في جلب تفاصيل الرحلة', 'Failed to fetch trip details');
  static String get failedToRespondToRequest =>
      _t('فشل في الاستجابة للطلب', 'Failed to respond to request');
  static String get failedToConfirmArrival =>
      _t('فشل في تأكيد الوصول', 'Failed to confirm arrival');
  static String get failedToStartTrip =>
      _t('فشل في بدء الرحلة', 'Failed to start trip');
  static String get failedToEndTrip =>
      _t('فشل في إنهاء الرحلة', 'Failed to end trip');
  static String get failedToConfirmPayment =>
      _t('فشل في تأكيد الدفع', 'Failed to confirm payment');
  static String get failedToCancelTrip =>
      _t('فشل في إلغاء الرحلة', 'Failed to cancel trip');
  static String get cancellingTrip =>
      _t('جاري إلغاء الرحلة...', 'Cancelling trip...');
  static String get connectionTimeout =>
      _t('انتهت مهلة الاتصال', 'Connection timed out');
  static String get noInternetConnection =>
      _t('لا يوجد اتصال بالإنترنت', 'No internet connection');
  static String get unauthorized => _t('غير مصرح', 'Unauthorized');
  static String get invalidData => _t('بيانات غير صالحة', 'Invalid data');
  static String get serverError =>
      _t('حدث خطأ في الخادم', 'Server error occurred');

  // ─── Invoice / Payment Labels ───
  static String get electronicPayment =>
      _t('دفع الكتروني', 'Electronic Payment');
  static String get currencyIQD => _t('د.ع', 'IQD');

  // ─── Fare Breakdown ───
  static String get distanceFare => _t('أجرة المسافة', 'Distance Fare');
  static String get timeFare => _t('أجرة الوقت', 'Time Fare');
  static String get waitingCharge => _t('رسوم الانتظار', 'Waiting Charge');
  static String get couponDiscount => _t('خصم الكوبون', 'Coupon Discount');
  static String get tip => _t('إكرامية', 'Tip');

  // ─── Cancel / Reason Sheets ───
  static String get cancelReason => _t('سبب الإلغاء', 'Cancel Reason');
  static String get writeReasonHere =>
      _t('اكتب السبب هنا...', 'Write the reason here...');

  // ─── Driver Info ───
  static String get newUser => _t('مستخدم جديد', 'New User');

  // ─── Swipe / Actions ───
  static String get swipeToAcceptTrip =>
      _t('مرر لقبول الرحلة', 'Swipe to accept trip');
  static String get locatePosition => _t('تحديد الموقع', 'Locate Position');
  static String get shareTrip => _t('مشاركة الرحلة', 'Share Trip');

  // ─── Rating ───
  static String get rating => _t('التقييم', 'Rating');
  static String get howWasYourTripWith =>
      _t('كيف كانت رحلتك مع', 'How was your trip with');
  static String get writeCommentHere =>
      _t('اكتب تعليقك هنا...', 'Write your comment here...');
  static String get addRating => _t('إضافة تقييم', 'Add Rating');

  // ─── Driver Trip Status ───
  static String get onTheWay => _t('في الطريق', 'On the Way');
  static String get onWayToDropoff =>
      _t('في الطريق إلى موقع الإنزال', 'On the way to dropoff');
  static String get remainingDistance =>
      _t('المسافة المتبقية', 'Remaining Distance');
  static String get remainingTime => _t('الوقت المتبقي', 'Remaining Time');
  static String get tripStatus => _t('حالة الرحلة', 'Trip Status');
  static String get remainingWaitTime =>
      _t('الوقت المتبقي لانتظار الراكب', 'Remaining wait time for passenger');
  static String get tripElapsedTime =>
      _t('الوقت المنقضي من الرحلة', 'Trip Elapsed Time');
  static String get tripArrived => _t('وصلت الرحلة', 'Trip Arrived');
  static String get startTrip => _t('إبدأ الرحلة', 'Start Trip');
  static String get endTrip => _t('نهاية الرحلة', 'End Trip');
  static String get priceLabel => _t('السعر: ', 'Price: ');

  // ─── Driver Cancel Reasons ───
  static String get vehicleIssueOrEmergency =>
      _t('مشكلة في السيارة أو ظرف طارئ', 'Vehicle issue or emergency');
  static String get passengerNotResponding => _t(
      'الراكب لا يرد على الهاتف أو الرسائل',
      'Passenger not responding to calls or messages');

  // ─── Incoming Request ───
  static String get tripDetails => _t('تفاصيل الرحلة', 'Trip Details');
  static String get reject => _t('رفض', 'Reject');
  static String get second => _t('ثانية', 'second');
  static String get rideFare => _t('أجرة الركوب', 'Ride Fare');
  static String get tripAddressesLabel =>
      _t('عناوين الرحلة', 'Trip Addresses');
  static String get autoCancelWarning =>
      _t('سيتم إلغاء الرحلة تلقائياً بعد', 'Trip will be auto-cancelled after');
  static String get totalRidesCount => _t('رحلة', 'rides');

  // ─── Map Picker ───
  static String get selectLocation => _t('حدد الموقع', 'Select Location');
  static String get resolvingLocation =>
      _t('جارٍ التحديد...', 'Resolving...');
  static String get confirmLocation => _t('تأكيد الموقع', 'Confirm Location');
  static String get unknownLocation => _t('موقع غير معروف', 'Unknown Location');

  // ─── Search Destination ───
  static String get pickupLocationHint =>
      _t('موقع الالتقاط', 'Pickup Location');
  static String get recentPlaces => _t('الأماكن الأخيرة', 'Recent Places');
  static String get savedPlaces => _t('أماكن محفوظة', 'Saved Places');
  static String get selectDestinationFromMap =>
      _t('حدد الوجهة من الخريطة', 'Select destination from map');

  // ─── Trip Invoice ───
  static String get regular => _t('عادي', 'Regular');

  // ─── Empty State ───
  static String get noDataToDisplay =>
      _t('لا يوجد بيانات للعرض', 'No data to display');

  // ─── Favourite Location ───
  static String get enterAddressName =>
      _t('أدخل اسم العنوان', 'Enter address name');
  static String get addressNameHint =>
      _t('مثال: البيت، الشغل، الجامعة', 'e.g. Home, Work, University');
  static String get addFavouriteSuccess =>
      _t('تم إضافة الموقع بنجاح', 'Location added successfully');
  static String get deleteFavouriteConfirm => _t(
      'هل أنت متأكد من حذف هذا العنوان؟',
      'Are you sure you want to delete this address?');
  static String get add => _t('إضافة', 'Add');
  static String get delete => _t('حذف', 'Delete');
  static String get termsAndConditions =>
      _t('الشروط والأحكام', 'Terms & Conditions');

  // ─── Shipment / Delivery ───
  static String get shipmentVerification =>
      _t('إثبات الشحن', 'Shipment Verification');
  static String get uploadShipmentProofBefore =>
      _t('رفع إثبات الشحن قبل أو أثناء الرحلة',
          'Upload shipment proof before or during the trip');
  static String get uploadShipmentProofAfter =>
      _t('رفع إثبات الشحن بعد التوصيل',
          'Upload shipment proof after delivery');
  static String get uploadImageJpgPng =>
      _t('رفع صورة JPG, PNG', 'Upload image JPG, PNG');
  static String get continueText => _t('متابعة', 'Continue');
  static String get getCustomerSignature =>
      _t('الحصول على توقيع العميل عند التسليم',
          'Get customer signature upon delivery');
  static String get resetSignature => _t('إعادة التوقيع', 'Reset Signature');
  static String get confirmSignature => _t('تأكيد التوقيع', 'Confirm Signature');
  static String get pickGoods => _t('استلام البضاعة', 'Pick Goods');
  static String get dispatchGoods => _t('تسليم البضاعة', 'Dispatch Goods');
  static String get proofUploadedSuccess =>
      _t('تم رفع الإثبات بنجاح', 'Proof uploaded successfully');
  static String get signatureRequired =>
      _t('يرجى الحصول على التوقيع أولاً', 'Please get the signature first');
  static String get proofRequired =>
      _t('يرجى رفع إثبات الشحن أولاً', 'Please upload shipment proof first');

  // ─── Vehicle Info ───
  static String get vehicleInfo => _t('معلومات السيارة', 'Vehicle Info');
  static String get vehicleType => _t('نوع المركبة', 'Vehicle Type');
  static String get vehicleMake => _t('ماركة السيارة', 'Vehicle Make');
  static String get vehicleModel => _t('طراز السيارة', 'Vehicle Model');
  static String get vehicleNumber => _t('رقم السيارة', 'Vehicle Number');
  static String get vehicleColor => _t('لون السيارة', 'Vehicle Color');
  static String get edit => _t('تحرير', 'Edit');
  static String get vehicleUpdatedSuccess =>
      _t('تم تحديث معلومات السيارة بنجاح', 'Vehicle info updated successfully');
  static String get vehicleUpdateFailed =>
      _t('فشل تحديث معلومات السيارة', 'Failed to update vehicle info');
  static String get updating => _t('جاري التحديث...', 'Updating...');

  // ─── Document Verification ───
  static String get documentVerification =>
      _t('قائمة التوثيق', 'Document Verification');
  static String get verified => _t('تم التوثيق', 'Verified');
  static String get uploadRequired => _t('مطلوب الرفع', 'Upload Required');
  static String get pending => _t('قيد المراجعة', 'Pending');
  static String get declined => _t('مرفوض', 'Declined');
  static String get tapToUpload => _t('اضغط للرفع', 'Tap to Upload');
  static String get tapToView => _t('اضغط للعرض', 'Tap to View');
  static String get frontImage => _t('الصورة الأمامية', 'Front Image');
  static String get backImage => _t('الصورة الخلفية', 'Back Image');
  static String get chooseImage => _t('اختر صورة', 'Choose Image');
  static String get camera => _t('الكاميرا', 'Camera');
  static String get gallery => _t('المعرض', 'Gallery');
  static String get documentUploading =>
      _t('جاري رفع المستند...', 'Uploading document...');
  static String get documentUploadedSuccess =>
      _t('تم رفع المستند بنجاح', 'Document uploaded successfully');
  static String get documentUnderReview => _t(
      'تم رفع المستند بنجاح وهو قيد المراجعة من الإدارة',
      'Document uploaded successfully and is under review');
  static String get idNumber => _t('الرقم التعريفي', 'ID Number');
  static String get expiryDate => _t('تاريخ الانتهاء', 'Expiry Date');

  // ─── Location ───
  static String get currentLocation => _t('الموقع الحالي', 'Current Location');

  // ─── Trip Invoice ───
  static String get waitingDriverPaymentConfirm =>
      _t('بانتظار تأكيد السائق لاستلام المبلغ',
          'Waiting for driver to confirm payment received');
  static String get rateTrip => _t('تقييم الرحلة', 'Rate Trip');
  static String get packageDelivery => _t('توصيل طرود', 'Package Delivery');

  // ─── Subscription ───
  static String get subscriptionTitle => _t('الإشتراك', 'Subscription');
  static String get chooseSubscription =>
      _t('اختر اشتراكك', 'Choose your Subscription');
  static String get choosePlan => _t('اختر الخطة', 'Choose Plan');
  static String get paymentMethod => _t('طريقة الدفع', 'Payment Method');
  static String get paid => _t('مدفوع', 'Paid');
  static String get free => _t('مجاني', 'Free');
  static String get walletOption => _t('محفظة', 'Wallet');
  static String get cardOption => _t('بطاقة دفع', 'Payment Card');
  static String get execute => _t('تنفيذ', 'Execute');
  static String get dailySubscription =>
      _t('اشتراك اليوم :', "Today's Subscription:");
  static String get freeTrialHint => _t(
      '• يمكنك تجربة الاشتراك المجاني لمدة 48 ساعة',
      '• You can try the free subscription for 48 hours');
  static String get subscriptionSuccess =>
      _t('تم الاشتراك بنجاح', 'Subscription successful');
  static String get subscriptionExpired =>
      _t('انتهت صلاحية الاشتراك', 'Subscription expired');
  static String get noSubscription => _t('لا يوجد اشتراك', 'No subscription');
  static String get noSubscriptionHint => _t(
      'ليس لديك اشتراك حالياً. اختر خطة للبدء في استقبال الطلبات.',
      'You have no active subscription. Choose a plan to start receiving orders.');
  static String get subscriptionType => _t('نوع الإشتراك :', 'Subscription Type:');
  static String get price => _t('السعر :', 'Price:');
  static String get expiryDateTime =>
      _t('تاريخ ووقت اللإنتهاء :', 'Expiry Date & Time:');
  static String get validUntil => _t('صالحة حتى', 'Valid until');
  static String get wasValidUntil => _t('كانت صالحة حتى', 'Was valid until');
  static String get defaultPlanName => _t('أسبوعي', 'Weekly');
  static String get yes => _t('نعم', 'Yes');
  static String get subscriptionRequiredPrompt => _t(
      'يجب عليك الاشتراك في إحدى الخطط للبدء في استقبال الطلبات',
      'You must subscribe to a plan to start receiving orders');
  static String get or => _t('أو', 'or');
  static String get continueWithoutPlans =>
      _t('الاستمرار بدون خطط', 'Continue without plans');
  static String get commissionModeHint => _t(
      'يمكنك العمل بنظام العمولة بدون الحاجة إلى اشتراك',
      'You can work on commission without needing a subscription');

  // ─── POS QR Payment ───
  static String get scanQrCode => _t('مسح QR الدفع', 'Scan Payment QR');
  static String get scanQrInstruction => _t(
      'وجّه الكاميرا نحو رمز الـ QR الظاهر على جهاز الدفع',
      'Point the camera at the QR code on the payment device');
  static String get posPaymentSuccess =>
      _t('تم الدفع بنجاح', 'Payment successful');
  static String get posPaymentFailed =>
      _t('فشلت عملية الدفع', 'Payment failed');
  static String get invalidQrCode => _t(
      'رمز QR غير صالح — يرجى مسح الرمز الصحيح',
      'Invalid QR code — please scan the correct code');
  static String get responseCode => _t('كود الاستجابة', 'Response Code');
  static String get scanPosQr => _t('مسح QR جهاز الدفع', 'Scan POS QR');
  static String get orConfirmCash =>
      _t('أو تأكيد الدفع النقدي', 'or confirm cash payment');

  // ─── Validation Errors ───
  static String get pleaseEnterPhone =>
      _t('يرجى إدخال رقم الجوال', 'Please enter your phone number');
  static String get invalidPhone =>
      _t('رقم الجوال غير صحيح', 'Invalid phone number');
  static String get pleaseEnterOtp =>
      _t('يرجى إدخال رمز التحقق', 'Please enter the verification code');
  static String get otpMustBeDigits =>
      _t('رمز التحقق يجب أن يكون', 'Verification code must be');
  static String get digits => _t('أرقام', 'digits');
  static String get pleaseEnterName =>
      _t('يرجى إدخال الإسم', 'Please enter your name');
  static String get nameTooShort => _t('الإسم قصير جداً', 'Name is too short');
  static String get invalidEmail =>
      _t('البريد الإلكتروني غير صحيح', 'Invalid email address');
  static String get pleaseEnterValidPhone =>
      _t('يرجى إدخال رقم هاتف صحيح', 'Please enter a valid phone number');
  static String get pleaseSelectGender =>
      _t('يرجى تحديد النوع', 'Please select gender');

  // ─── Error Messages (Data Sources) ───
  static String get failedToLoadUserData =>
      _t('فشل تحميل بيانات المستخدم', 'Failed to load user data');
  static String get failedToToggleStatus =>
      _t('فشل تغيير الحالة', 'Failed to toggle status');
  static String get failedToLoadServiceTypes =>
      _t('فشل تحميل أنواع الخدمة', 'Failed to load service types');
  static String get failedToLoadActiveTrips =>
      _t('فشل تحميل الرحلات النشطة', 'Failed to load active trips');
  static String get connectionTimeoutRetry =>
      _t('انتهت مهلة الاتصال، حاول مرة أخرى', 'Connection timed out, please try again');
  static String get unexpectedError =>
      _t('حدث خطأ غير متوقع', 'An unexpected error occurred');
  static String get failedToRegister =>
      _t('فشل التسجيل', 'Registration failed');
  static String get failedToLoadConversation =>
      _t('فشل تحميل المحادثة', 'Failed to load conversation');
  static String get failedToSendMessage =>
      _t('فشل إرسال الرسالة', 'Failed to send message');
  static String get failedToUpdateReadStatus =>
      _t('فشل تحديث حالة القراءة', 'Failed to update read status');
  static String get failedToLoadNotifications =>
      _t('فشل تحميل الاشعارات', 'Failed to load notifications');
  static String get failedToDeleteNotification =>
      _t('فشل حذف الاشعار', 'Failed to delete notification');
  static String get failedToClearNotifications =>
      _t('فشل مسح الاشعارات', 'Failed to clear notifications');
  static String get failedToUpdateLocation =>
      _t('فشل تحديث الموقع', 'Failed to update location');
  static String get failedToResolveAddress =>
      _t('فشل في تحديد العنوان', 'Failed to resolve address');
  static String get locationPermissionDenied =>
      _t('تم رفض إذن الموقع', 'Location permission denied');
  static String get failedToLoadSubscriptionPlans =>
      _t('فشل تحميل خطط الاشتراك', 'Failed to load subscription plans');
  static String get failedToSubscribe =>
      _t('فشل الاشتراك', 'Subscription failed');
  static String get failedToLoadFavourites =>
      _t('فشل جلب المواقع المفضلة', 'Failed to load favourite locations');
  static String get failedToAddLocation =>
      _t('فشل إضافة الموقع', 'Failed to add location');
  static String get failedToDeleteLocation =>
      _t('فشل حذف الموقع', 'Failed to delete location');
  static String get invalidResponse =>
      _t('استجابة غير صالحة', 'Invalid response');
  static String get failedToLoadProfile =>
      _t('فشل تحميل البروفايل', 'Failed to load profile');
  static String get failedToUpdateProfile =>
      _t('فشل تحديث البروفايل', 'Failed to update profile');
  static String get failedToLoadGoodsTypes =>
      _t('فشل في جلب أنواع البضائع', 'Failed to load goods types');
  static String get failedToLoadTripHistory =>
      _t('فشل تحميل سجل الرحلات', 'Failed to load trip history');
  static String get tripNotFound =>
      _t('لم يتم العثور على الرحلة', 'Trip not found');
  static String get failedToLoadTripDetails =>
      _t('فشل تحميل تفاصيل الرحلة', 'Failed to load trip details');
  static String get failedToLoadEarnings =>
      _t('فشل تحميل الأرباح', 'Failed to load earnings');
  static String get paymentLinkNotReceived =>
      _t('لم يتم استلام رابط الدفع', 'Payment link not received');
  static String get failedToLoadWallet =>
      _t('فشل تحميل المحفظة', 'Failed to load wallet');
  static String get failedToCreatePayment =>
      _t('فشل إنشاء عملية الدفع', 'Failed to create payment');
  static String get failedToTransfer =>
      _t('فشل التحويل', 'Transfer failed');
  static String get failedToLoadReports =>
      _t('فشل تحميل التقارير', 'Failed to load reports');
  static String get failedToLoadIncentives =>
      _t('فشل تحميل الحوافز', 'Failed to load incentives');
  static String get failedToLoadImage =>
      _t('تعذر تحميل الصورة', 'Failed to load image');
  static String get failedToLoadContent =>
      _t('فشل تحميل المحتوى', 'Failed to load content');
  static String get paymentFailedRetry => _t(
      'فشلت عملية الدفع، يرجى المحاولة مرة أخرى',
      'Payment failed, please try again');
  static String get phoneNotAvailable =>
      _t('رقم الهاتف غير متوفر', 'Phone number not available');

  // ─── UI Labels & Status ───
  static String get activeTrips => _t('الرحلات النشطة', 'Active Trips');
  static String get statusAccepted => _t('تم القبول', 'Accepted');
  static String get statusDriverArrived => _t('السائق وصل', 'Driver Arrived');
  static String get statusOnWay => _t('في الطريق', 'On the Way');
  static String get statusCompleted => _t('مكتملة', 'Completed');
  static String get statusCancelled => _t('ملغية', 'Cancelled');
  static String get statusCompletedShort => _t('مكتمل', 'Completed');
  static String get statusCancelledShort => _t('تم الإلغاء', 'Cancelled');
  static String get statusUpcoming => _t('قادم', 'Upcoming');
  static String get statusUnknown => _t('غير معروف', 'Unknown');
  static String get driverNotFound =>
      _t('لم يتم العثور على سائق', 'Driver not found');
  static String get fromLabel => _t('من:', 'From:');
  static String get toLabel => _t('إلى:', 'To:');
  static String get searchPlace => _t('ابحث عن مكان...', 'Search for a place...');
  static String get recipientNameHint => _t('عبد الرحمن', 'Recipient name');
  static String get notesHint =>
      _t('ملاحظات أو تعليمات إضافية...', 'Notes or additional instructions...');
  static String get defaultDriverName => _t('سائق', 'Driver');
  static String get defaultVehicleType => _t('تاكسي', 'Taxi');
  static String get taxiVip => _t('تاكسيVIP', 'Taxi VIP');
  static String get provinces => _t('محافظات', 'Provinces');
  static String get yourDelegate => _t('مندوبك', 'Your Courier');
  static String get firstTripFree =>
      _t('رحلتك الأولى مجاناً', 'Your First Trip is Free');
  static String get firstTripFreeSubtitle => _t(
      'استمتع بأول رحلة مجانية مع IQ تاكسي',
      'Enjoy your first free trip with IQ Taxi');
  static String get changeLanguageTitle =>
      _t('تغيير اللغة', 'Change Language');
  static String get arabic => _t('العربية', 'Arabic');
  static String get waitingForPassenger =>
      _t('الوقت المتبقي لانتظار الراكب', 'Remaining wait time for passenger');
  static String get am => _t('ص', 'AM');
  static String get pm => _t('م', 'PM');

  // ─── Driver Login Marketing ───
  static String get benefit1 =>
      _t('سيارتك ملكك ماكو نسبة من الأرباح', 'Your car, your earnings — no profit sharing');
  static String get benefit2 =>
      _t('أرباح شهرية توصل 2,000,000', 'Monthly earnings up to 2,000,000');
  static String get benefit3 => _t('حوافز وجوائز', 'Incentives & rewards');
  static String get benefit4 => _t(
      'عمولة ثابتة 3000 بس باليوم الواحد',
      'Fixed commission of only 3000 per day');

  // ─── Car Color Names (Arabic) ───
  static String get colorRed => _t('أحمر', 'Red');
  static String get colorBlue => _t('أزرق', 'Blue');
  static String get colorGreen => _t('أخضر', 'Green');
  static String get colorWhite => _t('أبيض', 'White');
  static String get colorBlack => _t('أسود', 'Black');
  static String get colorYellow => _t('أصفر', 'Yellow');
  static String get colorOrange => _t('برتقالي', 'Orange');
  static String get colorGrey => _t('رمادي', 'Grey');
  static String get colorSilver => _t('فضي', 'Silver');
  static String get colorBrown => _t('بني', 'Brown');

  // ─── Currency ───
  static String get currencySymbolIQD => _t('د.ع', 'IQD');
}
