# تقرير التغييرات: ميزة ماكينات العملاء وقطع الغيار الاستهلاكية (Customer Machines & Parts)

## 1. حالة البنود المطلوبة (Status of Items)

| البند | الحالة | البيان والسبب |
|---|---|---|
| **البند 1: ترحيل قاعدة البيانات (Database Migration v10)** | **منجز بالكامل (Done)** | تم رفع إصدار المخطط إلى 10، وإنشاء جداول `customer_machines` و `machine_parts`، وتحديث `maintenance_records` و `maintenance_schedule` بإضافة عمود `customerId` مع المفاتيح الأجنبية والفهارس اللازمة. تم تفعيل النسخ الاحتياطي الوقائي التلقائي (`pre-upgrade safety backup`) قبل تطبيق الترقية، وعرض رقم إصدار قاعدة البيانات والتطبيق في الإعدادات. |
| **البند 2: ماكينات العملاء (Customer Machines)** | **منجز بالكامل (Done)** | تم إنشاء نموذج `MachineModel`، ومستودع `MachineRepository`، و `MachineCubit`، وحوار الإضافة والتعديل `MachineFormDialog`، وإضافة تبويب مخصص للماكينات في صفحة تفاصيل العميل مع دعم الحذف والارتباط التسلسلي (Cascade Delete). |
| **البند 3: قطع الغيار الاستهلاكية وسجل الاستبدال (Machine Parts & Replacement)** | **منجز بالكامل (Done)** | تم إنشاء نموذج `MachinePartModel` مع محددات الحالة (`isOverdue` و `isDueSoon` خلال 14 يوم)، ومستودع `MachinePartRepository` مع خصم المخزون الذري داخل معاملة واحدة (`single transaction`)، و `MachinePartCubit`، وحوار الاستبدال `MachinePartFormDialog` بشرائح اختيار سريعة وتنبيه المخزون، وشاشة تفاصيل الماكينة `MachineDetailScreen`. |
| **البند 4: عرض صيانة العميل (Customer Maintenance View)** | **منجز بالكامل (Done)** | تم ربط سجلات وجدول الصيانة باسم العميل في `MaintenanceRepository` عبر `LEFT JOIN`، وتحديث `MaintenanceFormScreen` لاختيار العميل اختيارياً، وإضافة شريط تصفية بالعميل وعرض اسم العميل على البطاقات في `MaintenanceScreen`، وبناء تبويب ملخص الصيانة المتقدم في `CustomerDetailScreen`، ودمج ماكينات العملاء في البحث الشامل `GlobalSearchScreen`. |
| **البند 5: توافق النسخ الاحتياطي والاستعادة (Backup & Restore Compatibility)** | **منجز بالكامل (Done)** | تم التأكد من أن جداول الماكينات الجديدة اختيارية أثناء التحقق من الاستعادة (`_optionalTables`) في `BackupService` لضمان استعادة أي نسخ احتياطية قديمة بنجاح وترقيتها تلقائياً إلى الإصدار 10، وتحديث `main.dart` لإعادة تحميل جميع الـ Cubits النشطة بعد الاستعادة. |

---

## 2. علاقة الميزة الجديدة بوحدة الصيانة الحالية (Relationship to Existing Maintenance Module)

- **وحدة الصيانة السابقة (`Maintenance` / `Fixes`)**:
  - كانت تركز على المعدات الداخلية في المخزون (`equipment` / `inventory`) وعلى الإصلاحات الورشية الخارجية (`fixes`).
  - لم تكن تدعم ماكينات الضواغط المركبة لدى مواقع العملاء، ولا تتبع العمر التشغيلي لقطع الغيار الاستهلاكية الدورية (فلاتر الزيت، فواصل الزيت، فلاتر الهواء، السيور، الزيوت).
- **الميزة الجديدة (`Customer Machines & Machine Parts`)**:
  - تخصصت في متابعة أصول ومعدات العملاء في مواقعهم بدقة (النوع، الموديل، سنة الصنع، الرقم التسلسلي، تاريخ التركيب).
  - توفر دورة حياة زمنية وتراكمية لقطع الغيار لكل ماكينة مع تنبيهات استباقية (مستحق الآن باللون الأحمر، يقترب موعده باللون البرتقالي).
  - قامت بتوسيع وتوحيد وحدة الصيانة العامة عن طريق إضافة حقل `customerId` الاختياري لسجلات الصيانة وجداولها، مما سمح بتصفية الصيانة بحسب العميل وعرض تاريخ الصيانة الكامل للعميل داخل ملفه دون المساس بأي من وظائف الصيانة الداخلية القائمة.

