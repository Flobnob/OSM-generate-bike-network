DELETE FROM polygons WHERE landuse IS NULL AND "natural" IS NULL;

ALTER TABLE lines_noded ADD COLUMN landuse_line TEXT, ADD COLUMN natural_line TEXT, ADD column highway_filled TEXT;

WITH lines_polygon_intersections AS (
    SELECT 
        lines.id AS line_id,
        polygons.landuse,
        polygons."natural",
        ST_Length(ST_Intersection(lines.geom, polygons.geom)) AS intersection_length
    FROM lines_noded AS lines
    JOIN polygons 
    ON ST_Intersects(ST_Buffer(lines.geom, 15), polygons.geom)
), ranked_intersections AS (
    SELECT 
        line_id,
        landuse,
        "natural",
        intersection_length,
        ROW_NUMBER() OVER (PARTITION BY line_id ORDER BY intersection_length DESC) AS rank
    FROM lines_polygon_intersections
)
-- Den Linien werden die meistüberschneidenden Polygonwerte zugewiesen. Dacnach wird geprüft, ob bereits ein Wert vorlag. Wenn ja, wird dieser gewählt
UPDATE lines_noded
SET 
    landuse_line = ranked_intersections.landuse,
    natural_line = ranked_intersections."natural"
FROM ranked_intersections
WHERE lines_noded.id = ranked_intersections.line_id AND ranked_intersections.rank = 1;


WITH target_line AS (
  -- Alle Linien ohne maxspeed_filled (also mindestens alle separat kartierten Wege)
  SELECT id, geom
    FROM lines_noded
   WHERE maxspeed_filled IS NULL
),
buffered_line AS (
  -- 15 m Puffer
  SELECT id,
         geom,
         ST_Buffer(geom, 15) AS buffer_geom
    FROM target_line
),
lines_intersections AS (
  -- sortieren nach größter Überschneidung mit linien die maxspeed-wert haben
  SELECT b.id                AS line_id,
         c.maxspeed_filled   AS candidate_speed,
         ST_Length(
           ST_Intersection(b.buffer_geom, c.geom)
         )                   AS intersection_length
    FROM buffered_line b
    JOIN lines_noded   c
      ON ST_Intersects(b.buffer_geom, c.geom)
     AND c.maxspeed_filled IS NOT NULL
     AND b.id             <> c.id
),
ranked_intersections AS (

  SELECT line_id,
         candidate_speed,
         ROW_NUMBER() OVER (
           PARTITION BY line_id
           ORDER BY intersection_length DESC
         ) AS rn
    FROM lines_intersections
)
-- größte Überschneidung Info wird übertragen
UPDATE lines_noded t
   SET maxspeed_filled = r.candidate_speed
  FROM ranked_intersections r
 WHERE t.id = r.line_id
   AND r.rn = 1;

-- nochmal das gleiche für highway
WITH target_line AS (
  SELECT id, geom
    FROM lines_noded
   WHERE highway_filled IS NULL
),
buffered_line AS (
  SELECT id,
         geom,
         ST_Buffer(geom, 15) AS buffer_geom
    FROM target_line
),
lines_intersections AS (
  SELECT b.id               AS line_id,
         c.highway         AS candidate_highway,
         ST_Length(
           ST_Intersection(b.buffer_geom, c.geom)
         )                  AS intersection_length
    FROM buffered_line b
    JOIN lines_noded   c
      ON ST_Intersects(b.buffer_geom, c.geom)
     AND c.highway      IS NOT NULL
     AND b.id           <> c.id
),
ranked_intersections AS (
  SELECT line_id,
         candidate_highway,
         ROW_NUMBER() OVER (
           PARTITION BY line_id
           ORDER BY intersection_length DESC
         ) AS rn
    FROM lines_intersections
)
UPDATE lines_noded t
   SET highway_filled = r.candidate_highway
  FROM ranked_intersections r
 WHERE t.id = r.line_id
   AND r.rn = 1;

