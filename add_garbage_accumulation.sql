-- Add Garbage Accumulation as new civic category
-- Linked to Sanitation department (same as Garbage Collection)

INSERT INTO civic_categories (type_name, description, department_id) 
VALUES ('Garbage Accumulation', 'Report accumulation of garbage at specific locations', 3);

-- Verify insertion
SELECT id, type_name, description, department_id FROM civic_categories WHERE type_name LIKE 'Garbage%';
