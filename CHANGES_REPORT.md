# CHANGES_REPORT.md — fixes/phase-1

## Branch Summary

Branch: `fixes/phase-1`  
Dart analyze: **No issues found** (0 errors, 0 warnings, 0 infos)

---

## Item Status

### 1. Sales invoice ↔ Inventory — DONE

**File:** `lib/repositories/sales_invoice_repository.dart`

| Operation | Behaviour |
|-----------|-----------|
| `create`  | Deducts `invoice.quantity` from the matching inventory row inside one `db.transaction`. |
| `update`  | If same item/model: applies only the diff (`newQty - oldQty`). If item/model changed: restores old row then deducts full new qty. All inside one transaction. |
| `delete`  | Restores `invoice.quantity` to the inventory row inside one transaction. |

Invoice row + inventory row always change atomically.

### 2. Purchases ↔ Inventory — DONE

**Files:** `lib/repositories/purchase_repository.dart`, `lib/cubits/purchase/purchase_cubit.dart`

`PurchaseCubit` accepts an `onInventoryChanged` callback; wired in `main.dart` to `inventoryCubit.loadInventory()`. Called after every add/update/delete. Existing purchase-to-inventory DB logic was preserved unchanged.

### 3. Low-stock warning — DONE

**File:** `lib/screens/sales_invoices/sales_invoice_form_screen.dart`

Before saving, the form queries `InventoryRepository.getByNameAndModel()`. If `availableQty < requestedQty` (accounting for old invoice qty on edit), an `AlertDialog` appears with two choices:
- **الغاء** — returns to form without saving.
- **متابعة وإتمام البيع** — proceeds (negative inventory allowed).

The sale is **never silently blocked**.

### 4a. Customer detail — invoices filtered by customer — DONE (was already correct)

**File:** `lib/screens/customers/customer_detail_screen.dart`

`CustomerDetailScreen` creates its own scoped `SalesInvoiceCubit` via `BlocProvider`, initialised with `loadForCustomer(customer.id!)`. Completely separate from the global one. Every navigation callback calls `loadForCustomer`, never `loadAll()`.

### 4b. Delete customer → refresh SalesInvoiceCubit — DONE (fixed this session)

**File:** `lib/screens/customers/customers_screen.dart`

After `CustomerCubit.deleteCustomer()`, `onDelete` now also calls `context.read<SalesInvoiceCubit>().loadAll()` so the global invoice list is purged of the deleted customer's cascade-deleted invoices.

### 4c. Delete inventory item → refresh MaintenanceCubit — DONE (fixed this session)

**File:** `lib/screens/inventory/inventory_screen.dart`

After `InventoryCubit.deleteItem()`, `onDelete` now also calls `context.read<MaintenanceCubit>().loadMaintenanceData()`.

### 5. InventoryCubit auto-refresh — DONE

Both `SalesInvoiceCubit` and `PurchaseCubit` use an `onInventoryChanged` callback wired in `main.dart`. The sales form also calls `loadInventory()` explicitly after save.

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Negative inventory rows | If an item is sold before being purchased, a row is inserted with `quantity = -soldQty`. Keeps a complete ledger; low-stock warning still fires correctly. |
| `onInventoryChanged` callback | Keeps cubits decoupled — `SalesInvoiceCubit` and `PurchaseCubit` don't import `InventoryCubit`. Wiring is at `main.dart`. |
| Scoped cubit in CustomerDetailScreen | Per-customer invoice list uses its own BlocProvider-scoped cubit, so tabs never reset global state or show cross-customer data. |
| Cross-cubit refresh in screen layer | Delete-customer/delete-inventory side-effects are handled at the screen via `context.read<>()`. Avoids circular cubit dependencies. |

---

## Manual Test Steps

### 1. Sale deducts inventory
1. Inventory tab — note qty of an item (e.g. Widget A = 10).
2. Customer detail → New invoice → Widget A, qty 3. Save.
3. Inventory → Widget A should show qty = 7.

### 2. Sale edit adjusts by diff
1. Edit the invoice: qty 3 → 5. Save.
2. Inventory → Widget A should show qty = 5.

### 3. Sale delete restores inventory
1. Delete the invoice.
2. Inventory → Widget A should show qty = 10.

### 4. Low-stock warning
1. New invoice for Widget A, qty = 15 (> 10 available).
2. Warning dialog must appear showing available (10) vs requested (15).
3. Tap Cancel → form stays open. Tap Proceed → invoice saves, inventory goes to -5.

### 5. Purchase adds to inventory
1. Purchases → add Widget A, qty 20.
2. Inventory → Widget A increases by 20.

### 6. Delete customer refreshes invoice list
1. Delete a customer who has invoices.
2. Global SalesInvoiceCubit reloads; deleted customer's invoices disappear.

### 7. Delete inventory item refreshes maintenance
1. Delete an inventory item.
2. Switch to Maintenance tab → list has reloaded from DB.

