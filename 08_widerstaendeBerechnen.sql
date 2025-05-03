DO $$ 
DECLARE 
    attr RECORD;
    attributes_mappings JSONB := '{
        "fuehrungsform_links": "fuehrungsform_mapping",
        "fuehrungsform_rechts": "fuehrungsform_mapping",
        "surface_links": "surface_mapping",
        "surface_rechts": "surface_mapping",
        "smoothness_links": "smoothness_mapping",
        "smoothness_rechts": "smoothness_mapping",
        "landuse_line": "landuse_line_mapping",
        "natural_line": "natural_line_mapping",
        "maxspeed_filled": "maxspeed_filled_mapping",
        "cycleway_width_links": "cycleway_width_mapping",
        "cycleway_width_rechts": "cycleway_width_mapping",
        "parking_orientation_links":"parking_orientation_mapping",
        "parking_orientation_rechts":"parking_orientation_mapping",
        "parking_position_links":"parking_position_mapping",
        "parking_position_rechts":"parking_position_mapping",
        "gleise":"gleise_mapping",
        "lit":"lit_mapping",
        "highway":"highway_mapping",
        "highway_filled": "highway_filled_mapping",
        "verkehrsregelung": "verkehrsregelung_mapping"
		}';
    table_name TEXT;
    attributes TEXT[];
    base_attribute TEXT;

BEGIN
    SELECT array_agg(key) INTO attributes 
    FROM jsonb_each(attributes_mappings);
    
    FOR attr IN SELECT unnest(attributes) AS attribute LOOP
        base_attribute := regexp_replace(attr.attribute, '(_links|_rechts)$', '');
        
        SELECT attributes_mappings ->> attr.attribute INTO table_name;
        
        EXECUTE format(
            'ALTER TABLE public.lines_noded ADD COLUMN  %1$I_factor NUMERIC;', attr.attribute);
        
        EXECUTE format(
            'UPDATE public.lines_noded l
             SET %1$I_factor = rm.factor
             FROM resistance_mappings.%2$I rm
             WHERE l.%1$I = rm.%3$I;',
            attr.attribute, table_name, base_attribute
        );
    END LOOP;
END $$;

/* DIE WIRKUNG DES MAXSPEED factorS HÄNGT MAßGEBLICH VON DER BAUWEISE AB UND SOLLTE BEI MISCHVERKEHR UND FAHR- BZW. SCHUTZSTREIFEN STÄRKER ZU BUCHE SCHLAGEN
-- DIE MAXSPEED WERTE WERDEN IN EINEM SCHON BESTEHENDEN VERKEHRSMODELL BESSER OHNEHIN NICHT AUS OSM ABGELEITET, SONDERN AUS DEM BESTEHENDEN NETZ
Wenn Mischverkehr dann Maxspeed factor * Verkehrsbelastung; Wenn Radweg dann (Maxspeed-factor*Verkehrsbelastung)*0.2, wenn Schutzstrfeifen dann *0.9, wenn fahrstreifen dann *0.8
*/
ALTER TABLE lines_noded ADD COLUMN verkehrsbelastung_links_factor NUMERIC, ADD COLUMN verkehrsbelastung_rechts_factor NUMERIC;

UPDATE lines_noded
SET verkehrsbelastung_links_factor = CASE
    WHEN fuehrungsform_links IN ('Mischverkehr', 'Fahrradfahrstreifen', 'Fahrradschutzstreifen', 'Geteilte Busspur', 'Erschliessungsweg', 'Freier Weg') 
        THEN COALESCE(highway_filled_factor, highway_factor) * maxspeed_filled_factor
    ELSE GREATEST(1.0, highway_factor * maxspeed_filled_factor * 0.25)
    END; -- der Faktor soll mindestens 1.0 sein, aber im Falle von getrennter Infrastruktur gesenkt werden

UPDATE lines_noded
SET verkehrsbelastung_rechts_factor = CASE
    WHEN fuehrungsform_rechts IN ('Mischverkehr', 'Fahrradfahrstreifen', 'Fahrradschutzstreifen', 'Geteilte Busspur', 'Erschliessungsweg') 
        THEN COALESCE(highway_filled_factor, highway_factor) * maxspeed_filled_factor
    ELSE GREATEST(1.0, highway_factor * maxspeed_filled_factor  * 0.5)
    END; -- der Faktor soll mindestens 1.0 sein


