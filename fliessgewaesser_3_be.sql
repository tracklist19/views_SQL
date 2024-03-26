--DROP VIEW IF EXISTS views.v_fliessgewaesser_3_be; 

CREATE VIEW  views.v_fliessgewaesser_3_be  AS

-- aus: q_fliessgewaesser_3_be__gemNAM 
-- ohne Vorgabe: analog zu q_fliessgewaesser_1_be, plus ax_hafenbecken, 
-- um weniger Lücken in den Fliessgewaessern zu haben (Hafen_BE (ohne Vorgabe) extra (-> ax_hafen)) 
-- einige ax_stehendesgewaesser schaffen dennoch Unterbrechungen in ax_fliessgewaesser 

SELECT 
row_number() over(order by ax_fliessgewaesser.ogc_fid, ax_hafenbecken.ogc_fid ) AS "ID", 

	ax_fliessgewaesser.ogc_fid AS "FID_44001", 
	ax_hafenbecken.ogc_fid AS "FID_44005", 
	fliesshafen_union.gml_id AS "OBJID", 
	
	ax_fliessgewaesser.hydrologischesmerkmal AS "HYD", 
	ax_fliessgewaesser.funktion AS "FKT", 							-- aktuell nur Kanal: 8300 
	ax_fliessgewaesser.zustand AS "ZUS", 
	
	hafenkanalwasser_union.name AS "NAM", 
	
	ax_hafenbecken.nutzung AS "NTZ", 
	--ax_hafenbecken.seekennzahl AS "SKZ", 							-- ab ATKIS-OK 7.1.0

	ax_wasserlauf.ogc_fid AS "FID_44002_Z", 
	ax_kanal.ogc_fid AS "FID_44003_Z", 
	
	kanalWasserlauf_union.gml_id AS "OBJID_Z", 
	kanalWasserlauf_union.gewaesserkennzahl AS "GWK", 
	kanalWasserlauf_union.identnummer AS "IDN", 
	kanalWasserlauf_union.schifffahrtskategorie AS "SFK", 
	kanalWasserlauf_union.widmung AS "WDM", 
	kanalWasserlauf_union.zweitname AS "ZNM", 
--	kanalWasserlauf_union.regionalsprache AS "RGS", 					-- ab ATKIS-OK 7.1.0

	fliesshafen_union.wkb_geometry AS "GEOM" 	

FROM  
(
	SELECT 
			ax_wasserlauf.gml_id, 
			ax_wasserlauf.gewaesserkennzahl, 
			ax_wasserlauf.identnummer, 
			ax_wasserlauf.schifffahrtskategorie, 
			ax_wasserlauf.widmung, 
			ax_wasserlauf.zweitname 
		--	ax_wasserlauf.regionalsprache, 						-- ab ATKIS-OK 7.1.0
	FROM ax_wasserlauf 

		UNION ALL 
		
	SELECT 
			ax_kanal.gml_id, 
			ax_kanal.gewaesserkennzahl, 
			ax_kanal.identnummer, 
			ax_kanal.schifffahrtskategorie, 
			ax_kanal.widmung, 
			ax_kanal.zweitname 
		--	ax_kanal.regionalsprache, 						-- ab ATKIS-OK 7.1.0
	FROM ax_kanal 

) AS kanalWasserlauf_union 


LEFT JOIN ax_wasserlauf ON kanalWasserlauf_union.gml_id = ax_wasserlauf.gml_id 
LEFT JOIN ax_kanal ON kanalWasserlauf_union.gml_id = ax_kanal.gml_id 
RIGHT JOIN ( 
		SELECT 
		ax_fliessgewaesser.gml_id, 
		ax_fliessgewaesser.advstandardmodell, 						-- fuer WHERE-Clause am Ende 
		ax_fliessgewaesser.istteilvon,  						-- fuer JOIN mit kanalWasserlauf_union 
		ax_fliessgewaesser.wkb_geometry
		FROM ax_fliessgewaesser 
	UNION ALL 
		SELECT 
		ax_hafenbecken.gml_id, 
		ax_hafenbecken.advstandardmodell, 
		ax_hafenbecken.istteilvon,  
		ax_hafenbecken.wkb_geometry
		FROM ax_hafenbecken
) 	AS fliesshafen_union 
 ON kanalWasserlauf_union.gml_id = any(fliesshafen_union.istteilvon) 

LEFT JOIN ax_fliessgewaesser ON fliesshafen_union.gml_id = ax_fliessgewaesser.gml_id 
LEFT JOIN ax_hafenbecken ON fliesshafen_union.gml_id = ax_hafenbecken.gml_id 

-- gemeinsame NamensSpalte 
LEFT JOIN ( 
		SELECT 
			ax_wasserlauf.gml_id, 							-- gml_id-Spalten fuer JOIN 
			ax_wasserlauf.name 
		FROM ax_wasserlauf 
	UNION ALL 
		SELECT 
			ax_kanal.gml_id, 
			ax_kanal.name 
		FROM ax_kanal 
	UNION ALL 
		SELECT 
			ax_hafenbecken.gml_id, 
			ax_hafenbecken.unverschluesselt --AS name
		FROM ax_hafenbecken 
) AS hafenkanalwasser_union ON hafenkanalwasser_union.gml_id = any(fliesshafen_union.istteilvon) 
				OR hafenkanalwasser_union.gml_id = ax_hafenbecken.gml_id 

WHERE fliesshafen_union.advstandardmodell @> ('{Basis-DLM}')				-- wird hier benötigt, denn es existiert advstandardmodell = DTK25
; 


ALTER TABLE views.v_fliessgewaesser_3_be OWNER TO postgres;
