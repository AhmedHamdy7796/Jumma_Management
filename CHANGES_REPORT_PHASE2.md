# CHANGES_REPORT_PHASE2.md

> Branch: `fixes/phase-2-backup`  
> Base:   `fixes/phase-1`  
> Date:   2026-10-23

---

## 1. Status per item

| Item | Status | Notes |
|------|--------|-------|
| **1** - VACUUM INTO backup | Done | backup_service.dart fully rewritten |
| **1b** - Manual local backup UI | Done | Picker, default folder, 10-file rotation, reminder, success dialog with path+size |
| **2** - Validated restore | Done | integrity_check + core-table check, safety copy, WAL/SHM cleanup, all cubits reloaded |
| **3** - Google Drive button | Partial | Drive tab UI + settings fully built; actual upload is a stub pending OAuth setup |
| **3b** - Drive connection settings | Partial | All settings fields/dropdowns present and persistent; connect/disconnect are stubs |

---

## 2. git diff --stat fixes/phase-1..HEAD

 .gitignore                                |   3 +
 lib/config/google_config.example.dart     |  43 ++
 lib/cubits/backup/backup_cubit.dart       | 105 +++-
 lib/database/database_constants.dart      |  15 +-
 lib/main.dart                             |  15 +-
 lib/screens/settings/settings_screen.dart | 863 +++++++++++++++++++++++++-----
 lib/services/backup_service.dart          | 368 +++++++++----
 7 files changed, 1146 insertions(+), 266 deletions(-)

---

## 3. Per-file summary

| File | What changed | Why |
|------|-------------|-----|
| lib/services/backup_service.dart | Full rewrite: VACUUM INTO backup (no DB close), validated restore, safety copy, WAL/SHM cleanup, FilePicker wrappers, 10-file local rotation | Items 1, 1b, 2 |
| lib/cubits/backup/backup_cubit.dart | New states carry path+size+kind; new actions createBackupWithPicker, createLocalBackup, restoreWithPicker, restoreFromFile; onRestoreComplete callback | Items 1b, 2 |
| lib/main.dart | BackupCubit created with onRestoreComplete that reloads all global cubits | Item 2 |
| lib/database/database_constants.dart | Added lastBackupKind, lastBackupError, driveEnabled, driveFolderName, driveFolderId, driveBackupFrequency, driveKeepCount, driveWifiOnly, lastDriveBackupAt | Items 1b, 3b |
| lib/screens/settings/settings_screen.dart | 4-tab rewrite: Company (unchanged), Local Backup (new), Google Drive (new), Users (unchanged). Reminder banner, success dialog, error dialog, Drive settings form | Items 1b, 3, 3b |
| lib/config/google_config.example.dart | New: OAuth config template committed to git | Item 3 |
| .gitignore | Added lib/config/google_config.dart exclusion | Item 3 |

---

## 3b. Table Names Verification & Comparison (Restore Validation)

Comparison between tables created in `database_service.dart` (and constants in `database_constants.dart`) versus `_coreTables` checked in `backup_service.dart`:

| Table Name in `database_service.dart` | Constant in `TableNames` | Checked in `_coreTables` (`backup_service.dart`) | Notes |
|--------------------------------------|--------------------------|--------------------------------------------------|-------|
| `customers` | `TableNames.customers` | Yes | Core table |
| `purchases` | `TableNames.purchases` | Yes | Core table |
| `fixes` | `TableNames.fixes` | Yes | Core table |
| `sales_invoices` | `TableNames.salesInvoices` | Yes | Invoices (NOT `sales_invoice_items`) |
| `inventory` | `TableNames.inventory` | Yes | Inventory items (NOT `products`; accepts legacy `equipment` for v7/v8 backups) |
| `settings` | `TableNames.settings` | Yes | App & backup configuration |
| `maintenance_records` | `TableNames.maintenanceRecords` | Secondary | Linked to inventory via foreign key |
| `maintenance_schedule` | `TableNames.maintenanceSchedule` | Secondary | Linked to inventory via foreign key |
| `notes` | `TableNames.notes` | Secondary | Entity notes |
| `audit_logs` | `TableNames.auditLogs` | Secondary | System audit logs |
| `users` | N/A (`'users'`) | Secondary | Auth users |