-- Für den Umgebungsfactor wird geprüft ob Landuse UND Natural vorliegen; falls ja wird der Mittelwert zwischen den factoren gewählt und in die neue Spalte eingefügt.
ALTER TABLE lines_noded ADD COLUMN umgebung_factor NUMERIC;
UPDATE lines_noded
SET umgebung_factor = CASE
    WHEN landuse_line != 'other_areas' AND natural_line != 'other_areas' THEN (landuse_line_factor + natural_line_factor) / 2
    WHEN landuse_line != 'other_areas' AND natural_line = 'other_areas' THEN landuse_line_factor
    WHEN landuse_line = 'other_areas' AND natural_line != 'other_areas' THEN natural_line_factor
    ELSE 1.0
    END
;

ALTER TABLE lines_noded ADD COLUMN brunnel_factor NUMERIC;
UPDATE lines_noded
SET brunnel_factor = 1.2
WHERE bridge IS NOT NULL OR tunnel IS NOT NULL;

;

-- Für den width-Faktor wird geprüft, ob es sich um Zweirichtungsinfrastruktur handelt; falls ja, wird der Faktor verdoppelt
UPDATE lines_noded
SET cycleway_width_links_factor = CASE
    WHEN oneway_bicycle = 0 THEN cycleway_width_links_factor * 2
    ELSE cycleway_width_links_factor
    END;
UPDATE lines_noded
SET cycleway_width_rechts_factor = CASE
    WHEN oneway_bicycle = 0 THEN cycleway_width_rechts_factor * 2
    ELSE cycleway_width_rechts_factor
    END;

-- Um dedizierte Radreisewege und andere in OSM als Route verbundene Linien zu bevorzugen, wird die betroffene Spalte einfach umgewandelt
-- Falls das Segment teil einer Route ist, wird ein Bonus verrechnet
ALTER TABLE lines_noded
ADD COLUMN route_factor NUMERIC;
UPDATE lines_noded
SET route_factor = CASE 
    WHEN rel_refs IS NULL THEN 1 
    ELSE 0.9 
END;

-- Gegen die Richtung einer Einbahnstraße zu fahren erhöht den Empfundenen Widerstand (Reinfeld)
ALTER TABLE lines_noded
ADD COLUMN oneway_factor NUMERIC;
UPDATE lines_noded
SET oneway_factor = CASE
    WHEN oneway = '1' AND oneway_bicycle = '0' AND old_id IS NULL THEN 1.1
    WHEN oneway = '-1' ANd oneway_bicycle = '0' AND old_id IS NOT NULL THEN 1.1
    ELSE 1.0
END;

ALTER TABLE lines_noded
ADD COLUMN "parking_factor_links" NUMERIC;
ALTER TABLE lines_noded
ADD COLUMN "parking_factor_rechts" NUMERIC;
UPDATE lines_noded
SET parking_factor_links = ((COALESCE(parking_orientation_links_factor, 1) + COALESCE(parking_position_links_factor, 1))/2);
UPDATE lines_noded
SET parking_factor_rechts = ((COALESCE(parking_orientation_rechts_factor, 1) + COALESCE(parking_position_rechts_factor, 1))/2);

-- Neue Spalten hinzufügen, falls noch nicht vorhanden
ALTER TABLE lines_noded
--ADD COLUMN "ew_basis_log_links" NUMERIC,
--ADD COLUMN "ew_basis_log_rechts" NUMERIC,
ADD COLUMN "ew_vorsichtigen_l" NUMERIC,
ADD COLUMN "ew_vorsichtigen_r" NUMERIC,
ADD COLUMN "ew_pragmatischen_l" NUMERIC,
ADD COLUMN "ew_pragmatischen_r" NUMERIC,
ADD COLUMN "ew_effizienten_l" NUMERIC,
ADD COLUMN "ew_effizienten_r" NUMERIC,
--ADD COLUMN "fb_basis_log_links" NUMERIC,
--ADD COLUMN "fb_basis_log_rechts" NUMERIC,
ADD COLUMN "fb_vorsichtigen_l" NUMERIC,
ADD COLUMN "fb_vorsichtigen_r" NUMERIC,
ADD COLUMN "fb_pragmatischen_l" NUMERIC,
ADD COLUMN "fb_pragmatischen_r" NUMERIC,
ADD COLUMN "fb_effizienten_l" NUMERIC,
ADD COLUMN "fb_effizienten_r" NUMERIC,
ADD COLUMN "fb_ungewichtet_l" NUMERIC,
ADD COLUMN "fb_ungewichtet_r" NUMERIC
;


