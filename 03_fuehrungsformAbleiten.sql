--- Führungsformen für Links und Rechts bestimmen
--- LINKS

UPDATE lines
SET 
    fuehrungsform_links = CASE
        -- Verkehrszeichen
        WHEN starts_with(traffic_sign_links, 'DE:237') THEN CASE
            WHEN cycleway_left = 'lane' THEN 'Fahrradfahrstreifen'
            ELSE 'Radweg'
            END
        WHEN starts_with(traffic_sign_links, 'DE:240') THEN 'Gemeinsamer Geh- und Radweg'
        WHEN starts_with(traffic_sign_links, 'DE:241') THEN 'Getrennter Rad- und Gehweg'
        WHEN starts_with(traffic_sign_links, 'DE:239,1022-10') OR starts_with(traffic_sign_links, 'DE:239, 1022-10') THEN 'Gehweg, Radverkehr frei'
        WHEN starts_with(traffic_sign_links, 'DE:1022-10') OR starts_with(traffic_sign_links, 'DE:1000-33') THEN 'Gehweg, Radverkehr frei'
        WHEN starts_with(traffic_sign_links, 'DE:244.1') OR starts_with(traffic_sign_links, 'DE:244.3') THEN 'Fahrradstrasse'
        WHEN starts_with(traffic_sign_links, 'DE:331.1') OR starts_with(traffic_sign_links, 'DE:330.1') 
            OR (traffic_sign_links = 'DE:239' AND bicycle NOT IN ('yes', 'designated')) THEN 'Kein Zugang'

       -- Fahrradverbote (Including cycleway_left_bicycle)
        WHEN bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination') 
          OR cycleway_left_bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination')
          OR access IN ('no', 'use_sidepath', 'customers', 'private', 'destination')
          OR bicycle_backward IN ('no', 'use_sidepath') 
        THEN 'Kein Zugang'
        WHEN bicycle = 'dismount' THEN 'Fahrradfahrer absteigen'
        WHEN highway IN ('motorroad', 'motorroad_link', 'trunk', 'trunk_link') THEN 'Kein Zugang'

        -- Fussgängerinfrastruktur
        WHEN footway = 'crossing' OR "path" = 'crossing' THEN 'Uebergang'
        WHEN highway IN ('footway', 'pedestrian') AND bicycle = 'yes' THEN 'Gehweg, Radverkehr frei'

        -- Radinfrastruktur (Links)
        WHEN bicycle_road = 'yes' THEN 'Fahrradstrasse'
        WHEN cycleway_left IN ('track') THEN 'Radweg'
        WHEN cycleway_left IN ('lane') THEN
            CASE
                WHEN cycleway_left_bicycle = 'designated' OR bicycle_backward = 'designated' OR cycleway_left_lane = 'exclusive' THEN 'Fahrradfahrstreifen'
                ELSE 'Fahrradschutzstreifen'
            END
        WHEN cycleway_left = 'shared_busway' THEN 'Geteilte Busspur'
        WHEN highway = 'cycleway' THEN CASE
            WHEN segregated = 'no' THEN 'Gemeinsamer Geh- und Radweg'
            WHEN segregated = 'yes' THEN 'Getrennter Rad- und Gehweg'
            WHEN bicycle = 'designated' AND foot = 'designated' THEN 'Gemeinsamer Geh- und Radweg'
            ELSE 'Radweg'
            END

        -- Allgemeine Wege
        WHEN highway IN ('bridleway', 'track', 'path') THEN 
            CASE 
                WHEN segregated = 'no' THEN 'Gemeinsamer Geh- und Radweg'
                WHEN segregated = 'yes' THEN 'Getrennter Rad- und Gehweg'
                WHEN surface_links IN ('asphalt', 'concrete', 'concrete:lanes', 'concrete:plates', 'cobblestone', 'paving_stones', 'paved') 
                    OR tracktype IN ('grade1', 'grade2') THEN 'Freier Weg'
                WHEN tracktype IN ('grade3', 'grade4') THEN 'Erschliessungsweg'
                WHEN tracktype = 'grade5' THEN 'Kein Zugang'
                ELSE 'Erschliessungsweg'
            END

        -- Mischverkehr
        WHEN highway = 'living_street' THEN 'Verkehrsberuhigter Bereich'
        WHEN highway IN ('primary', 'secondary', 'tertiary', 'residential', 'unclassified', 'primary_link', 'secondary_link', 'tertiary_link')
            AND ((cycleway IS NULL OR cycleway in ('no', 'opposite'))
            AND (cycleway_left IS NULL OR cycleway_left IN ('no', 'opposite'))
            OR cycleway_left = 'shared_lane')
                THEN 'Mischverkehr'
        
        -- Reste abfangen
        WHEN highway = 'cycleway' THEN 'Radweg'
        WHEN bicycle = 'designated' THEN 'Radweg'

        -- Sonstiges
        WHEN highway = 'steps' THEN 'Treppenstufen'

        -- Standard
        ELSE 'Unbekannt'
    END,

    -- RECHTS
    fuehrungsform_rechts = CASE
        -- Verkehrszeichen (richtungsbezogen)
        WHEN starts_with(traffic_sign_rechts, 'DE:237') THEN CASE
            WHEN cycleway_right = 'lane' THEN 'Fahrradfahrstreifen'
            ELSE 'Radweg'
            END
        WHEN starts_with(traffic_sign_rechts, 'DE:240') THEN 'Gemeinsamer Geh- und Radweg'
        WHEN starts_with(traffic_sign_rechts, 'DE:241') THEN 'Getrennter Rad- und Gehweg'
        WHEN starts_with(traffic_sign_rechts, 'DE:239,1022-10') OR starts_with(traffic_sign_rechts, 'DE:239, 1022-10') THEN 'Gehweg, Radverkehr frei'
        WHEN starts_with(traffic_sign_rechts, 'DE:1022-10') OR starts_with(traffic_sign_rechts, 'DE:1000-33') THEN 'Gehweg, Radverkehr frei'
        WHEN starts_with(traffic_sign_rechts, 'DE:244.1') OR starts_with(traffic_sign_rechts, 'DE:244.3') THEN 'Fahrradstrasse'
        WHEN starts_with(traffic_sign_rechts, 'DE:331.1') OR starts_with(traffic_sign_rechts, 'DE:330.1') 
            OR (traffic_sign_rechts = 'DE:239' AND bicycle NOT IN ('yes', 'designated')) THEN 'Kein Zugang'

        -- Fahrradverbote (Including cycleway_right_bicycle)
        WHEN bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination') 
          OR cycleway_right_bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination')
          OR access IN ('no', 'use_sidepath', 'customers', 'private', 'destination')
          OR bicycle_forward IN ('no', 'use_sidepath') 
        THEN 'Kein Zugang'
        WHEN bicycle = 'dismount' THEN 'Fahrradfahrer absteigen'
        WHEN highway IN ('motorroad', 'motorroad_link', 'trunk', 'trunk_link') THEN 'Kein Zugang'

        -- Fussgängerinfrastruktur
        WHEN footway = 'crossing' OR "path" = 'crossing' THEN 'Uebergang'
        WHEN highway IN ('footway', 'pedestrian') AND bicycle = 'yes' THEN 'Gehweg, Radverkehr frei'

        -- Radinfrastruktur (Rechts)
        WHEN bicycle_road = 'yes' THEN 'Fahrradstrasse'
        WHEN cycleway_right IN ('track') THEN 'Radweg'
        WHEN cycleway_right IN ('lane') THEN
            CASE
                WHEN cycleway_right_bicycle = 'designated' OR bicycle_forward = 'designated' OR cycleway_right_lane = 'exclusive' THEN 'Fahrradfahrstreifen'
                ELSE 'Fahrradschutzstreifen'
            END
        WHEN cycleway_right IN ('shared_busway') THEN 'Geteilte Busspur'
        WHEN highway = 'cycleway' THEN CASE
            WHEN segregated = 'no' THEN 'Gemeinsamer Geh- und Radweg'
            WHEN segregated = 'yes' THEN 'Getrennter Rad- und Gehweg'
            WHEN bicycle = 'designated' AND foot = 'designated' THEN 'Gemeinsamer Geh- und Radweg'
            ELSE 'Radweg'
            END
       
        -- Allgemeine Wege
        WHEN highway IN ('bridleway', 'track', 'path') THEN 
            CASE 
                WHEN segregated = 'no' THEN 'Gemeinsamer Geh- und Radweg'
                WHEN segregated = 'yes' THEN 'Getrennter Rad- und Gehweg'
                -- Spät aufgefallener Fehler: Hier müsste außerdem nach bicycle=designated geprüft werden.
                -- Dabei werden 150 km Geh- und Radweg (also bicycle=designated und foot=designated) festgestellt und ca. 35 km Radweg. Nun werden sie zum Großteil den Freien Wegen zugeschrieben
                WHEN surface_rechts IN ('asphalt', 'concrete', 'concrete:lanes', 'concrete:plates', 'cobblestone', 'paving_stones', 'paved') 
                    OR tracktype IN ('grade1', 'grade2') THEN 'Freier Weg'
                WHEN tracktype IN ('grade3', 'grade4') THEN 'Erschliessungsweg'
                WHEN tracktype = 'grade5' THEN 'Kein Zugang'
                ELSE 'Erschliessungsweg'
            END

        -- Mischverkehr
        WHEN highway = 'living_street' THEN 'Verkehrsberuhigter Bereich'
        WHEN highway IN ('primary', 'secondary', 'tertiary', 'residential', 'unclassified', 'primary_link', 'secondary_link', 'tertiary_link')
            AND ((cycleway IS NULL OR cycleway in ('no', 'opposite'))
            AND (cycleway_right IS NULL OR cycleway_right IN ('no', 'opposite'))
            OR cycleway_right = 'shared_lane')
                THEN 'Mischverkehr'

        -- Reste abfangen
        WHEN highway = 'cycleway' THEN 'Radweg'
        WHEN bicycle = 'designated' THEN 'Radweg'

        -- Sonstiges
        WHEN highway = 'steps' THEN 'Treppenstufen'

        -- Standard
        ELSE 'Unbekannt'
    END; 

