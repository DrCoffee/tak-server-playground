-- TAK Server Database Initialization Script

-- Create PostGIS extension if not exists
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create additional extensions that TAK Server might use
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS hstore;

-- Grant necessary permissions to TAK user
GRANT ALL PRIVILEGES ON DATABASE cot TO tak;
GRANT ALL ON SCHEMA public TO tak;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tak;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tak;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO tak;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO tak;

-- Create basic indexes for performance (TAK Server will create additional tables)
-- These are common spatial indexes that PostGIS applications use

-- Ensure proper PostGIS functions are available
SELECT PostGIS_Version();

-- Log successful initialization
INSERT INTO pg_stat_statements_info VALUES ('TAK Server database initialized successfully') 
ON CONFLICT DO NOTHING;