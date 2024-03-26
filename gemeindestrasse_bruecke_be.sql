--DROP VIEW IF EXISTS views.v_gemeindestrasse_bruecke_be; 

CREATE VIEW  views.v_gemeindestrasse_bruecke_be  AS


-- AX_Fahrbahnachse & AX_Strassenachse, plus ZUSO AX_Strasse (ax_strasse.widmung = 1301  => Bundesautobahn) 
-- plus: Atrribute ax_bauwerkimverkehrsbereich 
		
		
SELECT 
row_number() over(order by ax_fahrbahnachse.ogc_fid, ax_strassenachse.ogc_fid) AS "ID", 

	ax_fahrbahnachse.ogc_fid AS "FID_42005", 
	ax_strassenachse.ogc_fid AS "FID_42003", 

-- UNION:   AX_Fahrbahnachse & AX_Strassenachse 
	fahrstrasse_union.gml_id AS "OBJID", 
	fahrstrasse_union.besondereFahrstreifen AS "BFS", 
	fahrstrasse_union.breiteDerFahrbahn AS "BRF", 
	fahrstrasse_union.funktion AS "FKT", 
	fahrstrasse_union.anzahlDerFahrstreifen AS "FSZ", 
	fahrstrasse_union.zustand AS "ZUS", 
	fahrstrasse_union.oberflaechenmaterial AS "OFM", 
--	fahrstrasse_union.fahrtrichtung AS "FAR", 							-- ab ATKIS-OK 7.1.0 

-- JOIN:   AX_Strassenachse 			
--	besondereVerkehrsbedeutung	AS "BVB", 								-- ab ATKIS-OK 7.1.0 
	breiteDesVerkehrsweges AS "BRV", 
	verkehrsbedeutungInneroertlich AS "BDI", 							-- bis ATKIS-OK 6.0.1 
	verkehrsbedeutungUeberoertlich AS "BDU", 							-- bis ATKIS-OK 6.0.1 

-- JOIN:   AX_Strasse 				
	ax_strasse.ogc_fid AS "FID_42002_Z", 
	ax_strasse.gml_id AS "OBJID_Z", 
	fahrbahntrennung AS "FTR", 
	internationaleBedeutung AS "IBD", 
	ax_strasse.bezeichnung AS "BEZ", 
	ax_strasse.name AS "NAM", 
	widmung AS "WDM", 
	strassenschluessel AS "STS", 
	zweitname AS "ZNM", 
--	regionalsprache	AS "RGS", 											-- ab ATKIS-OK 7.1.0 

	fahrstrasse_union.wkb_geometry AS "GEOM", 
	
-- JOIN:   ax_bauwerkimverkehrsbereich   (ohne Geometrien) 
	tunnel_join.ogc_fid AS "FID_53001", 
	tunnel_join.gml_id AS "OBJID_53001", 
	tunnel_join.bauwerksfunktion AS "BWF", 
	tunnel_join.name AS "NAM_53001", 
	tunnel_join.bezeichnung AS "BEZ_53001", 
	tunnel_join.zustand AS "ZUS_53001", 
	tunnel_join.durchfahrtshoehe AS "DHU", 
	tunnel_join.breitedesobjekts AS "BRO"
--	, tunnel_join.objekthoehe AS "HHO" 									-- ab ATKIS-OK 7.1.0 

FROM ( 
		SELECT 
			gml_id, 													-- fuer JOINs 
			advstandardmodell, 											-- fuer WHERE-CLause 
			besondereFahrstreifen, 
			breiteDerFahrbahn, 
			funktion, 
			anzahlDerFahrstreifen, 
			zustand, 
			oberflaechenmaterial, 
--			fahrtrichtung,												-- ab ATKIS-OK 7.1.0 
			istteilvon, 												-- fuer JOIN mit ZUSO ax_strasse 
			hatdirektunten, 
			wkb_geometry 
		FROM ax_fahrbahnachse 
	UNION ALL 
		SELECT 
			gml_id, 													-- fuer JOINs 
			advstandardmodell, 											-- fuer WHERE-CLause 
			besondereFahrstreifen, 
			breiteDerFahrbahn, 
			funktion, 
			anzahlDerFahrstreifen, 
			zustand, 
			oberflaechenmaterial, 
--			fahrtrichtung,												-- ab ATKIS-OK 7.1.0 
			istteilvon, 												-- fuer JOIN mit ZUSO ax_strasse 
			hatdirektunten, 
			wkb_geometry 
		FROM ax_strassenachse 
) AS fahrstrasse_union 

LEFT JOIN ax_fahrbahnachse ON ax_fahrbahnachse.gml_id = fahrstrasse_union.gml_id 					-- fuer FID-Spalte 
LEFT JOIN ax_strassenachse ON 	ax_strassenachse.gml_id = fahrstrasse_union.gml_id 

LEFT JOIN ax_strasse ON ax_strasse.gml_id = ANY(fahrstrasse_union.istteilvon) 

RIGHT JOIN (			
	SELECT ogc_fid, gml_id, zustand, bezeichnung, name, durchfahrtshoehe, breitedesobjekts, bauwerksfunktion
--				, objekthoehe 																		-- ab ATKIS-OK 7.1.0 
	FROM ax_bauwerkimverkehrsbereich 
		WHERE bauwerksfunktion IN (1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1830) 
) AS tunnel_join ON tunnel_join.gml_id = any(fahrstrasse_union.hatdirektunten)

--WHERE fahrstrasse_union.advstandardmodell @> ('{Basis-DLM}')			-- wird hier benötigt, denn es existiert advstandardmodell = DTK25 | DTK10 
WHERE 'Basis-DLM' = ANY(fahrstrasse_union.advstandardmodell) 			-- same
	AND ax_strasse.widmung IN (1307, 9997, 9999) 
; 


ALTER TABLE views.v_gemeindestrasse_bruecke_be OWNER TO postgres;
