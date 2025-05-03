@echo off
set PG_BIN="C:\Program Files\PostgreSQL\17\bin\"
set PG_USER=DBUSER
set PG_DB=DBNAME
set PGPASSWORD=DBPASSWORD

%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\00_dbAufsetzen_lookupTabellen.sql"
osm2pgsql -d %PG_DB% -U %PG_USER% -O flex -S "C:FILEPATHTO\config.lua" "C:FILEPATHTO\mecklenburg-vorpommern-latest.osm.pbf"


%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\01_koordinatenTransformieren.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\02_seitenabhaengigeAttribute.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\03_fuehrungsformAbleiten.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\04_topologieBearbeiten.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\05_werteNormalisieren.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\06_umgebungswerteUebertragen.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\07_knotenpunktwerteUebertragen.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\08_widerstaendeBerechnen.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\09_richtungenTrennen.sql"
%PG_BIN%psql -d %PG_DB% -U %PG_USER% -f "C:FILEPATHTO\20_turningCosts.sql"

pause