UPDATE lines_noded
SET
    "fb_vorsichtigen_l" = 
        COALESCE(smoothness_links_factor, 1)			* 1 	+ 
        COALESCE(surface_links_factor, 1)				* 1 	+ 
        COALESCE(fuehrungsform_links_factor, 1)		    * 4 	+ 
        COALESCE(verkehrsbelastung_links_factor, 1)	    * 3 	+ 
        COALESCE(umgebung_factor, 1) 					* 3     +
        COALESCE(cycleway_width_links_factor, 1)        * 3     +
        parking_factor_links                            * 2     +
        COALESCE(gleise_factor, 1)                      * 1     +
        COALESCE(lit_factor, 1)                         * 0.5   +
        oneway_factor                                   * 1     +
        route_factor                                    * 1     +
        COALESCE(verkehrsregelung_factor, 1)            * 1     +
        COALESCE(brunnel_factor, 1)                     * 1
		,

    "fb_vorsichtigen_r" = 
        COALESCE(smoothness_rechts_factor, 1) 			* 1		+ 
        COALESCE(surface_rechts_factor, 1) 			    * 1		+ 
        COALESCE(fuehrungsform_rechts_factor, 1) 		* 4 	+ 
        COALESCE(verkehrsbelastung_rechts_factor, 1) 	* 3 	+ 
        COALESCE(umgebung_factor, 1)					* 3     +
        COALESCE(cycleway_width_rechts_factor, 1)       * 3     +
        parking_factor_rechts                           * 2     +
        COALESCE(gleise_factor, 1)                      * 1     +
        COALESCE(lit_factor, 1)                         * 0.5   +
        oneway_factor                                   * 1     +
        route_factor                                    * 1     +
        COALESCE(verkehrsregelung_factor, 1)            * 1     +
        COALESCE(brunnel_factor, 1)                     * 1
		,

    "fb_pragmatischen_l" = 
        COALESCE(smoothness_links_factor, 1)			* 2 	+ 
        COALESCE(surface_links_factor, 1)				* 2 	+ 
        COALESCE(fuehrungsform_links_factor, 1)		    * 2 	+ 
        COALESCE(verkehrsbelastung_links_factor, 1)	    * 2 	+ 
        COALESCE(umgebung_factor, 1)					* 1     +
        COALESCE(cycleway_width_links_factor, 1)        * 2     +
        parking_factor_links                            * 1.5   +
        COALESCE(gleise_factor, 1)                      * 1     +
        COALESCE(lit_factor, 1)                         * 0.5   +
        oneway_factor                                   * 0.75  +
        route_factor                                    * 0.75  +
        COALESCE(verkehrsregelung_factor, 1)            * 1.5   +
        COALESCE(brunnel_factor, 1)                     * 1
		,

    "fb_pragmatischen_r" = 
        COALESCE(smoothness_rechts_factor, 1) 			* 2 	+ 
        COALESCE(surface_rechts_factor, 1) 			    * 2 	+ 
        COALESCE(fuehrungsform_rechts_factor, 1) 		* 2		+ 
        COALESCE(verkehrsbelastung_rechts_factor, 1) 	* 2		+ 
        COALESCE(umgebung_factor, 1)					* 1     +
        COALESCE(cycleway_width_rechts_factor, 1)       * 2     +
        parking_factor_rechts                           * 1.5   +
        COALESCE(gleise_factor, 1)                      * 1     +
        COALESCE(lit_factor, 1)                         * 0.5   +
        oneway_factor                                   * 0.75  +
        route_factor                                    * 0.75  +
        COALESCE(verkehrsregelung_factor, 1)            * 1.5   +
        COALESCE(brunnel_factor, 1)                     * 1
		,
    
    "fb_effizienten_l" = 
        COALESCE(smoothness_links_factor, 1) 			* 4 	+ 
        COALESCE(surface_links_factor, 1)				* 4 	+ 
        COALESCE(fuehrungsform_links_factor, 1)		    * 0.5 	+ 
        COALESCE(verkehrsbelastung_links_factor, 1)	    * 0.5 	+ 
        COALESCE(umgebung_factor, 1)					* 0.5   +
        COALESCE(cycleway_width_links_factor, 1)        * 3     +
        parking_factor_links                            * 0.5   +
        COALESCE(gleise_factor, 1)                      * 1     +
        COALESCE(lit_factor, 1)                         * 0.5   +
        oneway_factor                                   * 0.5   +
        route_factor                                    * 0.5   +
        COALESCE(verkehrsregelung_factor, 1)            * 2     +
        COALESCE(brunnel_factor, 1)                     * 1
		,

    "fb_effizienten_r" = 
        COALESCE(smoothness_rechts_factor, 1)			* 4	    + 
        COALESCE(surface_rechts_factor, 1)				* 4 	+ 
        COALESCE(fuehrungsform_rechts_factor, 1)		* 0.5	+ 
        COALESCE(verkehrsbelastung_rechts_factor, 1)	* 0.5 	+ 
        COALESCE(umgebung_factor, 1)					* 0.5   +
        COALESCE(cycleway_width_rechts_factor, 1)       * 3     +
        parking_factor_rechts                           * 0.5   +
        COALESCE(gleise_factor, 1)                      * 1     +
        COALESCE(lit_factor, 1)                         * 0.5   +
        oneway_factor                                   * 0.5   +
        route_factor                                    * 0.5   +
        COALESCE(verkehrsregelung_factor, 1)            * 2     +
        COALESCE(brunnel_factor, 1)                     * 1
        ,

    "fb_ungewichtet_l" = 
        COALESCE(smoothness_links_factor, 1) 				+ 
        COALESCE(surface_links_factor, 1)					+ 
        COALESCE(fuehrungsform_links_factor, 1)		  	+ 
        COALESCE(verkehrsbelastung_links_factor, 1)	   + 
        COALESCE(umgebung_factor, 1)					  +
        COALESCE(cycleway_width_links_factor, 1)          +
        parking_factor_links                              +
        COALESCE(gleise_factor, 1)                      +
        COALESCE(lit_factor, 1)                          +
        oneway_factor                                      +
        route_factor                                     +
        COALESCE(verkehrsregelung_factor, 1)              +
        COALESCE(brunnel_factor, 1)                   
		,

    "fb_ungewichtet_r" = 
        COALESCE(smoothness_rechts_factor, 1)			  + 
        COALESCE(surface_rechts_factor, 1)					+ 
        COALESCE(fuehrungsform_rechts_factor, 1)		+ 
        COALESCE(verkehrsbelastung_rechts_factor, 1)	+ 
        COALESCE(umgebung_factor, 1)					 +
        COALESCE(cycleway_width_rechts_factor, 1)       +
        parking_factor_rechts                             +
        COALESCE(gleise_factor, 1)                       +
        COALESCE(lit_factor, 1)                        +
        oneway_factor                                    +
        route_factor                                       +
        COALESCE(verkehrsregelung_factor, 1)               +
        COALESCE(brunnel_factor, 1)                     
