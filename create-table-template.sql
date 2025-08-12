CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('customer', 'admin') DEFAULT 'customer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE Table product(
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    prod_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);


CREATE TABLE OrderItems (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    payment_date DATETIME,
    payment_method ENUM('credit_card', 'paypal', 'bank_transfer'),
    amount DECIMAL(10,2),
    status ENUM('completed', 'pending', 'failed'),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);


ALTER TABLE orders ADD total_amount INT;


CREATE Trigger tri_update_totalamount 
AFTER INSERT ON orderitems
FOR EACH ROW
Begin
     UPDATE orders
     SET total_amount = (SELECT sum(price*quantity) FROM orderitems WHERE order_id = new.order_id) WHERE order_id = new.order_id;
END 

CREATE Trigger tri_update_stock
AFTER INSERT ON orderitems
FOR EACH ROW
begin
    UPDATE product
    SET stock = stock - new.quantity
    WHERE product_id = NEW.product_id;
END

CREATE TABLE deleted_audit_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT,
    performed_by INT,
    details TEXT,
    deleted_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE Trigger tri_audit_deleted_orders
BEFORE DELETE ON orders
FOR EACH ROW
begin
    INSERT INTO deleted_audit_logs (table_name,record_id,performed_by,details   )
    VALUES(
        'orders',
        OLD.order_id,
        OLD.user_id,
        CONCAT('deleted order with total_amount = ',OLD.total_amount,',status=',OLD.status)
    );
END


CREATE Trigger tri_audit_deleted_orderitems
BEFORE DELETE ON orderitems
FOR EACH ROW
begin
    INSERT INTO deleted_audit_logs (table_name,record_id,details   )
    VALUES(
        'orderitem',
        OLD.order_item_id,
        CONCAT('deleted product item  = ',OLD.product_id,',quantity =',OLD.quantity)
    );
END



CREATE Trigger tri_audit_deleted_product
BEFORE DELETE ON product
FOR EACH ROW
begin
    INSERT INTO deleted_audit_logs (table_name,record_id,details   )
    VALUES(
        'product',
        OLD.product_id,
        CONCAT('deleted product = ',OLD.prod_name,',stock =',OLD.stock)
    );
END


CREATE VIEW topsellingproduct AS
SELECT
p.product_id,
p.prod_name,
o.status,
sum(oi.quantity) AS pord_sold,
sum(oi.quantity * oi.price) AS total_sold_amount
FROM product p
JOIN orderitems oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('shipped','delivered')
GROUP BY p.product_id,o.status
ORDER BY total_sold_amount DESC;


CREATE VIEW inventoryreport AS 
SELECT
product_id,
prod_name,
stock 
FROM product 
WHERE stock < 10
ORDER BY stock;

CREATE VIEW MonthlySalesPerformance AS
SELECT 
DATE_FORMAT(o.order_date, '%Y-%m') AS month,
COUNT(DISTINCT o.order_id) AS total_orders,
SUM(oi.quantity * oi.price) AS total_sales,
SUM(oi.quantity) AS total_items_sold
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
WHERE o.status IN ('shipped', 'delivered')
GROUP BY month;

SET GLOBAL event_scheduler = ON;

CREATE EVENT old_audit_log
ON SCHEDULE EVERY 1 MONTH
STARTS '2025-08-01 00:00:00'
DO
DELETE FROM audit_log
WHERE log_time < NOW() - INTERVAL 30 DAY;


CREATE VIEW CancelledOrderAnalysis AS
SELECT 
DATE(o.order_date) AS cancel_date,
COUNT(o.order_id) AS cancelled_orders,
SUM(oi.quantity * oi.price) AS lost_revenue
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
WHERE o.status = 'cancelled'
GROUP BY cancel_date;


CREATE INDEX idx_users_email ON Users(email);

CREATE INDEX idx_product_stock ON Product(stock);


CREATE INDEX idx_orders_order_date ON Orders(order_date);

CREATE INDEX idx_orders_status ON Orders(status);

CREATE INDEX idx_orders_user_id ON Orders(user_id);

CREATE INDEX idx_orderitems_order_id ON OrderItems(order_id);

CREATE INDEX idx_orderitems_product_id ON OrderItems(product_id);

CREATE INDEX idx_payments_order_id ON Payments(order_id);

CREATE INDEX idx_audit_table_record ON deleted_audit_logs(table_name, record_id);

