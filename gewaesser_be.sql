--DROP VIEW IF EXISTS views.v_gewaesser_be; 

CREATE VIEW  views.v_gewaesser_be  AS


-- aus: q_gewaesser_be__6_UNIONS , aehnlich v_fliessgewaesser_3_be, plus ax_stehendesgewaesser 
-- 3. UNION: NamensSpalte der ZUSOs ax_wasserlauf & ax_kanal mit der von ax_hafenbecken & ax_stehendesgewaesser verknuepfen 
-- weitere 3 UNIONS aufgrund Attributart-Ueberschneidungen vorhandener UNION- /Tabellen mit ax_stehendesgewaesser 
	

SELECT 
row_number() over(order by ax_fliessgewaesser.ogc_fid, ax_hafenbecken.ogc_fid, ax_stehendesgewaesser.ogc_fid) AS "ID", 

	ax_fliessgewaesser.ogc_fid AS "FID_44001", 
	ax_hafenbecken.ogc_fid AS "FID_44005", 
	ax_stehendesgewaesser.ogc_fid AS "FID_44006", 
	stehfliesshafen_union.gml_id AS "OBJID", 
	
	stehhafenkanalwasser_union.name AS "NAM", 
	
	stehfliess_union.funktion AS "FKT", 
	stehfliess_union.hydrologischesmerkmal AS "HYD", 
	--stehfliess_union.zustand AS "ZUS", 								-- ab ATKIS-OK 7.1.0

	ax_fliessgewaesser.zustand AS "ZUS", 								-- nur bis ATKIS-OK 6.0.1, siehe stehfliess_union 

	ax_hafenbecken.nutzung AS "NTZ",  								-- nur bis ATKIS-OK 6.0.1, siehe stehhafen_union 
	--stehhafen_union.nutzung AS "NTZ", 								-- ab ATKIS-OK 7.1.0 

	ax_stehendesgewaesser.bezeichnung AS "BEZ", 
	--ax_stehendesgewaesser.wasserspiegelhoeheinstehendemgewaesser AS "WSG", 			-- ab ATKIS-OK 7.1.0 
	
	--stehhafenkanalwasser_union.gewaesserkennzahl AS "GWK_SKZ", 					-- ab ATKIS-OK 7.1.0 
	stehwasserkanal_union.gewaesserkennzahl AS "GWK", 						-- bis ATKIS-OK 6.0.1, siehe stehhafenkanalwasser_union  
	stehwasserkanal_union.schifffahrtskategorie AS "SFK", 
	stehwasserkanal_union.widmung AS "WDM", 
	--stehwasserkanal_union.regionalsprache AS "RGS",						-- ab ATKIS-OK 7.1.0 
	--stehwasserkanal_union.zweitname AS "ZNM, 							-- ab ATKIS-OK 7.1.0 
	
	
	ax_wasserlauf.ogc_fid AS "FID_44002_Z", 
	ax_kanal.ogc_fid AS "FID_44003_Z", 
	
	kanalWasserlauf_union.gml_id AS "OBJID_Z", 
	kanalWasserlauf_union.identnummer AS "IDN", 
	kanalWasserlauf_union.zweitname AS "ZNM", 							-- bis ATKIS-OK 6.0.1, siehe stehhafenkanalwasser_union  

	stehfliesshafen_union.wkb_geometry AS "GEOM" 	

	