;
       
   

UPDATE lines_noded
SET 
    -- Berechnung für die verschiedenen Seiten für die Gruppe "Interessiert, aber besorgt"
    "ew_vorsichtigen_l" = CASE
        WHEN fuehrungsform_links IN ('Kein Zugang', 'Unbekannt')  or (oneway_bicycle = 1 and path != 'crossing') THEN -1       -- Fahren nur in eine Richtung erlaubt
        WHEN oneway_bicycle = -1 or oneway_bicycle = 0 or cycleway_left_oneway = '-1' THEN fb_vorsichtigen_l * (ST_Length(geom) * 0.75)  -- Fahren in Gegenrichtung (links) erlaubt
        ELSE -1
    END,
    "ew_vorsichtigen_r" = CASE
        WHEN fuehrungsform_rechts IN ('Kein Zugang', 'Unbekannt')  or (oneway_bicycle = -1 and path != 'crossing') THEN -1
        WHEN oneway_bicycle = 1 or oneway_bicycle = 0  or cycleway_right_oneway = '1' THEN fb_vorsichtigen_r * (ST_Length(geom) * 0.75) 
        ELSE -1
    END,
    "ew_pragmatischen_l" = CASE
        WHEN fuehrungsform_links IN ('Kein Zugang', 'Unbekannt')  or (oneway_bicycle = 1 and path != 'crossing') THEN -1
        WHEN oneway_bicycle = -1 or oneway_bicycle = 0  or cycleway_left_oneway = '-1' THEN fb_pragmatischen_l * (ST_Length(geom)*1.0)
        ELSE -1
    END,
    "ew_pragmatischen_r" = CASE
        WHEN fuehrungsform_rechts IN ('Kein Zugang', 'Unbekannt')  or (oneway_bicycle = -1 and path != 'crossing') THEN -1
        WHEN oneway_bicycle = 1 or oneway_bicycle = 0  or cycleway_right_oneway = '1' THEN fb_pragmatischen_r * (ST_Length(geom) * 1.0)
        ELSE -1
    END,
    "ew_effizienten_l" = CASE
        WHEN fuehrungsform_links IN ('Kein Zugang', 'Unbekannt')  or (oneway_bicycle = 1 and path != 'crossing') THEN -1
        WHEN oneway_bicycle = -1 or oneway_bicycle = 0  or cycleway_left_oneway = '-1' THEN fb_effizienten_l * (ST_Length(geom) * 1.25) 
        ELSE -1
    END,
    "ew_effizienten_r" = CASE
        WHEN fuehrungsform_rechts IN ('Kein Zugang', 'Unbekannt') or (oneway_bicycle = -1 and path != 'crossing') THEN -1
        WHEN oneway_bicycle = 1 or oneway_bicycle = 0  or cycleway_right_oneway = '1' THEN fb_effizienten_r * (ST_Length(geom) * 1.25) 
        ELSE -1
    END
    ;

