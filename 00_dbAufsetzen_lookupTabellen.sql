DROP SCHEMA IF EXISTS public CASCADE;
DROP SCHEMA IF EXISTS resistance_mappings CASCADE;

CREATE SCHEMA public;
CREATE EXTENSION postgis;
CREATE EXTENSION hstore;
CREATE EXTENSION pgrouting;

CREATE SCHEMA resistance_mappings;

DO $$ 
DECLARE	
    attribute RECORD;
    resistance_mappings TEXT[] := ARRAY[
        'fuehrungsform', 
        'surface',
        'smoothness',
		'landuse_line',
		'natural_line',
		'maxspeed',
        'cycleway_width',
        'lit',
        'parking_orientation',
        'parking_position',
        'gleise',
        'highway',
        'highway_filled',
        'maxspeed_filled',
        'verkehrsregelung'
    ];
BEGIN
    FOR attribute IN SELECT unnest(resistance_mappings) AS attribute LOOP
        EXECUTE format(
            'CREATE TABLE resistance_mappings.%1$I_mapping (
                %1$I TEXT PRIMARY KEY,
                factor NUMERIC
            );', 
            attribute.attribute
        );
    END LOOP;
END $$;

INSERT INTO resistance_mappings.verkehrsregelung_mapping (verkehrsregelung, factor) VALUES
	('halten', 1.1),
	('ampel', 1.2)
;

INSERT INTO resistance_mappings.fuehrungsform_mapping (fuehrungsform, factor) VALUES
	('Fahrradstrasse', 0.8),
	('Radweg', 0.9),
	('Getrennter Rad- und Gehweg', 1.0),
	('Gemeinsamer Geh- und Radweg', 1.2),
	('Geteilte Busspur', 1.2),
	('Erschliessungsweg', 5.0),
	('Freier Weg', 1.5),
	('Fahrradfahrstreifen', 1.6),
	('Fahrradschutzstreifen', 2.0),
	('Gehweg, Radverkehr frei', 3.0),
	('Mischverkehr', 3.0),
	('Uebergang', 1.0),
	('Treppenstufen', 5.0),
	('Kein Zugang', -1),
	('Unbekannt', -1),
	('Fahrradfahrer absteigen', 15.0),
	('Verkehrsberuhigter Bereich', 1.5)
;

INSERT INTO resistance_mappings.surface_mapping (surface, factor) VALUES
	('asphalt', 1.0),
	('cobblestone', 1.6),
	('compacted', 1.5),
	('concrete', 1.0),
	('concrete:plates', 1.1),
	('concrete:lanes', 2.0),
	('dirt', 2.0),
	('fine_gravel', 1.4),
	('grass', 7.0),
	('gravel', 2.0),
	('ground', 3.0),
	('paved', 1.3),
	('paving_stones', 1.1),
	('pebblestone', 1.5),
	('sand', 10.0),
	('sett', 1.4),
	('unpaved', 2.5),
	('unhewn_cobblestone', 3.0),
	('wood', 1.0)
;

INSERT INTO resistance_mappings.smoothness_mapping (smoothness, factor) VALUES
	('excellent', 1.0),
	('good', 1.1),
	('intermediate', 1.3),
	('bad', 1.6),
	('very_bad', 3.0),
	('horrible', 999.0),
	('very_horrible', 999.0),
	('impassable', 999.0)
;

INSERT INTO resistance_mappings.landuse_line_mapping (landuse_line, factor) VALUES
    ('residential_area', 1.0),
    ('commercial_area', 1.0),
    ('industrial_area', 1.2),
    ('farming_area', 0.9),
    ('open_area', 0.9),
    ('forest_area', 0.9),
    ('other_area', 1.0);

INSERT INTO resistance_mappings.natural_line_mapping (natural_line, factor) VALUES
    ('blue_area', 0.9),
    ('open_area', 0.9),
    ('tree_area', 0.9),
    ('other_area', 1.0);

INSERT INTO resistance_mappings.cycleway_width_mapping (cycleway_width, factor) VALUES
    ('<1', 2.0),
    ('<1.5', 1.5),
    ('<2', 1.0),
    ('<2.5', 0.9),
    ('<=3', 0.8),
    ('>3', 0.7);

