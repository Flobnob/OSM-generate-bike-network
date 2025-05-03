/* Das folgende Skript wurde am 09.02.2050 vollständig von ChatGPT verfasst. Der Prompt schloss an eine vorherige Frage bezüglich eines Syntax-Fehlers in SQL-Code an. 

Prompt: There are loads more surface types which i want to get rid of. Here are the types with counts

"asphalt"	48371
NULL	32658
"paving_stones"	14527
"ground"	10078
"grass"	5981
"compacted"	4399
"concrete"	3768
"sand"	3644
"sett"	3486
"dirt"	3384
"unpaved"	3078
"paved"	2908
"cobblestone"	2171
"gravel"	2094
"fine_gravel"	1216
"unhewn_cobblestone"	996
"wood"	728
"concrete:plates"	686
"concrete:lanes"	529
"pebblestone"	330
"earth"	257
"metal"	150
"grass_paver"	134
"cobblestone:flattened"	94
"mud"	64
"concrete_slab"	25
"dirt/sand"	21
"paving_stones:30"	19
"stone"	14
"paving_stones:lanes"	13
"woodchips"	12
"Schotter,Erde,Sand"	9
"grass;ground"	9
"grating"	8
"dirt, grass"	8
"metal_grid"	7
"steel"	6
"rock"	6
"ground;grass"	5
"compacted:lanes"	5
"soil; sand"	4
"cobblestone_flatened"	4
"recycled_plastic"	4
"plastic"	4
"paving_stones;asphalt"	3
"forest soil"	3
"sand;grass"	3
"sand;ground"	3
"dirt,grass"	3
"grass;sand"	3
"barkdust"	3
"concrete-grass-concrete"	3
"cobblestone:lines"	3
"plastics"	3
"go"	2
"artificial_turf"	2
"asphalt:lanes"	2
"bricks"	2
"clay"	2
"cobbelstone_flatened"	2
"cobblestone/paved"	2
"concrete:plates;dirt"	2
"good"	2
"grass_paver,_dirt"	2
"gravel; compacted"	2
"gravel;ground"	2
"gravel;sand"	2
"intermediate"	2
"natural"	2
"plastic_plank"	2
"rubber"	2
"scrub"	2
"wald_boden"	2
"multi"	1
"ground;sand"	1
"paving_stones:40"	1
"gravel;compacted"	1
"gratings"	1
"paving_stones;ground"	1
"paving_stones;sett"	1
"paving_stones;unhewn_cobblestone"	1
"gras_+_platten"	1
"plant"	1
"acrylic"	1
"asphalt,_schotter"	1
"plastic_planks"	1
"glass"	1
"plates"	1
"forest_floor"	1
"earth,_stone"	1
"asphalt;cobblestone:flattened"	1
"rubber_band"	1
"dressed_stone:plates"	1
"sand,_grevel"	1
"dirt;grass"	1
"dirt; grass"	1
"dauerhaft_schlammig,_oft_überflutet"	1
"asphalt,paved,_concrete"	1
"concrete_lanes"	1
"sett:lanes"	1
"sett; asphalt"	1
"soil"	1
"soil; grass"	1
"concrete:tiles"	1
"com"	1
"stepping_stones"	1
"cobblestone;sand"	1
"survey"	1
"tiles"	1
"unbefestigte_oberfläche,_betonplatten"	1
"cobblestone;ground"	1
"cm"	1
"untracked"	1
"packed_dirt"	1
"palstic"	1
"overgrown"	1
"paved;cobblestone"	1


Can you please provide a script to automatically change all of those with under 300 counts into a more prominent category that aligns with it?


Angefügter Prompt:
Super, danke. Nun habe ich allerdings am Ende zwei surface Kategorien; surface_links und surface_rechts. Bitte passe das Skript daran an. Gerne mit einer Schleife

Das Folgende Skript stellt die Antwort dar. Der darauffolgende, nicht auskommentierte Block ist die eigenständig angepasste Variante.
DO $$
DECLARE 
    col TEXT;
BEGIN
    FOR col IN (SELECT unnest(ARRAY['surface_links', 'surface_rechts'])) 
    LOOP
        EXECUTE format('
            UPDATE lines_noded
            SET %1$I = CASE
                WHEN %1$I IS NULL THEN
                    CASE
                        WHEN highway IN (''track'', ''bridleway'') THEN ''unpaved''
                        WHEN highway IS NOT NULL THEN ''paved''
                        ELSE NULL
                    END
                ELSE
                    CASE
                        -- If the value is already one of the canonical normalized values, keep it.
                        WHEN %1$I IN (
                            ''asphalt'', ''ground'', ''grass'', ''compacted'', 
                            ''concrete'', ''sand'', ''sett'', ''dirt'', ''unpaved'', ''paved'', 
                            ''cobblestone'', ''gravel'', ''fine_gravel'', ''unhewn_cobblestone'', 
                            ''wood'', ''concrete:plates'', ''concrete:lanes'', ''pebblestone'' 
                        ) THEN %1$I

                        -- Map various stone-based or cobble variants to ''cobblestone''
                        WHEN %1$I IN (
                            ''cobblestone:flattened'', ''cobblestone_flatened'', ''cobbelstone_flatened'', 
                            ''cobblestone/paved'', ''cobblestone:lines'', ''cobblestone;ground'', 
                            ''cobblestone;sand'', ''stone'', ''rock'', ''dressed_stone:plates'', 
                            ''asphalt;cobblestone:flattened'', ''paved;cobblestone''
                        ) THEN ''cobblestone''

                        -- Map natural/loose materials to ''unpaved''
                        WHEN %1$I IN (
                            ''mud'', ''dirt/sand'', ''dirt, grass'', ''dirt,grass'', ''dirt;grass'', 
                            ''packed_dirt'', ''forest soil'', ''forest_floor'', ''overgrown'', ''soil'', 
                            ''soil; grass'', ''natural'', ''barkdust'', ''scrub'', ''untracked'', 
                            ''multi'', ''good'', ''intermediate'', ''survey'', 
                            ''ground;grass'', ''dirt; grass'', ''wald_boden'', ''grass;ground'', 
                            ''woodchips'', ''earth,_stone'', ''unbefestigte_oberfläche,_betonplatten'', 
                            ''grass_paver,_dirt'', ''go'', ''dauerhaft_schlammig,_oft_überflutet'', 
                            ''cm''
                        ) THEN ''unpaved''

                        -- Map sandy mixtures to ''sand''
                        WHEN %1$I IN (
                            ''sand;grass'', ''sand;ground'', ''sand,_grevel'', ''soil; sand'', 
                            ''grass;sand'', ''ground;sand''
                        ) THEN ''sand''

                        -- Map gravelly mixtures to ''gravel''
                        WHEN %1$I IN (
                            ''gravel; compacted'', ''gravel;ground'', ''gravel;sand'', ''gravel;compacted'', 
                            ''Schotter,Erde,Sand''
                        ) THEN ''gravel''

                        -- Map concrete variants to ''concrete''
                        WHEN %1$I IN (
                            ''concrete_slab'', ''concrete_lanes'', ''concrete:tiles'', 
                            ''concrete-grass-concrete'', ''concrete:plates;dirt'', 
                            ''com'', ''plates''
                        ) THEN ''concrete''

                        -- Map paving stone variants to ''paving_stones''
                        WHEN %1$I IN (
                           ''paving_stones'', ''paving_stones:30'', ''paving_stones:40'', ''paving_stones:lanes'', 
                            ''paving_stones;ground'', ''paving_stones;sett'', 
                            ''paving_stones;unhewn_cobblestone'', ''paving_stones;asphalt'', 
                            ''sett; asphalt'', ''sett:lanes'', ''grass_paver''
                        ) THEN ''paving_stones''

                        -- Map other engineered surfaces to ''paved''
                        WHEN %1$I IN (
                            ''tiles'', ''rubber'', ''rubber_band'', ''bricks'', ''acrylic'', 
                            ''plastic'', ''plastics'', ''plastic_plank'', ''plastic_planks'', 
                            ''recycled_plastic'', ''metal_grid'', ''grating'', ''gratings'', 
                            ''steel'', ''artificial_turf'', ''glass'', ''plant'', 
                            ''metal'', ''asphalt:lanes'', ''asphalt,_schotter'', ''asphalt,paved,_concrete''
                        ) THEN ''paved''

                        ELSE %1$I
                    END
            END;
        ', col);
    END LOOP;
END $$;
*/

