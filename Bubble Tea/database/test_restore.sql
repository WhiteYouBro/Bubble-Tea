-- Test SQL file for restore testing
-- This is a simple backup that can be used to test the restore functionality

-- Create a test table
CREATE TABLE IF NOT EXISTS test_restore (
    id SERIAL PRIMARY KEY,
    test_message VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO test_restore (test_message) VALUES 
('Restore test successful!'),
('Database is working correctly');

-- Show results
SELECT 'Test restore completed successfully!' AS status;
SELECT * FROM test_restore;

