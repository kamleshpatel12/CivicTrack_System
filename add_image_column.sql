-- Add image_url column to issues table if it doesn't exist
ALTER TABLE issues ADD COLUMN image_url VARCHAR(500) NULL DEFAULT NULL AFTER address;

SELECT 'Image URL column added to issues table!' as status;
