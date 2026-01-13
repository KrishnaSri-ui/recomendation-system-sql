CREATE DATABASE sql_recommendation_system;
USE sql_recommendation_system;


CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50)
);


CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(30)
);


CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


CREATE TABLE ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    product_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
 
 

 INSERT INTO users (name) VALUES
('Alice'),('Bob'),('Charlie'),('David'),('Emma'),
('Frank'),('Grace'),('Helen'),('Ian'),('Jack'),
('Kathy'),('Leo'),('Mona'),('Nina'),('Oscar');


INSERT INTO products (product_name, category) VALUES
('Laptop','Electronics'),
('Mobile','Electronics'),
('Headphones','Electronics'),
('Smartwatch','Electronics'),
('Shoes','Fashion'),
('Jeans','Fashion'),
('T-Shirt','Fashion'),
('Backpack','Accessories'),
('Wallet','Accessories'),
('Sunglasses','Accessories'),
('Tablet','Electronics'),
('Power Bank','Electronics');


INSERT INTO orders (user_id, order_date) VALUES
(1,'2025-01-01'),(1,'2025-01-10'),
(2,'2025-01-02'),
(3,'2025-01-03'),(3,'2025-01-15'),
(4,'2025-01-04'),
(5,'2025-01-05'),
(6,'2025-01-06'),
(7,'2025-01-07'),
(8,'2025-01-08'),
(9,'2025-01-09'),
(10,'2025-01-10'),
(11,'2025-01-11'),
(12,'2025-01-12'),
(13,'2025-01-13'),
(14,'2025-01-14'),
(15,'2025-01-15');


INSERT INTO order_items (order_id, product_id, quantity) VALUES
-- Alice
(1,1,1),(1,3,1),(2,5,1),

-- Bob
(3,1,1),(3,5,1),

-- Charlie
(4,3,1),(4,8,1),(5,11,1),

-- David
(6,1,1),(6,5,1),(6,6,1),

-- Emma
(7,3,1),(7,4,1),

-- Frank
(8,1,1),(8,12,1),

-- Grace
(9,3,1),(9,5,1),

-- Helen
(10,2,1),(10,8,1),

-- Ian
(11,1,1),(11,4,1),

-- Jack
(12,5,1),(12,6,1),

-- Kathy
(13,3,1),(13,10,1),

-- Leo
(14,2,1),(14,11,1),

-- Mona
(15,1,1),(15,5,1),

-- Nina
(16,3,1),(16,9,1),

-- Oscar
(17,5,1),(17,8,1);


INSERT INTO ratings (user_id, product_id, rating) VALUES
(1,1,5),(1,3,4),
(2,1,5),(2,5,4),
(3,3,5),(3,8,4),
(4,1,4),(4,6,5),
(5,3,4),(5,4,5),
(6,1,4),(6,12,4),
(7,3,5),(7,5,4);

select * from users;
select * from orders;
select * from order_items;
select * from products;
select * from ratings;



SELECT 
    p.category,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category, p.product_id, p.product_name
ORDER BY p.category, total_quantity_sold DESC;


SELECT 
    category,
    product_name,
    avg_rating
FROM (
    SELECT 
        p.category,
        p.product_name,
        AVG(r.rating) AS avg_rating,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY AVG(r.rating) DESC) AS ranking
    FROM ratings r
    JOIN products p ON r.product_id = p.product_id
    GROUP BY p.category, p.product_id, p.product_name
) t
WHERE ranking = 1;


SELECT 
    u.name,
    GROUP_CONCAT(DISTINCT p.product_name ORDER BY p.product_name) AS products_bought
FROM users u
JOIN orders o ON u.user_id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY u.user_id;

SELECT 
    p.product_name,
    COUNT(*) AS times_bought
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id
ORDER BY times_bought DESC;




WITH user_bought AS (
    SELECT 
        u.user_id,
        u.name AS user_name,
        GROUP_CONCAT(DISTINCT p.product_name ORDER BY p.product_name) AS bought_products
    FROM users u
    JOIN orders o ON u.user_id = o.user_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE u.user_id = 1
    GROUP BY u.user_id, u.name
),

recommendations AS (
    SELECT 
        o1.user_id,
        p2.product_name AS recommended_product,
        COUNT(*) AS recommendation_score
    FROM orders o1
    JOIN order_items oi1 ON o1.order_id = oi1.order_id
    JOIN order_items oi2 ON oi1.product_id = oi2.product_id
    JOIN orders o2 ON oi2.order_id = o2.order_id
    JOIN order_items oi3 ON o2.order_id = oi3.order_id
    JOIN products p2 ON oi3.product_id = p2.product_id
    WHERE o1.user_id = 1
      AND o2.user_id <> 1
      AND p2.product_id NOT IN (
          SELECT oi.product_id
          FROM orders o
          JOIN order_items oi ON o.order_id = oi.order_id
          WHERE o.user_id = 1
      )
    GROUP BY o1.user_id, p2.product_id, p2.product_name
)

SELECT 
    ub.user_name,
    ub.bought_products,
    r.recommended_product,
    r.recommendation_score,
    DENSE_RANK() OVER (ORDER BY r.recommendation_score DESC) AS ranking
FROM user_bought ub
JOIN recommendations r ON ub.user_id = r.user_id
ORDER BY ranking;