---

## 3. إحصائيات الفروقات البرمجية (`git diff --stat fixes/phase-2-backup`)

```text
 lib/cubits/machine/machine_cubit.dart              | 114 +++
 lib/cubits/machine_part/machine_part_cubit.dart    | 143 ++++
 lib/database/database_constants.dart               |  39 +
 lib/database/database_service.dart                 |  65 ++
 lib/database/migration_manager.dart                | 156 +++-
 lib/main.dart                                      |   5 +
 lib/models/machine_model.dart                      |  96 +++
 lib/models/machine_part_model.dart                 | 130 +++
 lib/models/maintenance_record_model.dart           |  16 +
 lib/models/maintenance_schedule_model.dart         |  16 +
 lib/repositories/interfaces/i_machine_part_repository.dart |  31 +
 lib/repositories/interfaces/i_machine_repository.dart      |  25 +
 lib/repositories/machine_part_repository.dart      | 215 +++++
 lib/repositories/machine_repository.dart           | 180 ++++
 lib/repositories/maintenance_repository.dart       |  57 +-
 lib/repositories/search_repository.dart            |  11 +-
 lib/screens/customers/customer_detail_screen.dart  | 930 ++++++++++++++++++---
 lib/screens/customers/customers_screen.dart        |   2 +
 lib/screens/machines/machine_detail_screen.dart    | 453 ++++++++++
 lib/screens/machines/machine_form_dialog.dart      | 399 +++++++++
 lib/screens/machines/machine_part_form_dialog.dart | 587 +++++++++++++
 lib/screens/maintenance/maintenance_form_screen.dart       |  44 +
 lib/screens/maintenance/maintenance_screen.dart    | 270 +++++-
 lib/screens/search/global_search_screen.dart       |  66 +-
 lib/screens/settings/settings_screen.dart          |  67 ++
 lib/services/backup_service.dart                   |  24 +
 lib/services/validation_service.dart               |  13 +
 test/backup_restore_compatibility_test.dart        | 178 ++++
 test/customer_machines_test.dart                   | 134 +++
 test/customer_maintenance_test.dart                | 202 +++++
 test/database_migration_v10_test.dart              | 226 +++++
 test/machine_parts_test.dart                       | 178 ++++
 32 files changed, 4879 insertions(+), 193 deletions(-)
```

---

## 4. بيان الملفات المعدلة والمضافة (What & Why per File)