INSERT INTO resistance_mappings.lit_mapping (lit, factor) VALUES
    ('yes', 0.9),
    ('no', 1.0);

INSERT INTO resistance_mappings.parking_orientation_mapping (parking_orientation, factor) VALUES
    ('parallel', 1.3),
    ('diagonal', 1.2),
    ('perpendicular', 1.2)
    ;

INSERT INTO resistance_mappings.parking_position_mapping (parking_position, factor) VALUES
    ('no', 0.9),
    ('yes', 1.3),
    ('lane', 1.3),
    ('on_kerb', 1.2),
    ('half_on_kerb', 1.2),
    ('on_shoulder', 1.2),
    ('street_side', 1.1),
    ('seperate', 1.1)
    ;

INSERT INTO resistance_mappings.gleise_mapping (gleise, factor) VALUES
    ('no', 1.0),
    ('uebergang', 1.3),
    ('eingelassen', 1.5);

/* Die Liste entspricht allen Highway-Typen die vor Filterung durch Führungsform in den Daten vorhanden war. Hier wird eine Verringerung des empfundenen Widerstands durch
die Verkehrsbelastung simuliert, in einem Modell sollten diese Werte durch die Umlegungsergebnisse gefüllt werden*/

INSERT INTO resistance_mappings.highway_mapping (highway, factor) VALUES
    ('abandoned',       1.0),
    ('bridleway',       1.0),
    ('bus_stop',        1.0),
    ('construction',    1.0),
    ('corridor',        1.0),
    ('cycleway',        1.0),
    ('elevator',        1.0),
    ('footway',         1.0),
    ('living_street',   1.3),
    ('loading_ramp',    1.0),
    ('motorway',        5.0),
    ('motorway_link',   5.0),
    ('no',              1.0),
    ('passing_place',   1.0),
    ('path',            1.0),
    ('pedestrian',      1.1),
    ('platform',        1.0),
    ('primary',         2.5),
    ('primary_link',    2.5),
    ('proposed',        1.0),
    ('raceway',         1.0),
    ('razed',           1.0),
    ('residential',     1.5),
    ('rest_area',       1.0),
    ('road',            1.5),
    ('secondary',       2.0),
    ('secondary_link',  2.0),
    ('service',         1.0),
    ('services',        1.0),
    ('steps',           1.0),
    ('street_lamp',     1.0),
    ('tertiary',        1.5),
    ('tertiary_link',   1.5),
    ('track',           1.1),
    ('trunk',           4.0),
    ('trunk_link',      4.0),
    ('unclassified',    2.0);

INSERT INTO resistance_mappings.highway_filled_mapping (highway_filled, factor) VALUES
    ('abandoned',       1.0),
    ('bridleway',       1.0),
    ('bus_stop',        1.0),
    ('construction',    1.0),
    ('corridor',        1.0),
    ('cycleway',        1.0),
    ('elevator',        1.0),
    ('footway',         1.0),
    ('living_street',   1.3),
    ('loading_ramp',    1.0),
    ('motorway',        5.0),
    ('motorway_link',   5.0),
    ('no',              1.0),
    ('passing_place',   1.0),
    ('path',            1.0),
    ('pedestrian',      1.1),
    ('platform',        1.0),
    ('primary',         2.5),
    ('primary_link',    2.5),
    ('proposed',        1.0),
    ('raceway',         1.0),
    ('razed',           1.0),
    ('residential',     1.5),
    ('rest_area',       1.0),
    ('road',            1.5),
    ('secondary',       2.0),
    ('secondary_link',  2.0),
    ('service',         1.0),
    ('services',        1.0),
    ('steps',           1.0),
    ('street_lamp',     1.0),
    ('tertiary',        1.5),
    ('tertiary_link',   1.5),
    ('track',           1.1),
    ('trunk',           4.0),
    ('trunk_link',      4.0),
    ('unclassified',    2.0);
    
INSERT INTO resistance_mappings.maxspeed_filled_mapping (maxspeed_filled, factor) VALUES
    ('<15', 1.0),
    ('<30', 1.3),
    ('<40', 1.5),
    ('<50', 2.0),
    ('<80', 3.0),
    ('>=80', 5.0);