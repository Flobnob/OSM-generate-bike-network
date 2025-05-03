ALTER Table lines 
    ADD column bicycle_forward TEXT, ADD column bicycle_backward TEXT,
    ADD column traffic_sign_forward TEXT, ADD column traffic_sign_backward TEXT,
    ADD column strassenbegleitend_links TEXT, ADD column strassenbegleitend_rechts TEXT,
    ADD COLUMN surface_links TEXT, ADD COLUMN surface_rechts TEXT,
    ADD COLUMN traffic_sign_links TEXT, ADD COLUMN traffic_sign_rechts TEXT,
    ADD COLUMN smoothness_links TEXT, ADD COLUMN smoothness_rechts TEXT,
    ADD COLUMN fuehrungsform_links text, ADD COLUMN fuehrungsform_rechts text
    ;

UPDATE lines
SET 
    bicycle_forward = tags->>'bicycle:forward',
    bicycle_backward = tags->>'bicycle:backward',
    traffic_sign_forward = tags ->>'traffic_sign:forward',
    traffic_sign_backward = tags ->>'traffic_sign:backward'
    ;

-- Im folgenden werden die seitenabhängigen Attribute mit den generellen Varianten befüllt, falls erstere nicht vorhanden sind, zweitere aber schon.
-- Falls nur way-zugehörige Attribute vorliegen, wird auf diese zurückgegriffen
UPDATE lines
SET
    surface_links = COALESCE(cycleway_left_surface, cycleway_both_surface, cycleway_surface, surface),
    surface_rechts = COALESCE(cycleway_right_surface, cycleway_both_surface, cycleway_surface, surface),
    smoothness_links = COALESCE(cycleway_left_smoothness, cycleway_both_smoothness, cycleway_smoothness, smoothness),
    smoothness_rechts = COALESCE(cycleway_right_smoothness, cycleway_both_smoothness, cycleway_smoothness, smoothness),
    cycleway_left = COALESCE(cycleway_left, cycleway_both, cycleway),
    cycleway_left_lane = COALESCE(cycleway_left_lane, cycleway_both_lane),
    cycleway_left_oneway = COALESCE(cycleway_left_oneway, cycleway_both_oneway, cycleway_oneway),
    cycleway_left_surface_colour = COALESCE(cycleway_left_surface_colour, cycleway_both_surface_colour),
    cycleway_left_buffer_left = COALESCE(cycleway_left_buffer_left, cycleway_both_buffer_left),
    cycleway_left_buffer_right = COALESCE(cycleway_left_buffer_right, cycleway_both_buffer_right),
    cycleway_left_buffer_both = COALESCE(cycleway_left_buffer_both, cycleway_both_buffer_both),
    cycleway_right = COALESCE(cycleway_right, cycleway_both, cycleway),
    cycleway_right_lane = COALESCE(cycleway_right_lane, cycleway_both_lane),
    cycleway_right_oneway = COALESCE(cycleway_right_oneway, cycleway_both_oneway, cycleway_oneway),
    cycleway_right_surface_colour = COALESCE(cycleway_right_surface_colour, cycleway_both_surface_colour),
    cycleway_right_buffer_left = COALESCE(cycleway_right_buffer_left, cycleway_both_buffer_left),
    cycleway_right_buffer_right = COALESCE(cycleway_right_buffer_right, cycleway_both_buffer_right),
    cycleway_right_buffer_both = COALESCE(cycleway_right_buffer_both, cycleway_both_buffer_both),
    traffic_sign_links = COALESCE(cycleway_left_traffic_sign, cycleway_both_traffic_sign, traffic_sign_backward, traffic_sign),
    traffic_sign_rechts = COALESCE(cycleway_right_traffic_sign, cycleway_both_traffic_sign, traffic_sign_forward, traffic_sign),
    cycleway_left_width = CASE 
        WHEN cycleway_left_width IS NOT NULL THEN cycleway_left_width
        WHEN cycleway_left_width IS NULL AND (cycleway_both_width IS NOT NULL OR cycleway_width IS NOT NULL) THEN COALESCE(cycleway_both_width, cycleway_width)
        WHEN cycleway_left_width IS NULL AND highway IN ('path', 'cycleway', 'footway', 'track', 'bridleway', 'living_street') THEN COALESCE(width, est_width)
        ELSE NULL
    END,
    cycleway_right_width = CASE 
        WHEN cycleway_right_width IS NOT NULL THEN cycleway_right_width
        WHEN cycleway_right_width IS NULL AND (cycleway_both_width IS NOT NULL OR cycleway_width IS NOT NULL) THEN COALESCE(cycleway_both_width, cycleway_width)
        WHEN cycleway_right_width IS NULL AND highway IN ('path', 'cycleway', 'footway', 'track', 'bridleway', 'living_street') THEN COALESCE(width, est_width)
        ELSE NULL
    END,
    strassenbegleitend_links = CASE
        WHEN tags ->>'is_sidepath' = 'yes' or cycleway_left IN ('track', 'sidepath') THEN 'yes'
        WHEN tags ->>'is_sidepath' = 'no' THEN 'no'
        WHEN highway IN ('track', 'path', 'cycleway', 'footway') THEN 'unsure'
        ELSE 'no'
    END,
    strassenbegleitend_rechts = CASE
        WHEN tags ->>'is_sidepath' = 'yes' or cycleway_right IN ('track', 'sidepath') THEN 'yes'
        WHEN tags ->>'is_sidepath' = 'no' THEN 'no'
        WHEN highway IN ('track', 'path', 'cycleway', 'footway') THEN 'unsure'
        ELSE 'no'
    END;
    
-- Bestimmung von Richtungsbeschränkungen, zuerst die in beide geöffneten checken um nichts ausversehen zu sperren
UPDATE lines
SET oneway_bicycle = CASE
    WHEN ("path" = 'crossing' or "highway" = 'steps')
    or (oneway_bicycle_text = 'no' or cycleway in ('opposite', 'opposite_track'))
    or (cycleway_left_oneway = 'no' or cycleway_right_oneway = 'no')
    or (cycleway_left_oneway = 'yes' and cycleway_right_oneway = 'yes')
        THEN 0
    
    WHEN oneway_bicycle_text = 'yes' or cycleway_left_oneway = 'yes' or cycleway_right_oneway = 'yes' THEN 1
    
    WHEN oneway_bicycle_text = '-1' or cycleway_left_oneway = '-1' or cycleway_right_oneway = '-1' THEN -1

    WHEN oneway_bicycle_text IS NULL AND oneway IS NOT NULL THEN oneway
    ELSE 0
END;