-- Addieren eines vom Durchschnitt der Gruppe/Seite abhängenden Werts, sodass häufiges Wechseln von Segmenten bestraft wird

WITH avg_values AS (
    SELECT
        AVG(NULLIF("ew_vorsichtigen_l", -1)) AS avg_vl,
        AVG(NULLIF("ew_vorsichtigen_r", -1)) AS avg_vr,
        AVG(NULLIF("ew_pragmatischen_l", -1)) AS avg_pl,
        AVG(NULLIF("ew_pragmatischen_r", -1)) AS avg_pr,
        AVG(NULLIF("ew_effizienten_l", -1)) AS avg_el,
        AVG(NULLIF("ew_effizienten_r", -1)) AS avg_er
    FROM lines_noded
)
UPDATE lines_noded
SET
    "ew_vorsichtigen_l" = CASE 
        WHEN "ew_vorsichtigen_l" != -1 THEN "ew_vorsichtigen_l" + (avg_vl / 10)
        ELSE "ew_vorsichtigen_l"
    END,
    "ew_vorsichtigen_r" = CASE 
        WHEN "ew_vorsichtigen_r" != -1 THEN "ew_vorsichtigen_r" + (avg_vr / 10)
        ELSE "ew_vorsichtigen_r"
    END,
    "ew_pragmatischen_l" = CASE 
        WHEN "ew_pragmatischen_l" != -1 THEN "ew_pragmatischen_l" + (avg_pl / 10)
        ELSE "ew_pragmatischen_l"
    END,
    "ew_pragmatischen_r" = CASE 
        WHEN "ew_pragmatischen_r" != -1 THEN "ew_pragmatischen_r" + (avg_pr / 10)
        ELSE "ew_pragmatischen_r"
    END,
    "ew_effizienten_l" = CASE 
        WHEN "ew_effizienten_l" != -1 THEN "ew_effizienten_l" + (avg_el / 10)
        ELSE "ew_effizienten_l"
    END,
    "ew_effizienten_r" = CASE 
        WHEN "ew_effizienten_r" != -1 THEN "ew_effizienten_r" + (avg_er / 10)
        ELSE "ew_effizienten_r"
    END
FROM avg_values;