### Key Clarifications on Mismatches:
1. **`inventory` vs `products`**: The codebase defines `inventory` (`TableNames.inventory`), never `products`. `backup_service.dart` validates `TableNames.inventory`. Furthermore, if restoring an older backup from schema v7/v8 where the table was named `equipment`, `backup_service.dart` accepts `equipment` as valid because `MigrationManager.migrate()` automatically upgrades `equipment` to `inventory` upon reopening.
2. **`sales_invoices` vs `sales_invoice_items` / `payments`**: The schema stores invoice item details and paid amounts directly within the `sales_invoices` table (`TableNames.salesInvoices`). There is no separate `sales_invoice_items` or `payments` table.
3. **`TableNames` Constants**: `_coreTables` now directly uses the `TableNames` constants from `database_constants.dart` instead of raw strings.

---

## 4. flutter analyze - before vs after

Before (fixes/phase-1): No issues found
After  (fixes/phase-2-backup): No issues found

---

## 5. Manual setup steps needed (Google Cloud + OAuth)

Nothing in the app crashes without this. Drive buttons show an informative snackbar.

### Step 1 - Google Cloud Project
1. Go to https://console.cloud.google.com
2. Create project "Gomaa Management"
3. Enable Google Drive API
4. OAuth consent screen: scopes = https://www.googleapis.com/auth/drive.file

### Step 2 - OAuth Client IDs

Android:
  Package name: check android/app/build.gradle (applicationId)
  SHA-1 debug: keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
  Download google-services.json -> android/app/

iOS:
  Bundle ID from ios/Runner/Info.plist CFBundleIdentifier
  Download GoogleService-Info.plist -> ios/Runner/

Windows (Desktop):
  Type: Desktop app
  Copy client_id from downloaded JSON into lib/config/google_config.dart

### Step 3 - Add packages to pubspec.yaml
  google_sign_in: ^6.2.1
  googleapis: ^13.2.0
Run flutter pub get.

### Step 4 - Create lib/config/google_config.dart
Copy lib/config/google_config.example.dart -> lib/config/google_config.dart
Fill in your real client IDs. This file is in .gitignore - NEVER commit it.

---

## 6. Manual test steps

Backup:
1. Settings -> النسخ الاحتياطي tab
2. "نسخ احتياطي - اختر المجلد" -> OS picker -> pick USB/folder -> success dialog shows path+size
3. "نسخ احتياطي - المجلد الافتراضي" -> saved to <AppSupport>/backups/ -> success dialog
4. Open .db in DB Browser for SQLite -> all tables and data present
5. Repeat 11x to default folder -> only 10 most-recent remain

1-Day reminder:
6. Set last_backup_at to 2 days ago in settings table
7. Restart -> orange reminder banner visible

Restore (good file):
8. Backup. Add a customer. Try to restore the earlier backup.
9. "استعادة من ملف .db" -> confirm -> pick file -> snackbar "تمت الاستعادة بنجاح"
10. New customer gone (correct). All screens refreshed.

Restore (corrupted file):
11. Create a text file with .db extension
12. Try to restore it -> error dialog "الملف المحدد تالف"
13. Current DB untouched

Airplane mode:
14. Enable airplane mode
15. Manual backup works fully
16. Restore from that file works fully

Without Google Sign-In:
17. Never configure Drive -> backup and restore work as usual
18. Drive tab shows "غير متصل" and informative messages

---

## 7. Decisions and risks

VACUUM INTO chosen over file copy:
  Atomic consistent snapshot, does not close the live connection.
  SQLite docs recommend it for online backups.

Validation on separate read-only connection (sqflite_ffi):
  Prevents any risk of corrupting the live DB during validation.

Safety copy before replace:
  If the file copy step fails, the original DB is still intact.

WAL/SHM deleted before replace:
  Prevents restored DB from being replayed with old journal entries.

Drive upload is a UI stub:
  google_sign_in and googleapis are NOT added yet.
  Adding them without google-services.json causes Android build failure.
  Complete the Google Cloud setup first, then add the packages.

on_close auto-backup on Windows:
  window_manager does not expose a reliable willClose hook.
  Recommended as a follow-up after Drive upload is wired.

Drive Wi-Fi-only on Windows:
  Would need connectivity_plus (not in pubspec). Skipped to avoid new packages.
  Toggle is only visible on Android/iOS where platform APIs exist.

google_config.dart excluded from git:
  Prevents accidentally committing OAuth client IDs.