FROM  
(
	SELECT 
			ax_wasserlauf.gml_id, 
			ax_wasserlauf.name, 
			ax_wasserlauf.gewaesserkennzahl, 
			ax_wasserlauf.identnummer, 
			ax_wasserlauf.schifffahrtskategorie, 
			ax_wasserlauf.widmung, 
			ax_wasserlauf.zweitname 							-- bis ATKIS-OK 6.0.1 
		--	ax_wasserlauf.regionalsprache, 							--  ab ATKIS-OK 7.1.0
	FROM ax_wasserlauf 

		UNION ALL 
		
	SELECT 
			ax_kanal.gml_id, 
			ax_kanal.name, 
			ax_kanal.gewaesserkennzahl, 
			ax_kanal.identnummer, 
			ax_kanal.schifffahrtskategorie, 
			ax_kanal.widmung, 
			ax_kanal.zweitname 								-- bis ATKIS-OK 6.0.1 
		--	ax_kanal.regionalsprache, 							--  ab ATKIS-OK 7.1.0
	FROM ax_kanal 

) AS kanalWasserlauf_union 


LEFT JOIN ax_wasserlauf ON kanalWasserlauf_union.gml_id = ax_wasserlauf.gml_id 
LEFT JOIN ax_kanal ON kanalWasserlauf_union.gml_id = ax_kanal.gml_id 
RIGHT JOIN ( 
		SELECT 
		ax_fliessgewaesser.gml_id, 
		ax_fliessgewaesser.advstandardmodell, 							-- fuer WHERE-Clause am Ende 
		ax_fliessgewaesser.istteilvon,  							-- fuer JOIN mit kanalWasserlauf_union 
		ax_fliessgewaesser.wkb_geometry
		FROM ax_fliessgewaesser 
	UNION ALL 
		SELECT 
		ax_hafenbecken.gml_id, 
		ax_hafenbecken.advstandardmodell, 
		ax_hafenbecken.istteilvon,  
		ax_hafenbecken.wkb_geometry
		FROM ax_hafenbecken 
	UNION ALL 
		SELECT 
		ax_stehendesgewaesser.gml_id, 
		ax_stehendesgewaesser.advstandardmodell, 
		ax_stehendesgewaesser.istteilvon,  
		ax_stehendesgewaesser.wkb_geometry 
		FROM ax_stehendesgewaesser
) 	AS stehfliesshafen_union 
 ON kanalWasserlauf_union.gml_id = any(stehfliesshafen_union.istteilvon) 


LEFT JOIN ax_fliessgewaesser ON stehfliesshafen_union.gml_id = ax_fliessgewaesser.gml_id 
LEFT JOIN ax_hafenbecken ON stehfliesshafen_union.gml_id = ax_hafenbecken.gml_id 
LEFT JOIN ax_stehendesgewaesser ON  stehfliesshafen_union.gml_id = ax_stehendesgewaesser.gml_id 


-- gemeinsame NamensSpalte  (ab ATKIS-OK 7.1.0 : gewaesserkennzahl & seekennzahl) 
LEFT JOIN ( 
		SELECT 
			ax_wasserlauf.gml_id, 								-- gml_id-Spalten fuer JOIN 
			ax_wasserlauf.name 
			--, ax_wasserlauf.gewaesserkennzahl 						-- ab ATKIS-OK 7.1.0 
		FROM ax_wasserlauf 
	UNION ALL 
		SELECT 
			ax_kanal.gml_id, 
			ax_kanal.name 
			--, ax_kanal.gewaesserkennzahl 							-- ab ATKIS-OK 7.1.0 
		FROM ax_kanal 
	UNION ALL 
		SELECT 
			ax_hafenbecken.gml_id, 
			ax_hafenbecken.unverschluesselt 
			--, ax_hafenbecken.seekennzahl 							-- ab ATKIS-OK 7.1.0 
		FROM ax_hafenbecken 
	UNION ALL 
		SELECT 
			ax_stehendesgewaesser.gml_id, 
			ax_stehendesgewaesser.unverschluesselt 
			--, ax_stehendesgewaesser.seekennzahl 						-- ab ATKIS-OK 7.1.0 
		FROM ax_stehendesgewaesser 
) AS stehhafenkanalwasser_union ON stehhafenkanalwasser_union.gml_id = any(stehfliesshafen_union.istteilvon) 
					OR stehhafenkanalwasser_union.gml_id = ax_hafenbecken.gml_id 
					OR stehhafenkanalwasser_union.gml_id = ax_stehendesgewaesser.gml_id 

													
