DO $$
DECLARE
  start_id INTEGER := 123778;
  end_id   INTEGER := 39360;
BEGIN
  -- Vorsichtigen
  EXECUTE format('
    DROP TABLE IF EXISTS route_result_vorsichtigen;
    CREATE TABLE route_result_vorsichtigen AS
    SELECT
      ln.*,
      rt.seq,
      rt.id1 AS node,
      rt.id2 AS edge,
      rt.cost
    FROM lines_noded AS ln
    JOIN pgr_trsp(
      ''SELECT
          id::INTEGER,
          source::INTEGER,
          target::INTEGER,
          ew_vorsichtigen_r::DOUBLE PRECISION AS cost,
          -1::DOUBLE PRECISION AS reverse_cost
        FROM lines_noded'',
      %s, %s,
      true, true,
      ''SELECT to_cost, target_id, via_path FROM restrictions''
    ) AS rt
    ON ln.id = rt.id2;',
    start_id, end_id
  );

  -- Pragmatischen
  EXECUTE format('
    DROP TABLE IF EXISTS route_result_pragmatischen;
    CREATE TABLE route_result_pragmatischen AS
    SELECT
      ln.*,
      rt.seq,
      rt.id1 AS node,
      rt.id2 AS edge,
      rt.cost
    FROM lines_noded AS ln
    JOIN pgr_trsp(
      ''SELECT
          id::INTEGER,
          source::INTEGER,
          target::INTEGER,
          ew_pragmatischen_r::DOUBLE PRECISION AS cost,
          -1::DOUBLE PRECISION AS reverse_cost
        FROM lines_noded'',
      %s, %s,
      true, true,
      ''SELECT to_cost, target_id, via_path FROM restrictions''
    ) AS rt
    ON ln.id = rt.id2;',
    start_id, end_id
  );

  -- Effizienten
  EXECUTE format('
    DROP TABLE IF EXISTS route_result_effizienten;
    CREATE TABLE route_result_effizienten AS
    SELECT
      ln.*,
      rt.seq,
      rt.id1 AS node,
      rt.id2 AS edge,
      rt.cost
    FROM lines_noded AS ln
    JOIN pgr_trsp(
      ''SELECT
          id::INTEGER,
          source::INTEGER,
          target::INTEGER,
          ew_effizienten_r::DOUBLE PRECISION AS cost,
          -1::DOUBLE PRECISION AS reverse_cost
        FROM lines_noded'',
      %s, %s,
      true, true,
      ''SELECT to_cost, target_id, via_path FROM restrictions''
    ) AS rt
    ON ln.id = rt.id2;',
    start_id, end_id
  );

END $$;
