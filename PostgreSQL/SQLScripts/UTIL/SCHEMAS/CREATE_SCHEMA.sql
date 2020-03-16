-- 3D City Database - The Open Source CityGML Database
-- http://www.3dcitydb.org/
<<<<<<< HEAD
--
-- Copyright 2013 - 2019
=======
-- 
-- Copyright 2013 - 2020
>>>>>>> master
-- Chair of Geoinformatics
-- Technical University of Munich, Germany
-- https://www.gis.bgu.tum.de/
--
-- The 3D City Database is jointly developed with the following
-- cooperation partners:
--
-- virtualcitySYSTEMS GmbH, Berlin <http://www.virtualcitysystems.de/>
-- M.O.S.S. Computer Grafik Systeme GmbH, Taufkirchen <http://www.moss.de/>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

\pset footer off
SET client_min_messages TO WARNING;
\set ON_ERROR_STOP ON

\set SCHEMA_NAME :schema_name
\set TMP_DELETE_FILE :tmp_delete_file
\set TMP_ENVELOPE_FILE :tmp_envelope_file
\set TMP_SCHEMA_RASTER_FILE :tmp_schema_raster_file

\echo 'Creating 3DCityDB schema "':SCHEMA_NAME'" ...'

--// create schema
CREATE SCHEMA :"SCHEMA_NAME";

--// set search_path for this session
SELECT current_setting('search_path') AS current_path;
\gset
SET search_path TO :"SCHEMA_NAME", :current_path;

--// check if the PostGIS extension and the citydb_pkg package are available
--// check if version is below 3 or if postgis_raster extension is available
SELECT EXISTS(SELECT 1 AS create_raster FROM pg_available_extensions WHERE name = 'postgis_raster') OR postgis_lib_version() < '3' AS create_raster \gset
SELECT version as citydb_version from citydb_pkg.citydb_version();

--// create TABLES, SEQUENCES, CONSTRAINTS, INDEXES
\echo
\echo 'Setting up database schema ...'
\i ../../SCHEMA/SCHEMA.sql

--// fill tables OBJECTCLASS
\i ../../SCHEMA/OBJECTCLASS/OBJECTCLASS_INSTANCES.sql
\i ../../SCHEMA/OBJECTCLASS/AGGREGATION_INFO_INSTANCES.sql

--// create and fill INDEX_TABLE
\i ../../SCHEMA/INDEX_TABLE/INDEX_TABLE.sql

--// create schema FUNCTIONS
\i ../../SCHEMA/OBJECTCLASS/OBJCLASS.sql
\i :TMP_ENVELOPE_FILE
\i :TMP_DELETE_FILE

--// create additional schema for raster data only if raster type is installed
SELECT CASE WHEN :create_raster
  THEN :TMP_SCHEMA_RASTER_FILE
  ELSE '../RASTER/DO_NOTHING.sql'
  END AS do_action;
\gset

\i :do_action

\echo
\echo 'Created 3DCityDB schema "':SCHEMA_NAME'".'

\echo 'Setting spatial reference system for schema "':SCHEMA_NAME'" (will be the same as for schema "citydb") ...'
\set SCHEMA_NAME_QUOTED '\'':SCHEMA_NAME'\''
INSERT INTO :SCHEMA_NAME.DATABASE_SRS SELECT srid, gml_srs_name FROM citydb.database_srs LIMIT 1;
SELECT citydb_pkg.change_schema_srid(database_srs.srid, database_srs.gml_srs_name, 0, :SCHEMA_NAME_QUOTED) FROM citydb.database_srs LIMIT 1;
\echo 'Done'
