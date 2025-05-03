INSERT INTO lines_noded (
    id, name, highway, geom, source, target, oneway, oneway_bicycle,
    fuehrungsform_rechts, zuweisungsattribut_rechts, strassenbegleitend_rechts,
    surface_rechts, smoothness_rechts, cycleway_width_rechts,
    parking_orientation_rechts, parking_position_rechts,
    gleise, maxspeed_filled, traffic_sign_rechts, rel_refs, bridge, tunnel, landuse_line, natural_line, lit,
    fb_vorsichtigen_r, fb_pragmatischen_r, fb_effizienten_r, fb_ungewichtet_r,
    ew_vorsichtigen_r, ew_pragmatischen_r, ew_effizienten_r,
    tags
)
SELECT 
    id + 10000000, name, highway, geom,
    target AS source, source AS target,
    oneway, oneway_bicycle,
    fuehrungsform_links AS fuehrungsform_rechts, zuweisungsattribut_links AS zuweisungsattribut_rechts, strassenbegleitend_links AS strassenbegleitend_rechts,
    surface_links AS surface_rechts, smoothness_links AS smoothness_rechts, cycleway_width_links AS cycleway_width_rechts,
    parking_orientation_links AS parking_orientation_rechts, parking_position_links AS parking_position_rechts,
    gleise, maxspeed_filled, traffic_sign_links AS traffic_sign_rechts, rel_refs, bridge, tunnel, landuse_line, natural_line, lit,
    fb_vorsichtigen_l AS fb_vorsichtigen_r, fb_pragmatischen_l AS fb_pragmatischen_r, fb_effizienten_l AS fb_effizienten_r, fb_ungewichtet_l as fb_ungewichtet_r,
    ew_vorsichtigen_l AS ew_vorsichtigen_r, ew_pragmatischen_l AS ew_pragmatischen_r, ew_effizienten_l AS ew_effizienten_r,
    tags AS tags
FROM lines_noded WHERE oneway_bicycle = 0 or oneway_bicycle = -1;

UPDATE lines_noded
SET geom = ST_Reverse(geom)
WHERE old_id IS NULL;