ALTER TABLE lines ADD COLUMN zuweisungsattribut_links text, ADD COLUMN zuweisungsattribut_rechts text;

UPDATE lines
SET 
    zuweisungsattribut_links = CASE
        -- Verkehrszeichen
        WHEN starts_with(traffic_sign_links, 'DE:237') THEN CASE
            WHEN cycleway_left = 'lane' THEN 'Verkehrszeichen + Lane'
            ELSE 'Verkerhszeichen ohne lane'
            END
        WHEN 
         starts_with(traffic_sign_links, 'DE:240') or
         starts_with(traffic_sign_links, 'DE:241') or
         starts_with(traffic_sign_links, 'DE:239,1022-10') OR starts_with(traffic_sign_links, 'DE:239, 1022-10')  or
         starts_with(traffic_sign_links, 'DE:1022-10') OR starts_with(traffic_sign_links, 'DE:1000-33')  or
         starts_with(traffic_sign_links, 'DE:244.1') OR starts_with(traffic_sign_links, 'DE:244.3')  or
         starts_with(traffic_sign_links, 'DE:331.1') OR starts_with(traffic_sign_links, 'DE:330.1')
            OR (traffic_sign_links = 'DE:239' AND bicycle NOT IN ('yes', 'designated')) THEN 'Verkehrszeichen'

       -- Fahrradverbote (Including cycleway_left_bicycle)
        WHEN bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination', 'dismount')
          OR cycleway_left_bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination')
          OR bicycle_backward IN ('no', 'use_sidepath')  then 'Zugangsbeschränkung (bicycle)'
        WHEN access IN ('no', 'use_sidepath', 'customers', 'private', 'destination') then 'Zugangsbeschränkung (access)'


        WHEN highway IN ('motorroad', 'motorroad_link', 'trunk', 'trunk_link') THEN 'Highway (motorroad, trunk, link)'

        -- Fussgängerinfrastruktur
        WHEN footway = 'crossing' OR "path" = 'crossing' THEN 'Footway/Path (crossing)'
        WHEN highway IN ('footway', 'pedestrian') AND bicycle = 'yes' THEN 'Highway + biycle'

        -- Radinfrastruktur (Links)
        WHEN bicycle_road = 'yes' THEN 'bicycle_road'
        WHEN cycleway_left IN ('track') THEN 'cycleway=track'
        WHEN cycleway_left IN ('lane') THEN
            CASE
                WHEN cycleway_left_bicycle = 'designated' OR bicycle_backward = 'designated' or cycleway_left_lane = 'exclusive' THEN 'cycleway=lane + designated'
                ELSE 'cycleway=lane + nichts'
            END
        WHEN highway = 'cycleway' THEN CASE
            WHEN segregated = 'no' THEN 'highway(cycleway)+segregated(no)'
            WHEN segregated = 'yes' THEN 'highway(cycleway)+segregated(yes)'
            WHEN bicycle = 'designated' AND foot = 'designated' THEN 'Zugangsbeschränkungen(foot+bicycle=designated)'
            ELSE 'highway=cycleway'
            END
        -- Allgemeine Wege
        WHEN highway IN ('bridleway', 'track', 'path') THEN 
            CASE 
                WHEN segregated = 'no' THEN 'highway+segregated'
                WHEN segregated = 'yes' THEN 'highway+segregated'
                WHEN surface_rechts IN ('asphalt', 'concrete', 'concrete:lanes', 'concrete:plates', 'cobblestone', 'paving_stones', 'paved') 
                    OR tracktype IN ('grade1', 'grade2') THEN 'highway+surface/tracktype'
                WHEN tracktype IN ('grade3', 'grade4') THEN 'highway+surface/tracktype'
                WHEN tracktype = 'grade5' THEN 'tracktype'
                ELSE 'highway+surface/tracktype'
            END
        -- Mischverkehr
        WHEN highway = 'living_street' THEN 'highway (living_street)'
        WHEN highway IN ('primary', 'secondary', 'tertiary', 'residential', 'unclassified', 'primary_link', 'secondary_link', 'tertiary_link')
            AND ((cycleway IS NULL OR cycleway in ('no', 'opposite')) AND (cycleway_left IS NULL OR cycleway_left IN ('no', 'opposite')) 
            OR cycleway_left = 'shared_lane') THEN 'highway + fehlender cycleway'
        
        -- Reste abfangen
        WHEN highway = 'cycleway' THEN 'reste highway=cycleway'
        WHEN bicycle = 'designated' THEN 'reste bicycle=designated'

        -- Sonstiges
        WHEN highway = 'steps' THEN 'Treppenstufen'

        -- Standard
        ELSE 'Unbekannt'
    END,

    -- RECHTS
    zuweisungsattribut_rechts = CASE
        -- Verkehrszeichen
        WHEN starts_with(traffic_sign_rechts, 'DE:237') THEN CASE
            WHEN cycleway_right = 'lane' THEN 'Verkehrszeichen + Lane'
            ELSE 'Verkerhszeichen ohne lane'
            END
        WHEN 
         starts_with(traffic_sign_links, 'DE:240') or
       starts_with(traffic_sign_rechts, 'DE:241') or
        starts_with(traffic_sign_rechts, 'DE:239,1022-10') OR starts_with(traffic_sign_rechts, 'DE:239, 1022-10')  or
         starts_with(traffic_sign_rechts, 'DE:1022-10') OR starts_with(traffic_sign_rechts, 'DE:1000-33')  or
         starts_with(traffic_sign_rechts, 'DE:244.1') OR starts_with(traffic_sign_rechts, 'DE:244.3')  or
         starts_with(traffic_sign_rechts, 'DE:331.1') OR starts_with(traffic_sign_rechts, 'DE:330.1')
            OR (traffic_sign_rechts = 'DE:239' AND bicycle NOT IN ('yes', 'designated')) THEN 'Verkehrszeichen'

       -- Fahrradverbote (Including cycleway_right_bicycle)
        WHEN bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination', 'dismount')
          OR cycleway_right_bicycle IN ('no', 'use_sidepath', 'customers', 'private', 'destination')
          OR bicycle_backward IN ('no', 'use_sidepath')  then 'Zugangsbeschränkung (bicycle)'
        WHEN access IN ('no', 'use_sidepath', 'customers', 'private', 'destination') then 'Zugangsbeschränkung (access)'


        WHEN highway IN ('motorroad', 'motorroad_link', 'trunk', 'trunk_link') THEN 'Highway (motorroad, trunk, link)'

        -- Fussgängerinfrastruktur
        WHEN footway = 'crossing' OR "path" = 'crossing' THEN 'Footway/Path (crossing)'
        WHEN highway IN ('footway', 'pedestrian') AND bicycle = 'yes' THEN 'Highway + biycle'

        -- Radinfrastruktur (rechts)
        WHEN bicycle_road = 'yes' THEN 'bicycle_road'
        WHEN cycleway_right IN ('track') THEN 'cycleway=track'
        WHEN cycleway_right IN ('lane') THEN
            CASE
                WHEN cycleway_right_bicycle = 'designated' OR bicycle_forward = 'designated' or cycleway_right_lane = 'exclusive' THEN 'cycleway=lane + designated'
                ELSE 'cycleway=lane + nichts'
            END
        WHEN highway = 'cycleway' THEN CASE
            WHEN segregated = 'no' THEN 'highway(cycleway)+segregated(no)'
            WHEN segregated = 'yes' THEN 'highway(cycleway)+segregated(yes)'
            WHEN bicycle = 'designated' AND foot = 'designated' THEN 'Zugangsbeschränkungen(foot+bicycle=designated)'
            ELSE 'highway=cycleway'
        END
        -- Allgemeine Wege
        WHEN highway IN ('bridleway', 'track', 'path') THEN 
            CASE 
                WHEN segregated = 'no' THEN 'highway+segregated'
                WHEN segregated = 'yes' THEN 'highway+segregated'
                WHEN surface_rechts IN ('asphalt', 'concrete', 'concrete:lanes', 'concrete:plates', 'cobblestone', 'paving_stones', 'paved') 
                    OR tracktype IN ('grade1', 'grade2') THEN 'highway+surface/tracktype'
                WHEN tracktype IN ('grade3', 'grade4') THEN 'highway+surface/tracktype'
                WHEN tracktype = 'grade5' THEN 'tracktype'
                ELSE 'highway+surface/tracktype'
            END

        -- Mischverkehr
        WHEN highway = 'living_street' THEN 'highway (living_street)'
        WHEN highway IN ('primary', 'secondary', 'tertiary', 'residential', 'unclassified', 'primary_link', 'secondary_link', 'tertiary_link')
            AND ((cycleway IS NULL OR cycleway in ('no', 'opposite'))
            AND (cycleway_right IS NULL OR cycleway_right IN ('no', 'opposite'))
            OR cycleway_right = 'shared_lane') 
                THEN 'highway + fehlender cycleway'
        
        -- Reste abfangen
        WHEN highway = 'cycleway' THEN 'reste highway=cycleway'
        WHEN bicycle = 'designated' THEN 'reste bicycle=designated'

        -- Sonstiges
        WHEN highway = 'steps' THEN 'Treppenstufen'

        -- Standard
        ELSE 'Unbekannt'
    END; 


CREATE TABLE lines_deleted AS 
SELECT * 
FROM lines
WHERE (fuehrungsform_links IS NULL OR fuehrungsform_links IN ('Kein Zugang', 'Unbekannt'))
    AND (fuehrungsform_rechts IS NULL OR fuehrungsform_rechts IN ('Kein Zugang', 'Unbekannt'))
    AND ((access IN ('no', 'customers', 'private', 'destination')
        OR highway IN ('service'))
    );


DELETE FROM lines
WHERE (fuehrungsform_links IS NULL OR fuehrungsform_links IN ('Kein Zugang', 'Unbekannt'))
    AND (fuehrungsform_rechts IS NULL OR fuehrungsform_rechts IN ('Kein Zugang', 'Unbekannt'))
    AND ((access IN ('no', 'customers', 'private', 'destination')
        OR highway IN ('service'))
    );

-- An Knoten schreiben, wie viele Linien sie haben
ALTER TABLE lines_noded_vertices_pgr ADD COLUMN degree INTEGER;
UPDATE lines_noded_vertices_pgr v
SET degree = (
  SELECT count(*) 
  FROM lines_noded 
  WHERE source = v.id OR target = v.id
);