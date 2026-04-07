INSERT INTO citizens (id, full_name, email, phone_number, password) VALUES
(1, 'John Doe', 'citizen@example.com', '9876543210', '$2b$10$YourHashedPasswordHere');

INSERT INTO department (department_name, budget) VALUES
('Water Supply', 5000000),
('Roads & Infrastructure', 8000000),
('Sanitation', 3000000),
('Parks & Recreation', 2000000),
('Public Safety', 6000000);

INSERT INTO civic_categories (type_name, description, department_id) VALUES
('Water Leakage', 'Pipe leaks and water supply issues', 1),
('Pothole', 'Road damage and potholes', 2),
('Garbage Collection', 'Waste management issues', 3),
('Park Maintenance', 'Park cleanliness and maintenance', 4),
('Street Lighting', 'Broken street lights', 5);

INSERT INTO location (city, area_name, locality, zip_code, state) VALUES
('Bangalore', 'Electronic City', '2nd Phase', '560100', 'Karnataka'),
('Bangalore', 'Whitefield', 'Marathahalli', '560037', 'Karnataka'),
('Bangalore', 'Koramangala', 'Central', '560034', 'Karnataka');

SELECT 'Sample data inserted successfully!' as status;
