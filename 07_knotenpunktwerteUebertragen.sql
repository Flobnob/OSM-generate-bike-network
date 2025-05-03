-- Hier werden Strecken markiert, welche vermutlich an einer Lichtsignanlage liegen
ALTER TABLE lines_noded_vertices_pgr 
ADD COLUMN verkehrsregelung text DEFAULT 'no';

UPDATE lines_noded_vertices_pgr nodes
SET verkehrsregelung = COALESCE((
    SELECT CASE
             WHEN points.tags->>'highway' = 'traffic_signal' THEN 'ampel'
             WHEN points.tags->>'highway' IN ('give_way', 'stop') THEN 'halten'
           END
    FROM points WHERE (points.tags->>'highway' = 'traffic_signal' or points.tags->>'highway' IN ('give_way', 'stop'))
    AND ST_DWithin(nodes.the_geom, points.geom, 10)
      AND points.tags ? 'highway'
      AND (points.tags->>'highway' = 'traffic_signal'
           OR points.tags->>'highway' IN ('give_way', 'stop'))
    ORDER BY ST_Distance(nodes.the_geom, points.geom)
    LIMIT 1
), 'no');

-- Im Folgenden werden Knoten, welche an Gleisen liegen, markiert. Daraufhin werden Straßen und Wege markiert, welche wiederrum einen Knoten mit Gleisen teilen
ALTER TABLE lines_noded_vertices_pgr ADD COLUMN gleisuebergang TEXT;
ALTER TABLE lines_noded ADD COLUMN gleise TEXT, ADD COLUMN verkehrsregelung TEXT;

UPDATE lines_noded_vertices_pgr v
SET gleisuebergang = CASE
WHEN v.id IN (
    SELECT DISTINCT source FROM lines_noded WHERE railway IS NOT NULL
    UNION
    SELECT DISTINCT target FROM lines_noded WHERE railway IS NOT NULL
) THEN 'yes'
ELSE 'no'
END;

UPDATE lines_noded
SET gleise = CASE
WHEN lines_noded.source IN (
    SELECT id FROM lines_noded_vertices_pgr WHERE gleisuebergang = 'yes'
) OR lines_noded.target IN (
    SELECT id FROM lines_noded_vertices_pgr WHERE gleisuebergang = 'yes'
) THEN 'uebergang'
WHEN embedded_rails != 'no' AND embedded_rails IS NOT NULL THEN 'eingelassen'
ELSE 'No'
END;


-- Verkehrsregelung aus den Knoten übernehmen
UPDATE lines_noded
SET verkehrsregelung = (
    SELECT CASE
        WHEN lines_noded_vertices_pgr.verkehrsregelung != 'no' THEN lines_noded_vertices_pgr.verkehrsregelung
        WHEN lines_noded_vertices_pgr_2.verkehrsregelung != 'no' THEN lines_noded_vertices_pgr_2.verkehrsregelung
        ELSE NULL
    END
    FROM lines_noded_vertices_pgr
    JOIN lines_noded_vertices_pgr AS lines_noded_vertices_pgr_2 ON TRUE
    WHERE lines_noded_vertices_pgr.id = lines_noded.source
      AND lines_noded_vertices_pgr_2.id = lines_noded.target
)
WHERE verkehrsregelung IS NULL;
