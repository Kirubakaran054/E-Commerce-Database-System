# 🛒 E-Commerce Database Schema

This project contains the **SQL schema**, triggers, views, indexes, and scheduled events for a simple **E-Commerce Management System**.  
It supports **product listings, orders, payments, stock tracking, sales reporting, and audit logging**.

---

## 📂 Database Structure

### 1️⃣ Tables

#### **Users**
Stores customer and admin details.  
**Fields:** `user_id`, `name`, `email`, `password_hash`, `role`, `created_at`.

#### **Product**
Stores product catalog details.  
**Fields:** `product_id`, `prod_name`, `description`, `price`, `stock`, `created_at`.

#### **Orders**
Stores order records linked to users.  
**Fields:** `order_id`, `user_id`, `order_date`, `status`, `total_amount`.

#### **OrderItems**
Stores products and quantities for each order.  
**Fields:** `order_item_id`, `order_id`, `product_id`, `quantity`, `price`.

#### **Payments**
Stores payment details for orders.  
**Fields:** `payment_id`, `order_id`, `payment_date`, `payment_method`, `amount`, `status`.

#### **Deleted Audit Logs**
Keeps a record of deleted entries for accountability.  
**Fields:** `log_id`, `table_name`, `record_id`, `performed_by`, `details`, `deleted_time`.

---

## ⚡ Triggers

- **`tri_update_totalamount`** – Updates order total automatically when items are inserted.  
- **`tri_update_stock`** – Reduces product stock when items are sold.  
- **Audit Triggers** (`tri_audit_deleted_orders`, `tri_audit_deleted_orderitems`, `tri_audit_deleted_product`) – Log deleted records into the `deleted_audit_logs` table.

---

## 📊 Views

- **`topsellingproduct`** – Shows best-selling products by revenue & quantity.  
- **`inventoryreport`** – Lists products with stock less than 10.  
- **`MonthlySalesPerformance`** – Tracks monthly sales, order counts, and items sold.  
- **`CancelledOrderAnalysis`** – Analyzes cancellations and potential revenue loss.

---

## ⏰ Events

- **`old_audit_log`** – Deletes audit logs older than 30 days automatically (runs monthly).  
  *(Requires `SET GLOBAL event_scheduler = ON`)*

---

## 📌 Indexes

Indexes added for performance optimization:

- **Users:** `email`
- **Product:** `stock`
- **Orders:** `order_date`, `status`, `user_id`
- **OrderItems:** `order_id`, `product_id`
- **Payments:** `order_id`
- **Deleted Audit Logs:** `(table_name, record_id)`

---

## 🛠 Installation

1. **Create a new MySQL database**:
   ```sql
   CREATE DATABASE ecommerce;
   USE ecommerce;


   
📈 Features
✅ Automatic order total calculation.
✅ Stock auto-adjustment on sales.
✅ Audit logs for deleted records.
✅ Pre-built sales & inventory reports.
✅ Automatic cleanup of old logs.
✅ Optimized queries with indexes.
