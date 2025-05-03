ALTER TABLE lines ADD COLUMN source INTEGER;
ALTER TABLE lines ADD COLUMN target INTEGER;

-- SELECT pgr_createTopology('lines', 0.001, 'geom', 'way_id', 'source', 'target');
-- SELECT  pgr_analyzeGraph('lines',0.001,'geom','way_id','source','target');
-- Zuerst werden die Brücken und Tunnel gesondert bearbeitet, damit sie später nicht miteinander verbunden werden
UPDATE lines
SET bridge = CASE WHEN bridge = 'no' THEN NULL ELSE bridge END,
    tunnel = CASE WHEN tunnel = 'no' THEN NULL ELSE tunnel END;

SELECT pgr_nodeNetwork('lines', 0.001, 'way_id', 'geom', 'noBrunnel', 'bridge IS NULL and tunnel IS NULL');
SELECT pgr_nodeNetwork('lines', 0.001, 'way_id', 'geom', 'onlyBrunnel', 'bridge IS NOT NULL or tunnel IS NOT NULL');

UPDATE public."lines_onlyBrunnel"
SET id = id + 1000000;

-- Daten werden kombiniert
CREATE TABLE lines_noded AS
SELECT * FROM public."lines_noBrunnel"
UNION ALL
SELECT * FROM public."lines_onlyBrunnel";

SELECT pgr_createTopology('lines_noded', 0.001, 'geom', 'id', 'source', 'target');
-- SELECT pgr_analyzeGraph('lines_noded',0.001,'geom','id','source','target');

-- Die folgende Schleife ist dafür da, jegliche Spalten von lines auf lines_noded zu übertragen. Dafür müssen die Spalten aber ersteinmal erstellt werden.
-- um zu wissen, welche Spalten überhaupt vorliegen, wird das information_schema abgefragt.
DO $$
DECLARE
    rec record;
    alter_statements text := '';
    update_statements text := '';
BEGIN
    FOR rec IN 
        SELECT a.attname AS column_name,
               pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type
        FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        WHERE c.relname = 'lines'
          AND a.attnum > 0
          AND NOT a.attisdropped
          AND a.attname NOT IN (
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = 'lines_noded'
          )
    LOOP
        alter_statements := alter_statements || format('ADD COLUMN %I %s, ', rec.column_name, rec.data_type);
        update_statements := update_statements || format('%I = (SELECT %I FROM lines WHERE lines_noded.old_id = lines.way_id), ', rec.column_name, rec.column_name);
    END LOOP;

    IF alter_statements <> '' THEN
        EXECUTE 'ALTER TABLE lines_noded ' || left(alter_statements, -2) || ';';
    END IF;

    IF update_statements <> '' THEN
        EXECUTE 'UPDATE lines_noded SET ' || left(update_statements, -2) || ';';
    END IF;
END $$;