1. [database_constants.dart](file:///d:/Jumaa/lib/database/database_constants.dart):
   - **ما تم**: إضافة أسماء جداول وأعمدة ماكينات العملاء وقطع الغيار وحقل `customerId` في الصيانة.
   - **السبب**: منع الأخطاء الإملائية وتوحيد مسميات الجداول والحقول عبر كامل طبقات التطبيق.
2. [database_service.dart](file:///d:/Jumaa/lib/database/database_service.dart):
   - **ما تم**: فحص إصدار قاعدة البيانات وإنشاء نسخة احتياطية وقائية قبل الترقية عبر اتصال منفصل للقراءة فقط.
   - **السبب**: منع قيود SQLite على أمر `VACUUM INTO` داخل معاملات الترقية التلقائية وحماية بيانات المستخدم.
3. [migration_manager.dart](file:///d:/Jumaa/lib/database/migration_manager.dart):
   - **ما تم**: إضافة ترحيل v10 لجداول وفهارس الماكينات وقطع الغيار وأعمدة العملاء مع التحقق الدفاعي من الجداول.
   - **السبب**: ترقية المخطط بسلاسة وأمان مع الحفاظ على التوافق الرجعي لكافة النسخ السابقة.
4. [settings_screen.dart](file:///d:/Jumaa/lib/screens/settings/settings_screen.dart):
   - **ما تم**: عرض بطاقة إصدار التطبيق ورقم إصدار قاعدة البيانات (`v10`) في تبويب الشركة.
   - **السبب**: تمكين المستخدم والمسؤول من التحقق المرئي الفوري من سلامة الترقية ومطابقة الإصدار.
5. [machine_model.dart](file:///d:/Jumaa/lib/models/machine_model.dart):
   - **ما تم**: إنشاء كائن البيانات لماكينة العميل مع دوال التحويل `toMap`/`fromMap` و `copyWith`.
   - **السبب**: تمثيل بيانات الماكينات (النوع، الموديل، سنة الصنع، الرقم التسلسلي، تاريخ التركيب).
6. [i_machine_repository.dart](file:///d:/Jumaa/lib/repositories/interfaces/i_machine_repository.dart):
   - **ما تم**: تعريف العقد البرمجي لمستودع ماكينات العملاء.
   - **السبب**: الالتزام بمبدأ فصل الاعتماديات وإتاحة الاختبارات الأحادية.
7. [machine_repository.dart](file:///d:/Jumaa/lib/repositories/machine_repository.dart):
   - **ما تم**: تنفيذ عمليات الاستعلام والإضافة والتعديل والحذف وتدوين سجل التدقيق للماكينات.
   - **السبب**: إدارة تخزين واسترجاع ماكينات العملاء مع تأكيد تطبيق قيود السلامة.
8. [machine_cubit.dart](file:///d:/Jumaa/lib/cubits/machine/machine_cubit.dart):
   - **ما تم**: إدارة الحالة والعمليات لماكينات العملاء مع دعم التحديث المتزامن.
   - **السبب**: تحديث واجهات المستخدم في الوقت الفعلي عند إضافة أو تعديل أو حذف أي ماكينة.
9. [validation_service.dart](file:///d:/Jumaa/lib/services/validation_service.dart):
   - **ما تم**: إضافة دالة التحقق من سنة الصنع `validateManufactureYear` (بين عام 1950 والعام الحالي).
   - **السبب**: منع إدخال سنوات تصنيع غير منطقية أو مستقبلية.
10. [machine_form_dialog.dart](file:///d:/Jumaa/lib/screens/machines/machine_form_dialog.dart):
    - **ما تم**: نافذة حوارية منبثقة لإضافة وتعديل بيانات الماكينة مع اختيار التواريخ والسنوات.
    - **السبب**: توفير واجهة سريعة ومريحة للمستخدم لإدارة الماكينات دون مغادرة الصفحة.
11. [customers_screen.dart](file:///d:/Jumaa/lib/screens/customers/customers_screen.dart):
    - **ما تم**: استدعاء تحديث `MachineCubit` عند حذف أي عميل.
    - **السبب**: مزامنة حالة التطبيق فور حدوث الحذف التسلسلي للعميل وماكيناته.
12. [machine_part_model.dart](file:///d:/Jumaa/lib/models/machine_part_model.dart):
    - **ما تم**: كائن بيانات قطع الغيار مع محددات الحالة الزمنية `isOverdue` و `isDueSoon`.
    - **السبب**: دعم مؤشرات الصيانة الوقائية الاستباقية لقطع الغيار الاستهلاكية.
13. [i_machine_part_repository.dart](file:///d:/Jumaa/lib/repositories/interfaces/i_machine_part_repository.dart):
    - **ما تم**: تعريف العقد البرمجي لمستودع قطع غيار الماكينات.
    - **السبب**: عزل منطق استبدال القطع والخصم من المخزون وتسهيل اختباره.
14. [machine_part_repository.dart](file:///d:/Jumaa/lib/repositories/machine_part_repository.dart):
    - **ما تم**: تنفيذ عمليات إدارة قطع الغيار مع الخصم الذري من المخزون داخل معاملة واحدة.
    - **السبب**: ضمان سلامة العمليات وتفادي عدم اتساق بيانات المخزون مع عمليات الاستبدال.
15. [machine_part_cubit.dart](file:///d:/Jumaa/lib/cubits/machine_part/machine_part_cubit.dart):
    - **ما تم**: إدارة حالة قطع الغيار وسجل الاستبدال لكل ماكينة مع ردود نداء المخزون.
    - **السبب**: توفير تفاعل فوري في شاشات الماكينة وتحديث كميات المخزون فورياً.
16. [machine_part_form_dialog.dart](file:///d:/Jumaa/lib/screens/machines/machine_part_form_dialog.dart):
    - **ما تم**: حوار تسجيل استبدال قطعة غيار مع شرائح اختيار سريعة والربط الاختياري بالمخزون وتنبيه انخفاض الرصيد.
    - **السبب**: تبسيط إدخال قطع غيار الضواغط (فلاتر وزيوت) وربطها التلقائي بحركة المستودع.
17. [machine_detail_screen.dart](file:///d:/Jumaa/lib/screens/machines/machine_detail_screen.dart):
    - **ما تم**: شاشة عرض تفاصيل الماكينة وسجل استبدال قطع الغيار بترتيب زمني مع إبراز الحالات المستحقة.
    - **السبب**: إعطاء المستخدم سجلاً فنياً دقيقاً لكل ماكينة وتسهيل عمليات الصيانة.
18. [maintenance_record_model.dart](file:///d:/Jumaa/lib/models/maintenance_record_model.dart):
    - **ما تم**: إضافة حقلي `customerId` و `customerName` إلى نموذج سجل الصيانة.
    - **السبب**: ربط عمليات الصيانة المنفذة بالعميل مباشرة.
19. [maintenance_schedule_model.dart](file:///d:/Jumaa/lib/models/maintenance_schedule_model.dart):
    - **ما تم**: إضافة حقلي `customerId` و `customerName` إلى نموذج الصيانة المجدولة.
    - **السبب**: دعم جدولة مواعيد الصيانة الوقائية المخصصة لكل عميل.
20. [maintenance_repository.dart](file:///d:/Jumaa/lib/repositories/maintenance_repository.dart):
    - **ما تم**: تحديث استعلامات الصيانة لتنفيذ `LEFT JOIN` مع جدول العملاء لجلب أسماء العملاء.
    - **السبب**: عرض اسم العميل تلقائياً مع تفاصيل الصيانة دون الحاجة لاستعلامات إضافية.
21. [maintenance_form_screen.dart](file:///d:/Jumaa/lib/screens/maintenance/maintenance_form_screen.dart):
    - **ما تم**: إضافة حقل اختيار العميل (اختياري) في نموذج إضافة الصيانة.
    - **السبب**: تمكين تحديد ما إذا كانت الصيانة تخص عميلاً معيناً أو صيانة داخلية عامة.
22. [maintenance_screen.dart](file:///d:/Jumaa/lib/screens/maintenance/maintenance_screen.dart):
    - **ما تم**: إضافة شريط تصفية بالعميل في الأعلى وعرض اسم العميل على بطاقات الصيانة.
    - **السبب**: تسهيل فلترة واستعراض جداول وسجلات الصيانة لكل عميل على حدة.
23. [customer_detail_screen.dart](file:///d:/Jumaa/lib/screens/customers/customer_detail_screen.dart):
    - **ما تم**: تقسيم الصفحة إلى 3 تبويبات رئيسية (الفواتير، الماكينات، الصيانة) وبناء ملخص الصيانة الإحصائي والتنبيهات.
    - **السبب**: جمع كل بيانات العميل الفنية والمالية في مكان واحد بتصميم متكامل.
24. [search_repository.dart](file:///d:/Jumaa/lib/repositories/search_repository.dart):
    - **ما تم**: إضافة استعلام `UNION ALL` لماكينات العملاء للبحث بالموديل والرقم التسلسلي.
    - **السبب**: تمكين الوصول الفوري لأي ماكينة من محرك البحث الشامل.
25. [global_search_screen.dart](file:///d:/Jumaa/lib/screens/search/global_search_screen.dart):
    - **ما تم**: التعامل مع نوع `customerMachine` والفتح المباشر لشاشة تفاصيل الماكينة عند النقر عليها.
    - **السبب**: توفير تجربة انتقال سريعة للمستخدم من شاشة البحث إلى ماكينة العميل مباشرة.
26. [backup_service.dart](file:///d:/Jumaa/lib/services/backup_service.dart):
    - **ما تم**: الإبقاء على الجداول الأساسية الإلزامية واعتبار جداول الماكينات الجديدة اختيارية مع تسجيل التشخيص.
    - **السبب**: ضمان استعادة النسخ الاحتياطية السابقة القديمة دون أي أخطاء وترقيتها تلقائياً.
27. [main.dart](file:///d:/Jumaa/lib/main.dart):
    - **ما تم**: توفير `MachineCubit` عالمياً وإعادة تحميله مع باقي الـ Cubits عند اكتمال الاستعادة.
    - **السبب**: ضمان تجديد بيانات الواجهات على مستوى التطبيق بالكامل بعد استعادة نسخة احتياطية.
28. [database_migration_v10_test.dart](file:///d:/Jumaa/test/database_migration_v10_test.dart):
    - **ما تم**: اختبار ترقية قاعدة البيانات من الإصدار 9 إلى 10 والتأكد من النسخ الوقائي ووجود الجداول.
    - **السبب**: توثيق وضمان سلامة آلية الترقية التلقائية لقاعدة البيانات.
29. [customer_machines_test.dart](file:///d:/Jumaa/test/customer_machines_test.dart):
    - **ما تم**: اختبار عمليات الماكينات والتحقق من سنة الصنع والحذف التسلسلي مع العميل.
    - **السبب**: التحقق من قواعد الأعمال وسلامة القيود العلائقية.
30. [machine_parts_test.dart](file:///d:/Jumaa/test/machine_parts_test.dart):
    - **ما تم**: اختبار مؤشرات الاستحقاق وخصم المخزون الذري في معاملة واحدة.
    - **السبب**: ضمان عدم حدوث أي خلل في المخزون أو في حسابات فترات الصيانة.
31. [customer_maintenance_test.dart](file:///d:/Jumaa/test/customer_maintenance_test.dart):
    - **ما تم**: اختبار ربط الصيانة بالعميل والبحث الشامل عن الماكينات.
    - **السبب**: التحقق من تكامل وحدة الصيانة والبحث مع الماكينات الجديدة.
32. [backup_restore_compatibility_test.dart](file:///d:/Jumaa/test/backup_restore_compatibility_test.dart):
    - **ما تم**: اختبار قبول نسخة احتياطية قديمة (v9) وترقيتها بنجاح إلى v10.
    - **السبب**: ضمان أمان بيانات النسخ الاحتياطي عبر إصدارات المخطط المختلفة.

---

## 5. نتائج فحص الكود (Flutter Analyze Before vs After)

- **قبل البدء (Initial)**:
  ```text
  No issues found! (ran in 2.2s)
  ```
- **بعد الانتهاء (Final)**:
  ```text
  Analyzing Jumaa...
  No issues found! (ran in 2.4s)
  ```
- **حزم الطرف الثالث (`pubspec.yaml`)**: لم تتم إضافة أي حزمة خارجية نهائياً (0 dependencies added).

---

## 6. سيناريوهات الاختبار اليدوي المقترحة (Manual Test Scenarios)

1. **الترقية التلقائية وعرض الإصدار**:
   - فتح التطبيق والتوجه إلى `الإعدادات` > تبويب `بيانات الشركة`.
   - التحقق من ظهور بطاقة معلومات النظام التي تعرض: إصدار التطبيق `1.0.0+1` وإصدار قاعدة البيانات `v10`.
   - التحقق من مجلد `backups` للتأكد من وجود النسخة الوقائية `pre_upgrade_safety_v9_to_v10_*.db`.
2. **إضافة وإدارة ماكينات العميل**:
   - فتح شاشة `العملاء` واختيار أحد العملاء.
   - النقر على تبويب `الماكينات` ثم `ماكينة جديدة`.
   - إدخال نوع الماكينة (مثل: ضاغط حلزوني)، الموديل (مثل: GA-37)، سنة الصنع (مثل: 2022)، والرقم التسلسلي.
   - التحقق من حفظ الماكينة وظهورها في القائمة.
   - تجربة تعديل بيانات الماكينة والتأكد من تحديثها.
3. **تسجيل استبدال قطعة غيار وتنبيه المخزون**:
   - النقر على بطاقة الماكينة للانتقال إلى `تفاصيل الماكينة`.
   - النقر على `تسجيل استبدال قطعة جديدة`.
   - النقر على شريحة سريعة (مثل: "فلتر زيت").
   - اختيار الربط بصنف من المخزون:
     - إذا كانت الكمية متوفرة: التأكد من حفظ الاستبدال وخصم الكمية من المخزون تلقائياً.
     - إذا كانت الكمية منتهية: التأكد من ظهور مربع حوار التنبيه وسؤال المستخدم عن رغبته في المتابعة دون الخصم.
   - تحديد تاريخ الاستحقاق القادم والتحقق من ظهور الشارة المناسبة ("مستحق الآن" أو "يقترب موعده").
4. **ملخص صيانة العميل وتصفية الصيانة العامة**:
   - العودة إلى صفحة العميل واختيار تبويب `الصيانة`: التحقق من العدادات الإحصائية (إجمالي الماكينات، المستحقة فوراً، المقتربة) وقائمة القطع المستحقة.
   - فتح شاشة `الصيانة الدورية والوقائية` من القائمة الرئيسية:
     - إضافة مهمة صيانة جديدة واختيار العميل من القائمة المنسدلة.
     - استخدام شريط التصفية في الأعلى لاختيار العميل والتحقق من ظهور سجلاته فقط مع اسمه على البطاقة.
5. **البحث الشامل**:
   - فتح شاشة `البحث الشامل` والبحث برقم الموديل أو الرقم التسلسلي للماكينة.
   - التحقق من ظهور الماكينة بشارة "ماكينة عميل"، والنقر عليها للتأكد من الانتقال المباشر لشاشة تفاصيل الماكينة.
6. **النسخ الاحتياطي والاستعادة**:
   - إجراء نسخة احتياطية من شاشة الإعدادات.
   - استعادة نسخة احتياطية والتحقق من بقاء الماكينات وسجلات الاستبدال وإعادة تحميل الشاشات تلقائياً.

---

## 7. القرارات المتخذة والمخاطر المتبقية (Decisions & Remaining Risks)

### القرارات المتخذة نيابة عن العميل (Decisions Made on Behalf):
1. **النسخ الاحتياطي الوقائي قبل الترقية عبر اتصال منفصل**:
   - لكون أمر `VACUUM INTO` في SQLite لا يمكن تنفيذه داخل معاملة ترقية نشطة (`onUpgrade`)، تم فحص رقم الإصدار عبر اتصال منفصل للقراءة فقط قبل فتح اتصال الترقية لإنشاء النسخة الوقائية بأمان تام.
2. **عتبة تنبيه الصيانة المقتربة (`isDueSoon`)**:
   - تم تحديد مدة 14 يوماً قبل تاريخ الاستحقاق لتصنيف القطعة كـ "يقترب موعدها" (باللون البرتقالي التحذيري)، بينما تعتبر القطعة "مستحقة فوراً" (باللون الأحمر) بمجرد حلول تاريخ الاستحقاق أو تجاوزه.
3. **خصم المخزون الاختياري مع نافذة تأكيد تحذيرية**:
   - عند محاولة خصم صنف غير متوفر بالمخزون، تم تصميم نافذة تأكيد تخير المستخدم بين المتابعة وتسجيل الاستبدال بدون خصم من المخزون أو إلغاء العملية لتوفير الرصيد أولاً، منعاً لتعطيل الفنيين في الميدان.
4. **تكامل صيانة العملاء مع وحدة الصيانة القديمة**:
   - تم توظيف حقل `customerId` الاختياري في جدولة وسجلات الصيانة العامة لربط كل سجلات العميل دون كسر أي تدفقات سابقة للمعدات الداخلية.

### المخاطر المتبقية والملاحظات (Remaining Risks & Notes):
1. **عداد ساعات التشغيل (Running Hours)**:
   - تم دعم تسجيل ساعات التشغيل عند الاستبدال (`runningHoursAtReplacement`). في حال رغبة العميل مستقبلاً في جدولة التنبيهات بناءً على قراءات العداد التراكمية (وليس التواريخ فقط)، يمكن إضافة جدول قراءات عداد دورية للماكينة.
2. **البيانات الحقيقية**:
   - نظراً لأن التطبيق لم يُستخدم ببيانات حقيقية حتى الآن، يُنصح بإجراء تجربة ميدانية كاملة لدورة استبدال حقيقية في ورشة العمل للتأكد من مواءمة المسميات والشاشات لسير العمل اليومي للفنيين.