-- Spalten: funktion, hydrologischesmerkmal, zustand 
LEFT JOIN ( 
		SELECT 
			ax_stehendesgewaesser.gml_id, 
			ax_stehendesgewaesser.funktion, 
			ax_stehendesgewaesser.hydrologischesmerkmal 
			--, ax_stehendesgewaesser.zustand						-- ab ATKIS-OK 7.1.0
		FROM ax_stehendesgewaesser 
	UNION ALL 
		SELECT 
			ax_fliessgewaesser.gml_id, 
			ax_fliessgewaesser.funktion, 
			ax_fliessgewaesser.hydrologischesmerkmal 
			--, ax_fliessgewaesser.zustand
		FROM ax_fliessgewaesser 
) AS stehfliess_union ON stehfliess_union.gml_id = stehfliesshafen_union.gml_id 


-- Spalten: gewaesserkennzahl, widmung, schifffahrtskategorie, regionalsprache, zweitname 
LEFT JOIN ( 
		SELECT 
			ax_wasserlauf.gml_id, 
			ax_wasserlauf.gewaesserkennzahl, 						-- bis ATKIS-OK 6.0.1 
			ax_wasserlauf.widmung, 
			ax_wasserlauf.schifffahrtskategorie 
			--, ax_wasserlauf.regionalsprache						-- ab ATKIS-OK 7.1.0 
			--, ax_wasserlauf.zweitname 							-- ab ATKIS-OK 7.1.0 
		FROM ax_wasserlauf 
	UNION ALL 
		SELECT 
			ax_kanal.gml_id, 
			ax_kanal.gewaesserkennzahl, 							-- bis ATKIS-OK 6.0.1 
			ax_kanal.widmung, 
			ax_kanal.schifffahrtskategorie 
			--, ax_kanal.regionalsprache							-- ab ATKIS-OK 7.1.0 
			--, ax_kanal.zweitname 								-- ab ATKIS-OK 7.1.0 
		FROM ax_kanal 
	UNION ALL 
		SELECT 
			ax_stehendesgewaesser.gml_id, 
			ax_stehendesgewaesser.gewaesserkennziffer, 					-- bis ATKIS-OK 6.0.1 
			ax_stehendesgewaesser.widmung, 
			ax_stehendesgewaesser.schifffahrtskategorie 
			--, ax_stehendesgewaesser.regionalsprache 					-- ab ATKIS-OK 7.1.0 
			--, ax_stehendesgewaesser.zweitname 						-- ab ATKIS-OK 7.1.0 
		FROM ax_stehendesgewaesser 
) AS stehwasserkanal_union ON stehwasserkanal_union.gml_id = ax_wasserlauf.gml_id 
				OR stehwasserkanal_union.gml_id = ax_kanal.gml_id 
				OR stehwasserkanal_union.gml_id = ax_stehendesgewaesser.gml_id

									
/*
-- Spalte: nutzung 
LEFT JOIN ( 												-- ab ATKIS-OK 7.1.0 
		SELECT 
			ax_hafenbecken.gml_id, 
			ax_hafenbecken.nutzung 
		FROM ax_hafenbecken 
	UNION ALL 
		SELECT 
			ax_stehendesgewaesser.gml_id, 
			ax_stehendesgewaesser.nutzung 							-- ab ATKIS-OK 7.1.0 
		FROM ax_stehendesgewaesser 
) AS stehhafen_union ON stehhafen_union.gml_id = stehfliesshafen_union.gml_id 
*/


WHERE stehfliesshafen_union.advstandardmodell @> ('{Basis-DLM}')					-- wird hier benötigt, denn es existiert advstandardmodell = DTK25
; 


ALTER TABLE views.v_gewaesser_be OWNER TO postgres;