DO $$
DECLARE 
    col TEXT;
BEGIN
    FOR col IN (SELECT unnest(ARRAY['surface_links', 'surface_rechts'])) 
    LOOP
        EXECUTE format('
            UPDATE lines_noded
            SET %1$I = CASE
                        -- If the value is already one of the canonical normalized values, keep it.
                        WHEN %1$I IN (
                            ''asphalt'', ''grass'', ''compacted'', 
                            ''concrete'', ''sand'', ''sett'', ''unpaved'', ''paved'', 
                            ''cobblestone'', ''gravel'', ''fine_gravel'', ''unhewn_cobblestone'', 
                            ''wood'', ''concrete:plates'', ''concrete:lanes'', ''pebblestone'' 
                        ) THEN %1$I

                        -- Map various stone-based or cobble variants to ''cobblestone''
                        WHEN %1$I IN (
                            ''cobblestone:flattened'', ''cobblestone_flatened'', ''cobbelstone_flatened'', 
                            ''cobblestone/paved'', ''cobblestone:lines'', ''cobblestone;ground'', 
                            ''cobblestone;sand'', ''stone'', ''rock'', ''dressed_stone:plates'', 
                            ''asphalt;cobblestone:flattened'', ''paved;cobblestone''
                        ) THEN ''cobblestone''

                        -- Map natural/loose materials to ''unpaved''
                        WHEN %1$I IN (
                            ''earth'', ''mud'', ''dirt/sand'', ''dirt, grass'', ''dirt,grass'', ''dirt;grass'', 
                            ''packed_dirt'', ''forest soil'', ''forest_floor'', ''overgrown'', ''soil'', 
                            ''soil; grass'', ''natural'', ''barkdust'', ''scrub'', ''untracked'', 
                            ''multi'', ''good'', ''intermediate'', ''survey'', 
                            ''ground;grass'', ''dirt; grass'', ''wald_boden'', ''grass;ground'', 
                            ''woodchips'', ''earth,_stone'', ''unbefestigte_oberfläche,_betonplatten'', 
                            ''grass_paver,_dirt'', ''go'', ''dauerhaft_schlammig,_oft_überflutet'', 
                            ''cm'', ''dirt'', ''ground''
                        ) THEN ''unpaved''

                        -- Map sandy mixtures to ''sand''
                        WHEN %1$I IN (
                            ''sand;grass'', ''sand;ground'', ''sand,_grevel'', ''soil; sand'', 
                            ''grass;sand'', ''ground;sand''
                        ) THEN ''sand''

                        -- Map gravelly mixtures to ''gravel''
                        WHEN %1$I IN (
                            ''gravel; compacted'', ''gravel;ground'', ''gravel;sand'', ''gravel;compacted'', 
                            ''Schotter,Erde,Sand''
                        ) THEN ''gravel''

                        -- Map concrete variants to ''concrete''
                        WHEN %1$I IN (
                            ''concrete_slab'', ''concrete_lanes'', ''concrete:tiles'', 
                            ''concrete-grass-concrete'', ''concrete:plates;dirt'', 
                            ''com'', ''plates''
                        ) THEN ''concrete''

                        -- Map paving stone variants to ''paving_stones''
                        WHEN %1$I IN (
                            ''paving_stones:30'', ''paving_stones:40'', ''paving_stones:lanes'', 
                            ''paving_stones;ground'', ''paving_stones;sett'', 
                            ''paving_stones;unhewn_cobblestone'', ''paving_stones;asphalt'', 
                            ''sett; asphalt'', ''sett:lanes'', ''grass_paver''
                        ) THEN ''paving_stones''

                        -- Map other engineered surfaces to ''paved''
                        WHEN %1$I IN (
                            ''tiles'', ''rubber'', ''rubber_band'', ''bricks'', ''acrylic'', 
                            ''plastic'', ''plastics'', ''plastic_plank'', ''plastic_planks'', 
                            ''recycled_plastic'', ''metal_grid'', ''grating'', ''gratings'', 
                            ''steel'', ''artificial_turf'', ''glass'', ''plant'', 
                            ''metal'', ''asphalt:lanes'', ''asphalt,_schotter'', ''asphalt,paved,_concrete''
                        ) THEN ''paved''
                        ELSE NULL
            END;', col);
    END LOOP;
END $$;


/* Das nachfolgende Skript wurde von Chat-GPT verfasst. Der Prompt war: I have a postgresql table with polygons derived from OSM-Data in Mecklenburg Vorpommern, Germany.
 I later base spatial analysis on the data, for which i need toe landuse and natural columns. But the data has a lot of categories that are very rarely tagged AND not very
  useful for my analysis. I will send you the list with all the counts for the two columns (They are not mutually exlusive to each other, but also don't depend on each other,
   so group each column only based on it's own values). I want you to write me a script to group underrepresentated categories (under 100 polygons) and group them like this:
    for landuse, please sort them into "green_area" and "urban_area". For the "natural" column, order them into "blue_area" (things like coastline, that have to do with water
     in a broad sense should be here), "open_area" (things like grasslands, meadows) or "tree_area" (forests and such). Here is the table with the count:
     
     Gefolgt von der Liste der Polygone.
     
     In einem zweiten Prompt wurde nachgesteuert: Please, for landuse, differentiate between farming areas, open areas, residential areas, commercial areas, industrial areas,
     forest areas.
     
     Das Ergebnis: */

UPDATE polygons
SET landuse = CASE
    WHEN landuse IN ('residential', 'village_green', 'cemetery', 'churchyard', 'street_green', 'plaza') THEN 'residential_area'
    WHEN landuse IN ('commercial', 'retail', 'car_sale', 'administration', 'public_service', 'civic_admin', 'education', 'religious', 'institutional', 'government') THEN 'commercial_area'
    WHEN landuse IN ('industrial', 'garages', 'military', 'fire_station', 'storage_area', 'depot', 'logging', 'quarry', 'harbour') THEN 'industrial_area'
    WHEN landuse IN ('farmland', 'farmyard', 'orchard', 'plant_nursery', 'greenhouse_horticulture', 'vineyard', 'animal_keeping', 'paddock', 'pasture') THEN 'farming_area'
    WHEN landuse IN ('grass', 'meadow', 'greenfield', 'flowerbed', 'recreation_ground', 'leisure', 'fairground', 'camping', 'spare_time', 'leisure_time', 'public', 'ground_storage') THEN 'open_area'
    WHEN landuse IN ('forest') THEN 'forest_area'
    ELSE NULL
END;

UPDATE polygons
SET "natural" = CASE
    WHEN "natural" IN ('water', 'wetland', 'bay', 'coastline', 'reservoir', 'basin', 'mud', 'shoal', 'reef', 'ditch', 'riverbed', 'spring', 'sandbank') THEN 'blue_area'
    WHEN "natural" IN ('grass', 'meadow', 'grassland', 'heath', 'shrubbery', 'flowerbed', 'dune', 'bare_rock', 'scree', 'sand', 'tundra', 'moor', 'fell', 'scrub', 'shrubbery') THEN 'open_area'
    WHEN "natural" IN ('wood', 'forest', 'tree_row', 'tree_group', 'hedge') THEN 'tree_area'
    ELSE NULL
END;

ALTER TABLE lines_noded
ADD COLUMN maxspeed_int INTEGER,
ADD COLUMN maxspeed_text TEXT,
ADD COLUMN maxspeed_filled TEXT;

UPDATE lines_noded
SET maxspeed = CASE
    WHEN maxspeed IS NOT NULL THEN maxspeed
    WHEN maxspeed IS NULL AND tags->>'maxspeed:type' IS NOT NULL THEN tags->>'maxspeed:type'
    ELSE NULL
    END;

UPDATE lines_noded
SET 
    maxspeed_int = CASE
                       WHEN maxspeed ~ '^\d+$' THEN maxspeed::INTEGER
                       ELSE NULL
                   END,
    maxspeed_text = CASE
                        WHEN maxspeed !~ '^\d+$' THEN maxspeed
                        ELSE NULL
                    END;

UPDATE lines_noded
SET 
    maxspeed_int = CASE
                      WHEN maxspeed_text ILIKE '%rural'  THEN 80
                      WHEN maxspeed_text ILIKE '%urban'  THEN 50
                      WHEN maxspeed_text = 'walk' THEN 5
                      ELSE maxspeed_int
                  END;


UPDATE lines_noded
SET 
    maxspeed_filled = CASE
                        WHEN maxspeed_int < 15 THEN '<15'
                        WHEN maxspeed_int >= 15 AND maxspeed_int < 30 THEN '<30'
                        WHEN maxspeed_int >= 30 AND maxspeed_int < 40 THEN '<40'
                        WHEN maxspeed_int >= 40 AND maxspeed_int < 50 THEN '<50'
                        WHEN maxspeed_int >= 50 AND maxspeed_int < 80 THEN '<80'
                        WHEN maxspeed_int >= 80 THEN '>=80'
                        ELSE NULL
                    END;


UPDATE lines_noded
SET cycleway_right_width = REGEXP_REPLACE(REPLACE(cycleway_right_width, ',', '.'), '[A-Za-z]', '', 'g');
UPDATE lines_noded
SET cycleway_left_width = REGEXP_REPLACE(REPLACE(cycleway_left_width, ',', '.'), '[A-Za-z]', '', 'g');

UPDATE lines_noded
SET 
    cycleway_right_width = CASE
                              WHEN cycleway_right_width ~ '^\d+(\.\d+)?$' THEN cycleway_right_width
                              ELSE NULL
                          END,
    cycleway_left_width = CASE
                             WHEN cycleway_left_width ~ '^\d+(\.\d+)?$' THEN cycleway_left_width
                             ELSE NULL
                         END;

UPDATE lines_noded
SET cycleway_right_width = CASE
        WHEN cycleway_right_width::DECIMAL < 1.0 THEN 	'<1'
		WHEN cycleway_right_width::DECIMAL < 1.5 THEN 	'<1.5'
        WHEN cycleway_right_width::DECIMAL < 2.0 THEN 	'<2'
		WHEN cycleway_right_width::DECIMAL < 2.5 THEN 	'<2.5'
        WHEN cycleway_right_width::DECIMAL <= 3.0 THEN '<=3'
		WHEN cycleway_right_width::DECIMAL > 3.0 THEN 	'>3'
        ELSE NULL
END;

UPDATE lines_noded
SET cycleway_left_width = CASE
        WHEN cycleway_left_width::DECIMAL < 1.0 THEN 	'<1'
		WHEN cycleway_left_width::DECIMAL < 1.5 THEN 	'<1.5'
        WHEN cycleway_left_width::DECIMAL < 2.0 THEN 	'<2'
		WHEN cycleway_left_width::DECIMAL < 2.5 THEN 	'<2.5'
        WHEN cycleway_left_width::DECIMAL <= 3.0 THEN 	'<=3'
		WHEN cycleway_left_width::DECIMAL > 3.0 THEN 	'>3'
        ELSE NULL
END;

ALTER TABLE lines_noded
RENAME COLUMN cycleway_left_width TO cycleway_width_links;
ALTER TABLE lines_noded
RENAME COLUMN cycleway_right_width TO cycleway_width_rechts;

-- Attribuierung parkender Fahrzeuge anpassen
-- zuerst werden left und right ausgefüllt, falls both vorliegt.
UPDATE lines_noded
SET parking_left = CASE
    WHEN parking_left IS NULL THEN CASE
        WHEN parking_both IS NULL THEN parking_both
        END
    ELSE parking_left
    END;
UPDATE lines_noded
SET parking_left_orientation = CASE
    WHEN parking_left_orientation IS NULL THEN CASE
        WHEN parking_both_orientation IS NULL THEN parking_both_orientation
        END
    ELSE parking_left_orientation
    END;
-- dann wird die alte Tagging-Norm in die neuen Felder umgewandelt
UPDATE lines_noded
SET parking_left = CASE
    WHEN parking_left IS NULL THEN CASE
        WHEN parking_lane_both IS NOT NULL THEN CASE
            WHEN parking_lane_both IN ('yes', 'seperate', 'parallel', 'diagonal', 'perpendicular') THEN CASE
                WHEN parking_lane_both_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_both_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_parallel
                WHEN parking_lane_both_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_both_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_diagonal
                WHEN parking_lane_both_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_both_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_perpendicular
                END
            WHEN parking_lane_both = 'no' THEN parking_lane_both
            END
        WHEN parking_lane_left IS NOT NULL THEN CASE
            WHEN parking_lane_left IN ('yes', 'seperate', 'parallel') THEN CASE
                WHEN parking_lane_left_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_left_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_left_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_left_parallel
                WHEN parking_lane_left_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_left_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_left_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_left_diagonal
                WHEN parking_lane_left_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_left_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_left_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_left_perpendicular
                END
            WHEN parking_lane_left = 'no' THEN parking_lane_left
            END
    ELSE parking_left
    END
	ELSE parking_left 
	END;

UPDATE lines_noded
SET parking_left_orientation = CASE
    WHEN parking_left_orientation IS NULL THEN CASE
    WHEN parking_lane_both IS NOT NULL THEN CASE
        WHEN parking_lane_both IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_both
        WHEN parking_lane_both = 'no' THEN parking_lane_both
    END
    WHEN parking_lane_left IS NOT NULL THEN CASE
        WHEN parking_lane_left IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_left
        WHEN parking_lane_left = 'no' THEN parking_lane_left
    END
    ELSE parking_left_orientation
    END
	ELSE parking_left_orientation
	END;

UPDATE lines_noded
SET parking_left = CASE
    WHEN parking_left IS NULL THEN CASE
        WHEN parking_lane_both IS NOT NULL THEN CASE
            WHEN parking_lane_both IN ('yes', 'seperate', 'parallel', 'diagonal', 'perpendicular') THEN CASE
                WHEN parking_lane_both_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_both_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_parallel
                WHEN parking_lane_both_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_both_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_diagonal
                WHEN parking_lane_both_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_both_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_perpendicular
                END
            WHEN parking_lane_both = 'no' THEN parking_lane_both
            END
        WHEN parking_lane_left IS NOT NULL THEN CASE
            WHEN parking_lane_left IN ('yes', 'seperate', 'parallel') THEN CASE
                WHEN parking_lane_left_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_left_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_left_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_left_parallel
                WHEN parking_lane_left_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_left_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_left_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_left_diagonal
                WHEN parking_lane_left_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_left_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_left_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_left_perpendicular
                END
            WHEN parking_lane_left = 'no' THEN parking_lane_left
            END
    ELSE parking_left
    END
    ELSE parking_left
END;

UPDATE lines_noded
SET parking_left_orientation = CASE
    WHEN parking_left_orientation IS NULL THEN CASE
        WHEN parking_lane_both IS NOT NULL THEN CASE
            WHEN parking_lane_both IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_both
            WHEN parking_lane_both = 'no' THEN parking_lane_both
        END
        WHEN parking_lane_left IS NOT NULL THEN CASE
            WHEN parking_lane_left IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_left
            WHEN parking_lane_left = 'no' THEN parking_lane_left
        END
    ELSE parking_left_orientation
    END
ELSE parking_left_orientation
END;

-- Für die rechte Seite
UPDATE lines_noded
SET parking_right = CASE
    WHEN parking_right IS NULL THEN CASE
        WHEN parking_both IS NULL THEN parking_both
        END
    ELSE parking_right
    END;
UPDATE lines_noded
SET parking_right_orientation = CASE
    WHEN parking_right_orientation IS NULL THEN CASE
        WHEN parking_both_orientation IS NULL THEN parking_both_orientation
        END
    ELSE parking_right_orientation
    END;
-- dann wird die alte Tagging-Norm in die neuen Felder umgewandelt
UPDATE lines_noded
SET parking_right = CASE
    WHEN parking_right IS NULL THEN CASE
        WHEN parking_lane_both IS NOT NULL THEN CASE
            WHEN parking_lane_both IN ('yes', 'seperate', 'parallel', 'diagonal', 'perpendicular') THEN CASE
                WHEN parking_lane_both_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_both_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_parallel
                WHEN parking_lane_both_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_both_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_diagonal
                WHEN parking_lane_both_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_both_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_perpendicular
                END
            WHEN parking_lane_both = 'no' THEN parking_lane_both
            END
        WHEN parking_lane_right IS NOT NULL THEN CASE
            WHEN parking_lane_right IN ('yes', 'seperate', 'parallel') THEN CASE
                WHEN parking_lane_right_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_right_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_right_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_right_parallel
                WHEN parking_lane_right_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_right_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_right_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_right_diagonal
                WHEN parking_lane_right_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_right_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_right_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_right_perpendicular
                END
            WHEN parking_lane_right = 'no' THEN parking_lane_right
            END
    ELSE parking_right
    END
	ELSE parking_right
	END;

UPDATE lines_noded
SET parking_right_orientation = CASE
    WHEN parking_right_orientation IS NULL THEN CASE
    WHEN parking_lane_both IS NOT NULL THEN CASE
        WHEN parking_lane_both IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_both
        WHEN parking_lane_both = 'no' THEN parking_lane_both
    END
    WHEN parking_lane_right IS NOT NULL THEN CASE
        WHEN parking_lane_right IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_right
        WHEN parking_lane_right = 'no' THEN parking_lane_right
    END
    ELSE parking_right_orientation
    END
	ELSE parking_right_orientation
	END;

UPDATE lines_noded
SET parking_right = CASE
    WHEN parking_right IS NULL THEN CASE
        WHEN parking_lane_both IS NOT NULL THEN CASE
            WHEN parking_lane_both IN ('yes', 'seperate', 'parallel', 'diagonal', 'perpendicular') THEN CASE
                WHEN parking_lane_both_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_both_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_parallel
                WHEN parking_lane_both_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_both_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_diagonal
                WHEN parking_lane_both_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_both_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_both_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_both_perpendicular
                END
            WHEN parking_lane_both = 'no' THEN parking_lane_both
            END
        WHEN parking_lane_right IS NOT NULL THEN CASE
            WHEN parking_lane_right IN ('yes', 'seperate', 'parallel') THEN CASE
                WHEN parking_lane_right_parallel = 'on_street' THEN 'lane'
                WHEN parking_lane_right_parallel = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_right_parallel IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_right_parallel
                WHEN parking_lane_right_diagonal = 'on_street' THEN 'lane'
                WHEN parking_lane_right_diagonal = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_right_diagonal IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_right_diagonal
                WHEN parking_lane_right_perpendicular = 'on_street' THEN 'lane'
                WHEN parking_lane_right_perpendicular = 'on_sidewalk' THEN 'on_kerb'
                WHEN parking_lane_right_perpendicular IN ('half_on_kerb', 'on_kerb', 'street_side', 'shoulder') THEN parking_lane_right_perpendicular
                END
            WHEN parking_lane_right = 'no' THEN parking_lane_right
            END
    ELSE parking_right
    END
    ELSE parking_right
END;

UPDATE lines_noded
SET parking_right_orientation = CASE
    WHEN parking_right_orientation IS NULL THEN CASE
        WHEN parking_lane_both IS NOT NULL THEN CASE
            WHEN parking_lane_both IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_both
            WHEN parking_lane_both = 'no' THEN parking_lane_both
        END
        WHEN parking_lane_right IS NOT NULL THEN CASE
            WHEN parking_lane_right IN ('parallel', 'diagonal', 'perpendicular') THEN parking_lane_right
            WHEN parking_lane_right = 'no' THEN parking_lane_right
        END
    ELSE parking_right_orientation
    END
ELSE parking_right_orientation
END;

-- Jetzt werden die Spalten noch umbenannt, um in das spätere Schema der Widerstandsberechnung zu passen
ALTER TABLE lines_noded
RENAME COLUMN parking_left_orientation TO parking_orientation_links;
ALTER TABLE lines_noded
RENAME COLUMN parking_right_orientation TO parking_orientation_rechts;
ALTER TABLE lines_noded
RENAME COLUMN parking_left TO parking_position_links;
ALTER TABLE lines_noded
RENAME COLUMN parking_right TO parking_position_rechts;