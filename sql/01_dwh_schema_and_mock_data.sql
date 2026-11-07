-- DDL Schema & Mock Data for Commercial Analytics

DROP TABLE IF EXISTS Order_Lines CASCADE;
DROP TABLE IF EXISTS Products CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;

-- 1. Dimensions
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    registration_date DATE NOT NULL
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_type VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL
);

-- 2. Fact Table
CREATE TABLE Order_Lines (
    line_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    date DATE NOT NULL,
    customer_id INT NOT NULL REFERENCES Customers(customer_id),
    product_id INT NOT NULL REFERENCES Products(product_id),
    order_type VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    discount DECIMAL(10, 2) DEFAULT 0 CHECK (discount >= 0),
    total_cost DECIMAL(10, 2) NOT NULL CHECK (total_cost >= 0),
    order_channel VARCHAR(50) NOT NULL
);

-- 3. Seed Mock Data
INSERT INTO Customers (customer_id, name, region, city, registration_date) VALUES
(123456, 'Roman K.',       'ODESA',   'Odesa',   '2021-11-25'),
(740736, 'Volodymyr M.',   'LVIV',    'Stryi',   '2021-06-11'),
(370368, 'Inna B.',        'KYIV',    'Kyiv',    '2022-05-13'),
(185184, 'Olesia P.',      'KHARKIV', 'Kharkiv', '2020-10-26'),
(98765,  'Oleksii T.',     'KYIV',    'Kyiv',    '2022-01-15'),
(592589, 'Taras H.',       'KYIV',    'Kyiv',    '2022-03-01'),
(296294, 'Olena S.',       'LVIV',    'Lviv',    '2022-08-10');

INSERT INTO Products (product_id, product_type, product_name) VALUES
(1,  'Machine',     'BrewMaster Pro 500'),
(2,  'Machine',     'BrewMaster Compact White'),
(3,  'Machine',     'AeroPress Black Edition'),
(4,  'Machine',     'BrewMaster Limited Edition Matte'),
(5,  'Consumables', 'Espresso Pods Dark Roast 10pk'),
(6,  'Consumables', 'Latte Pods Regular 10pk'),
(7,  'Accessories', 'Thermal Travel Mug 450ml'),
(8,  'Accessories', 'Descaling & Cleaning Kit');

INSERT INTO Order_Lines (date, customer_id, order_id, product_id, order_type, price, discount, total_cost, order_channel) VALUES
-- Roman (Odesa) - Loyal customer
('2022-01-10', 123456, 10001, 1, 'Regular', 1500, 0, 1500, 'Web'),
('2022-02-15', 123456, 10002, 5, 'Regular', 35, 0, 35, 'Web'),
('2022-04-20', 123456, 10003, 5, 'Regular', 35, 0, 35, 'Flagship Store'),
-- Volodymyr (Lviv) - One-time buyer
('2022-06-15', 740736, 10004, 2, 'Promotion', 1300, 100, 1200, 'National Supermarket'),
-- Inna (Kyiv) - High value
('2023-04-10', 370368, 10005, 1, 'Regular', 1500, 0, 1500, 'Flagship Store'),
('2023-05-15', 370368, 10006, 4, 'Regular', 2100, 0, 2100, 'Flagship Store'),
('2023-09-20', 370368, 10007, 7, 'Regular', 45, 0, 45, 'Web'),
-- Olesia (Kharkiv) - Accessories & Consumables
('2022-03-08', 185184, 10008, 5, 'Regular', 30, 0, 60, 'Web'),
('2022-03-08', 185184, 10008, 8, 'Regular', 30, 0, 60, 'Web'),
-- Oleksii (Kyiv) - Multi-item basket
('2023-10-24', 98765,  10009, 1, 'Regular', 1500, 0, 1590, 'Flagship Store'),
('2023-10-24', 98765,  10009, 6, 'Regular', 90, 0, 1590, 'Flagship Store'),
-- Taras (Kyiv) - Lapsed flagship buyer, now buys in retail
('2022-05-01', 592589, 10010, 2, 'Regular', 1300, 0, 1300, 'Flagship Store'),
('2023-08-01', 592589, 10011, 5, 'Regular', 35, 0, 35, 'National Supermarket'),
('2023-09-10', 592589, 10012, 5, 'Regular', 35, 0, 35, 'Convenience Store'),
('2023-10-05', 592589, 10013, 6, 'Regular', 35, 0, 35, 'Convenience Store'),
-- Olena (Lviv) - Recent activity (Testing NULL discount handling)
('2023-01-15', 296294, 10014, 3, 'Regular', 150, NULL, 150, 'Web'),
('2023-05-03', 296294, 10015, 2, 'Replacement', 0, NULL, 0, 'Convenience Store');