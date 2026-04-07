SET FOREIGN_KEY_CHECKS=0;
DELETE FROM head_admin WHERE admin_id = (SELECT id FROM admins WHERE email = 'patel@gmail.com' LIMIT 1);
DELETE FROM admins WHERE email = 'patel@gmail.com';
SET FOREIGN_KEY_CHECKS=1;

INSERT INTO admins (full_name, email, phone_number, password, department_id, employee_id, is_active) 
VALUES ('Kamlesh Patel', 'patel@gmail.com', '9080706050', '$2a$10$Z4vYjKtHMaX0WQP7FzKjiu6MqJZ3qLqY0Zn8K9L0BkHf8vVXt7Q0O', NULL, 'EMP999', 1);

INSERT INTO head_admin (admin_id) 
VALUES ((SELECT id FROM admins WHERE email = 'patel@gmail.com' LIMIT 1));

SELECT 'HEAD ADMIN CREATED SUCCESSFULLY' as Status;
SELECT id, full_name, email, employee_id FROM admins WHERE email = 'patel@gmail.com';
SELECT 'HEAD ADMIN TABLE' as 'Head Admin Record';
SELECT * FROM head_admin WHERE admin_id = (SELECT id FROM admins WHERE email = 'patel@gmail.com' LIMIT 1);
