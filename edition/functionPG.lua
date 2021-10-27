dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

-- https://www.fis-ski.com/DB/alpine-skiing/biographies.html?lastname=&firstname=&sectorcode=AL&gendercode=&birthyear=&skiclub=&skis=&nationcode=&fiscode=198029&status=&search=true
-- textctrlbutton
-- local tTxtCtrlbutton = toto:GetWindowName('nation')
-- tTxtCtrlbutton:SetSelection(tNation, 'Code', 'Code, Label, Code_inter', 'Selection Nation');
-- tTxtCtrlbutton:SetValue('FRA,SUI');
-- tTxtCtrlbutton:SetSelectionMode(2);	-- 1=Selection Unique, 2 = Selection Multiples 

-- toto = tTxtCtrlbutton:GetValue();  dans toto on a une chaine du style 'FRA, BEL'

function CreateTableRapport_accident();
	tResultat_Info_Tirage = sqlTable.Create("Rapport_accident");
	tResultat_Info_Tirage:AddColumn({ name = 'Code_evenement', label = 'Code_evenement', type = sqlType.LONG });
	tResultat_Info_Tirage:SetPrimary('Code_evenement');
	tResultat_Info_Tirage:SetName('Rapport_accident');
	local strCreate = tResultat_Info_Tirage:GetStringCreate(base);
	if strCreate then
		base:Query(strCreate);
	end
	ReplaceTableEnvironnement(tRapport_accident, 'Rapport_accident');
end

function CreateTableResultat_Info_Tirage();
	tResultat_Info_Tirage = sqlTable.Create("Resultat_Info_Tirage");
	tResultat_Info_Tirage:AddColumn({ name = 'Code_evenement', label = 'Code_evenement', type = sqlType.LONG });
	tResultat_Info_Tirage:AddColumn({ name = 'Code_coureur', label = 'Code_coureur', type = sqlType.CHAR, size = 15 });
	tResultat_Info_Tirage:AddColumn({ name = 'Groupe_tirage', label = 'Groupe_tirage', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'Rang_tirage', label = 'Rang_tirage', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'WCSL_points', label = 'WCSL_points', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'WCSL_rank', label = 'WCSL_rank', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'ECSL_points', label = 'ECSL_points', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'ECSL_rank', label = 'ECSL_rank', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'ECSL_30', label = 'ECSL_30', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'ECSL_overall_points', label = 'ECSL_overall_points', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'ECSL_overall_rank', label = 'ECSL_overall_rank', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'Winner_CC', label = 'Winner_CC', type = sqlType.CHAR, size = 1, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'FIS_pts', label = 'FIS_pts', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'FIS_clt', label = 'FIS_clt', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'FIS_VIT_pts', label = 'FIS_VIT_pts', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'FIS_VIT_clt', label = 'FIS_VIT_clt', type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Tirage:AddColumn({ name = 'Statut', label = 'Statut', type = sqlType.CHAR, size = 2 });
	tResultat_Info_Tirage:SetPrimary('Code_evenement, Code_coureur');
	tResultat_Info_Tirage:SetName('Resultat_Info_Tirage');
	local strCreate = tResultat_Info_Tirage:GetStringCreate(base);
	if strCreate then
		base:Query(strCreate);
	end
	ReplaceTableEnvironnement(tResultat_Info_Tirage, 'Resultat_Info_Tirage');
end

function CreateTableResultat_Info_Bibo();
	tResultat_Info_Bibo = sqlTable.Create("Resultat_Info_Bibo");
	tResultat_Info_Bibo:AddColumn({ name = "Code_evenement", label = "Code_evenement", type = sqlType.LONG });
	tResultat_Info_Bibo:AddColumn({ name = "Groupe", label = "Groupe", type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Bibo:AddColumn({ name = "Ligne", label = "Ligne", type = sqlType.LONG, style = sqlStyle.NULL });
	tResultat_Info_Bibo:AddColumn({ name = "Table1", label = "Table1", type = sqlType.CHAR, size = 250, style = sqlStyle.NULL });
	tResultat_Info_Bibo:AddColumn({ name = "Table2", label = "Table2", type = sqlType.CHAR, size = 250, style = sqlStyle.NULL });
	tResultat_Info_Bibo:SetPrimary("Code_evenement, Groupe, Ligne");
	tResultat_Info_Bibo:SetName('Resultat_Info_Bibo');
	local strCreate = tResultat_Info_Bibo:GetStringCreate(base);
	if strCreate then
		base:Query(strCreate);
	end
	ReplaceTableEnvironnement(tResultat_Info_Bibo, 'Resultat_Info_Bibo');
end

function SortTable2(array)	-- tri des tables 
	table.sort(array, function (u,v)
		return 
			 u['Clt'] < v['Clt'];
	end)
end

function Shuffle(t, seed)
	if seed == true then
		math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
		--math.randomseed(os.time())
		math.random(); math.random(); math.random();
	end
    for i = 1, #t - 1 do
        local r = math.random(i, #t)
        t[i], t[r] = t[r], t[i]
    end
	return t;
end

function Round(num, dec)	-- en entrée un nombre décimal, en sortie un nombre arrondi avec dec chiffres après la virgule.
	num = tonumber(num) or 0;
    return math.floor( (num * 10^dec) + 0.5) / (10^dec)
end

function ReplaceTableEnvironnement(t, name)		-- replace la table créée dans l'environnement de la base de donnée pour éviter les memory leaks
	if type(t) ~= 'userdata' then
		return;
	end
	t:SetName(name);
	if base:GetTable(name) ~= nil then
		base:RemoveTable(name);
	end
	base:AddTable(t);
end

function VerifNodePodium()
	local utf8 = true;
	local xml = app.GetPath()..'/challenge/matrice_config.xml'
	local doc_config = xmlDocument.Create(xml);
	local root = doc_config:GetRoot();
	local node = doc_config:FindFirst('root/podium');
	if node == nil then	
		node = xmlNode.Create(root, xmlNodeType.ELEMENT_NODE, "podium");
		node:SetNodeContent('0 0 255');
	end
	doc_config:SaveFile(xml);
	doc_config:Delete();
end

function OnDecodeJsonBibo(code_evenement, groupe)
	cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..code_evenement..' And Groupe = '..groupe;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	tResultat_Info_Bibo:OrderBy('Groupe, Ligne');
	local tableDossards1 = {};
	local tableDossards2 = {};
	for i = 0, tResultat_Info_Bibo:GetNbRows() -1 do
		local jsontxt1 = tResultat_Info_Bibo:GetCell('Table1', i);
		local xTable1 = table.FromStringJSON(jsontxt1);
		table.insert(tableDossards1, xTable1.Table1[1].Col2);
		
		local jsontxt2 = tResultat_Info_Bibo:GetCell('Table2', i);
		local xTable2 = table.FromStringJSON(jsontxt2);
		local identite = xTable2.Table2[1].Col1 ;
		local pts = xTable2.Table2[1].Col2 ;
		local rang_fictif = xTable2.Table2[1].Col3 ;
		local dossard = xTable2.Table2[1].Col4;
		table.insert(tableDossards2, {Identite = identite, Pts = pts, RangFictif = rang_fictif, Dossard = dossard})
	end
	return tableDossards1, tableDossards2;
end

function OnEncodeJsonBibo(code_evenement, groupe)
	-- tResultat_Copy contient tous les coureurs du BIBO
	if not groupe or groupe == 1 then
		local cmd = 'Delete From Resultat_Info_Bibo Where Code_evenement = '..code_evenement;
		base:Query(cmd);
	end
	local cmd = 'Select * From Resultat_Info_Bibo Where Code_evenement = '..code_evenement;
	base:TableLoad(tResultat_Info_Bibo, cmd);
	local row_groupe = nil;
	assert(tTableTirage1:GetNbRows() > 0);
	for row = 0, tTableTirage1:GetNbRows() -1 do
		local idx = row + 1;
		local tTable1 = {};
		local tTable2 = {};
		table.insert(tTable1, {Col1 = 'Dossard du rang fictif '..idx, Col2 = params.tableDossards1[idx]});
		local xTable1 = {Table1 = tTable1};
		local jsontxt1 = table.ToStringJSON(xTable1, false);
		
		local rang_fictif = tTableTirage1:GetCellInt('Row', row);
		local code_coureur = '';
		local identite = '';
		local pts = '';
		local dossard = params.tableDossards1[rang_fictif] or '';
		code_coureur = tDrawG6:GetCell('Code_coureur', row);
		identite = tDrawG6:GetCell('Nom', row)..' '..tDrawG6:GetCell('Prenom', row);
		pts = tDrawG6:GetCellDouble('Point', row);
		local col1 = identite;
		local col2 = pts;
		local col3 = rang_fictif;
		local col4 = dossard;
		table.insert(tTable2, {Col1 = col1, Col2 = col2, Col3 = col3, Col4 = col4});
		local xTable2 = {Table2 = tTable2};
		local jsontxt2 = table.ToStringJSON(xTable2, false);
		local rowsql = tResultat_Info_Bibo:AddRow();
		tResultat_Info_Bibo:SetCell('Code_evenement', rowsql, params.code_evenement);
		if not groupe then
			tResultat_Info_Bibo:SetCell('Groupe', rowsql, 1);
		else
			tResultat_Info_Bibo:SetCell('Groupe', rowsql, groupe);
		end
		if params.debug then
			adv.Alert('OnEncodeJson groupe '..tostring(groupe)..' - row : '..row..', jsontxt1 '..jsontxt1..'\t'..', jsontxt2 = '..jsontxt2);
		end
		tResultat_Info_Bibo:SetCell('Ligne', rowsql, idx);
		tResultat_Info_Bibo:SetCell('Table1', rowsql, jsontxt1);
		tResultat_Info_Bibo:SetCell('Table2', rowsql, jsontxt2);
		base:TableInsert(tResultat_Info_Bibo, rowsql);
	end
end


function Eval(e1, e2)
	if e1 == e2 then
		return true;
	else
		return false;
	end
end

function CreateXMLConfig()
	local utf8 = true;
	local doc_config = xmlDocument.Create();
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "root");
	if doc_config:SetRoot(nodeRoot) == false then
		return;
	end
	if not nodeRoot then
		return;
	end
	nodeRoot:AddAttribute("Titre", 'Fichier XML de configuration des couleurs des disciplines');
	
	local nodeColors = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "colors");
	local nodeSL = xmlNode.Create(nodeColors, xmlNodeType.ELEMENT_NODE, "SL", '0 255 255');
	local nodeGS = xmlNode.Create(nodeColors, xmlNodeType.ELEMENT_NODE, "GS", '255 0 255');
	local nodeGS1 = xmlNode.Create(nodeColors, xmlNodeType.ELEMENT_NODE, "GS1", '255 0 255');
	local nodeSG = xmlNode.Create(nodeColors, xmlNodeType.ELEMENT_NODE, "SG", '0 255 0');
	local nodeDH = xmlNode.Create(nodeColors, xmlNodeType.ELEMENT_NODE, "DH", '255 255 0');
	local nodeSC = xmlNode.Create(nodeColors, xmlNodeType.ELEMENT_NODE, "SC", '255 170 0');
	local nodeCS = xmlNode.Create(nodeColors, xmlNodeType.ELEMENT_NODE, "CS", '192 192 192');
	nodeRoot:AddChild(nodeColors);
	
	doc_config:SaveFile(app.GetPath()..'/challenge/matrice_config.xml');
	doc_config:Delete();

end

function TransformeCombienPG(combien,sur)
	local arcombien = {};
	local numerateur = 1;
	local denominateur = 1;
	local retour = 0;
	if string.find(combien,'/') then	-- on a une fraction ex : 2/3
		arcombien = combien:Split('/');
		numerateur = tonumber(arcombien[1]) or 0;
		denominateur = tonumber(arcombien[2]) or 1;
		retour = math.ceil(Round(numerateur * sur / denominateur, 0));
		if retour < 1 then retour = 1; end
	elseif string.find(combien, '%%') then				-- on a un pourcentage 75% -> 75/100
		combien = string.gsub(combien, "%D", "");
		combien = tonumber(combien) or 0;
		retour = math.ceil(Round(sur * combien / 100, 0));
		if retour < 1 then retour = 1; end
	else
		retour = tonumber(combien) or 0;
		if retour < 1 then retour = 1; end
		retour = combien;
	end
	retour = tonumber(retour) or 1;
	return retour;
end

function GetDisciplines(Table_critere)
	local arDiscipline = {};
	local sur = 0;
	for i = 0, tMatrice_Courses:GetNbRows() -1 do
		local discipline = tMatrice_Courses:GetCell('Code_discipline', i);
		if #arDiscipline == 0 then
			table.insert(arDiscipline, {Discipline = discipline, Combien = 0, Sur = 0});
		end
		local ajouter = true;
		for j = 1, #arDiscipline do
			if arDiscipline[j].Discipline == discipline then
				arDiscipline[j].Sur = arDiscipline[j].Sur + 1;
				ajouter = false;
			end
		end
		if ajouter == true then
			table.insert(arDiscipline, {Discipline = discipline, Combien = 0, Sur = 1, FontColor = font_color});
		end	
	end
		-- Course|1|SG|au maximum|50%sur9
	for i = 1, #Table_critere do
		local arTableCritere = Table_critere[i].Critere:Split('|');
		for j = 1, #arDiscipline do
			if arTableCritere[3]:find(arDiscipline[j].Discipline) then
				if arTableCritere[5]:find('sur') then		-- 5 sur 9
					local arsur = arTableCritere[5]:Split('sur');
					arDiscipline[j].Sur = tonumber(arsur[2]) or 1;
					arsur[1] = TransformeCombienPG(arsur[1], arsur[2]);
					arDiscipline[j].Combien = arsur[1];
				else
					arDiscipline[j].Combien = TransformeCombienPG(arTableCritere[5],arDiscipline[j].Sur);
					if arDiscipline[j].Combien > arDiscipline[j].Sur then
						arDiscipline[j].Combien = arDiscipline[j].Sur;
					end
				end
			end
		end
	end
	return arDiscipline;
end


function ParseCriterex(tableau,idxcritere)
	tableau.NbCombien = TransformeCombienPG(tableau.NbCombien, tableau.Sur);
	return  tableau.Critere, tableau.TypeCritere, tableau.Item, tableau.Bloc, tableau.Discipline, tableau.Prendre, tableau.Combien, tableau.NbCombien, tableau.Sur;
end

function GetValuePG(cle, defaultValue)	-- Lecture d'une valeur dans la table Evenement_Matrice avec lecture d'une valeur par défaut dans le XML et retour de la valeur lue ou de la valeur par défaut
	local valretour = defaultValue;
	local r = tEvenement_Matrice:GetIndexRow('Cle', cle);
	if r >= 0 then
		valretour = tEvenement_Matrice:GetCell('Valeur', r);
	end
	return valretour;
end

function AnalysePerformances(code_evenement)
	ColAlign = {};
	local chaine = GetValuePG('Sexe_align', 'center');
	SetAlignCol('Sexe_align', chaine)
	chaine = GetValuePG('Nation_align', 'center');
	SetAlignCol('Nation', chaine)
	chaine = GetValuePG('Comite_align', 'center');
	SetAlignCol('Comite', chaine)
	chaine = GetValuePG('An_align','center');
	SetAlignCol('An', chaine)
	chaine = GetValuePG('Categ_align', 'center');
	SetAlignCol('Categ', chaine);
	local entite = GetValuePG('comboEntite','FFS');
	lignegauche = 0;
	local cmd = 'Select * From Evenement_Matrice Where Code_evenement = '..code_evenement.." And Cle Like '%analyseGauche%' Order By Cle";
	base:TableLoad(tEvenement_Matrice,cmd);
	arAnalyse = {};
	local idxcritere = nil;
	local faire = nil;
	local premiers = nil;
	local discipline = nil;
	local what = nil;
	local reg = '([^OU|ET]+)';
	for i = 1, 10 do
		local analyseGauche = GetValuePG('analyseGauche'..i, '');	-- 1,30,Technique
		if analyseGauche:len() > 0 then
			idxcritere = i;
			local tcritere = {};
			if not string.find(analyseGauche, 'ET') and not string.find(analyseGauche, 'OU') then
				local t = analyseGauche:Split(',');
				faire = tonumber(t[1]) or 0;
				premiers = tonumber(t[2]) or 0;
				discipline = t[3];
				if discipline == '*' then 
					what = "Avoir fait "..faire..' fois dans les '..premiers..' toutes disciplines confondues';
				else
					what = "Avoir fait "..faire..' fois dans les '..premiers..' en '..discipline;
				end					
				table.insert(tcritere, {Faire = faire, Premiers = premiers, Discipline = discipline, Rempli = 0});
				table.insert(arAnalyse, {idxcritere = idxcritere, Rempli = 0, Etou = nil, Criteres = tcritere, String = what});
			else
				if string.find(analyseGauche, 'ET') then
					etou = 'ET';
				else
					etou = 'OU';
				end
				table.insert(arAnalyse, {idxcritere = idxcritere, Rempli = 0, Etou = etou, Criteres = {}});
				local arChaine = analyseGauche:Split(etou);
				for i = 1, #arChaine do
					local chaine = arChaine[i];
					local t = chaine:Split(',');
					faire = tonumber(t[1]) or 0;
					premiers = tonumber(t[2]) or 0;
					discipline = t[3];
					if discipline == '*' then 
						whichdiscipline = 'toutes disciplines';
					else
						whichdiscipline = discipline;
					end					
					if not what then
						what = "Avoir fait "..faire..' fois dans les '..premiers..' en '..whichdiscipline;
					else
						what = what..' '..etou..' avoir fait '..faire..' fois dans les '..premiers..' en '..whichdiscipline;
					end
					table.insert(tcritere, {Faire = faire, Premiers = premiers, Discipline = discipline, Rempli = 0});
				end
				arAnalyse[idxcritere].Criteres = tcritere;
				arAnalyse[idxcritere].String = what;
			end
		end
	end
	for row = 0, body:GetNbRows() -1 do
		-- on initialise toutes les données des critères à chaque coureur
		local bolAnalyseFaite = false;
		for i = 1, #arAnalyse do
			arAnalyse[i].Rempli = 0;
			for j = 1, #arAnalyse[i].Criteres do
				arAnalyse[i].Criteres[j].Rempli = 0;
			end
			-- on trie les courses selon le classement.
			tData = {};
			-- if row == 0 then
				-- tMatrice_Courses:Snapshot('Matrice_Courses_functionPG.db3');
			-- end
			for idxcourse = 1, tMatrice_Courses:GetNbRows() do	-- on parcourt toutes les courses
				local clt = body:GetCellInt('Clt'..idxcourse, row, -1);	-- classement dans la course
				discipline = tMatrice_Courses:GetCell('Code_discipline',idxcourse-1);
				table.insert(tData, {Clt = clt, Ordre = idxcourse, Discipline = discipline});
			end
			SortTable2(tData, {'Clt'});	-- les courses sont triées par classement indépendamment de la discipline
			for idxcritere = 1, #arAnalyse do		-- on parcourt tous les critères et les sous-criteres
				if bolAnalyseFaite == true then
					break;
				end
				local etou = arAnalyse[idxcritere].Etou;	-- etou peut être = nil, ET, OU
				local tcritere = arAnalyse[idxcritere].Criteres;
				for idx = 1, #tcritere do
					criterex = tcritere[idx];
					criterex.compteur = 0;
					local faire = criterex.Faire;
					local premiers = criterex.Premiers;
					local discipline = criterex.Discipline;
					for i = 1, #tData do
						if discipline == 'Vitesse' then
							if tData[i].Discipline:In('SG','DH') then
									tData[i].Discipline = 'Vitesse';
							end
						end
						if discipline == 'Technique' then
							if tData[i].Discipline:In('GS','SL') then
								tData[i].Discipline = 'Technique';
							end
						end
						if tData[i].Clt > 0 and discipline == tData[i].Discipline and tData[i].Clt <= premiers then
							if discipline == '*' then
								criterex.compteur = criterex.compteur + 1;
							elseif tData[i].Discipline == discipline then
								criterex.compteur = criterex.compteur + 1;
							end
							if criterex.compteur > 0 and criterex.compteur >= faire then
								body:SetCell('Analyse'..idxcritere, row, criterex.compteur);
							end
						end
					end
					if criterex.compteur >= faire then
						criterex.Rempli = 1;
						arAnalyse[idxcritere].Rempli = arAnalyse[idxcritere].Rempli + 1;
					end
				end
				if etou and etou == 'ET' then
					if arAnalyse[idxcritere].Rempli < #tcritere then
						arAnalyse[idxcritere].Rempli = 0;
					end
				end
				if arAnalyse[idxcritere].Rempli > 0 then
					body:SetCell('Analyse_groupe', row, idxcritere);
					bolAnalyseFaite = true;
					break;
				end
			end
		end
	end
	body:OrderBy('Analyse_groupe, Analyse1 DESC, Analyse2 DESC, Analyse3 DESC, Analyse4 DESC, Analyse5 DESC, Pts_inscription');
	-- body:Snapshot('body.db3');
end

function EvaluateVal(val, tps)
	local num = tonumber(val) or 0;
	if tps == true then 
		if num == 0 then
			num = 1000000;
		end
		if num < 1000000 then
			val = app.TimeToString(num * 1000, '%-1h%-1m%2s.%2f')
			if string.sub(val, 1,1) == '0' then
				val = string.sub(val, 2);
			end
		end
		return val;
	elseif num > 10000 then
		val = '-1';
	end
	if string.sub(val, 1,1) == '0' then
		val = string.sub(val, 2);
	end
	if string.find(val, '-') then
		val = '';
	elseif string.find(val, '.') then
		if string.sub(val, -3) == '.00' then
			val = string.sub(val, 1, -4);
		-- elseif string.sub(val, -1) == '0' then
			-- val = string.sub(val, 1, -2);
		end
	elseif num == 0 then
		val = '0';
	end
	return val;
end

function EvaluatePts(row, idxcourse, colpts, abddsq)
	if not idxcourse or arCourses[idxcourse].Discipline == 'CS' then	-- Pts total la matrice pour le row
		local pts = body:GetCellDouble(colpts, row);
		if pts >=0 then
			if math.floor(pts) == pts then
				pts = math.floor(pts);
			end	
			return pts;
		else
			return '';
		end
	end
	arCourses[idxcourse].Prendre = tMatrice_Courses:GetCell('Prendre', idxcourse-1);
	local prendre = arCourses[idxcourse].Prendre;
	local coltps = string.gsub(colpts, 'Pts', 'Tps');
	local tps = body:GetCellInt(coltps, row);
	local txt_tps = body:GetCell(coltps, row);
	local pts = body:GetCellDouble(colpts, row, -1);
	if math.floor(pts) == pts then
		pts = math.floor(pts);
	end	
	local run_best = body:GetCellInt('Run'..idxcourse..'_best', row);
	if string.find(prendre, '1') or string.find(prendre, '2') then
		if tps > 0 then
			return pts;
		elseif tps == -500 or tps == -800 then
			if abddsq == 'Oui' then
				return txt_tps;
			else
				return '';
			end
		end
	else	-- Ptstotal
		if run_best > 0 then
			if pts >= 0 then
				return pts;
			else
				return '';
			end
		elseif tps == -500 or tps == -800 then
			if abddsq == 'Oui' then
				return txt_tps;
			else
				return '';
			end
		end
	end
	return '';
end

function EvaluateClt(clt)
	if clt > 0 then
		return clt;
	else
		return '';
	end
end

function EvaluateDiff(diff)		-- 2454 -> 2.45, 
	if diff > 0 then
		diff = Round(diff / 1000, 2);
		return string.format('%.2f',diff);
	else
		return '';
	end
end

-- EvaluateTps(row, 'Tps'..idxcourse, params.AbdDsq)
function EvaluateTps(row, coltps, abddsq, quoi)
	local retour = nil;
	local tps = body:GetCellInt(coltps, row, -600);
	local txt_tps = body:GetCell(coltps, row);
	if tps > 0 then
		return txt_tps;
	elseif abddsq == 'Non' then
		return '';
	else
		return txt_tps;
	end
	return '';
end

function InitColorDiscipline()
	base = base or sqlBase:Clone();
	tDiscipline = base:GetTable('Discipline');
	colorDiscipline = {};
	local doc = xmlDocument.Create(app.GetPath().."/challenge/matrice_config.xml");
	local nodecle = doc:FindFirst('root/colors');	-- on va chercher les valeurs par défaut des variables des couleurs des disciplines
	if nodecle then
		for i = 0, tDiscipline:GetNbRows() -1 do
			local discipline = tDiscipline:GetCell('Code', i);
			local nodecle = doc:FindFirst('root/colors/'..discipline);	-- on va chercher les valeurs par défaut des variables des couleurs des disciplines
			if nodecle then
				background = 'rgb '..nodecle:GetNodeContent();
			else
				background = 'rgb 255 255 255';
			end
			colorDiscipline[discipline] = background;
		end
	end
	doc:Delete();
	return colorDiscipline;
end

function InitColorPodium()
	local colorpodium = 'rgb 255 0 0';
	local doc = xmlDocument.Create(app.GetPath().."/challenge/matrice_config.xml");
	local node = doc:FindFirst('root/podium');
	if node then
		colorpodium = 'rgb '..node:GetNodeContent();
	end
	doc:Delete();
	return colorpodium;
end

function GetAlignCol(col, val)
	align = 'center';
	if type(ColAlign[col]) == 'table' and type(ColAlign[col][val]) == 'string' then
		align = ColAlign[col][val];
	end
	return align;
end

function SetAlignCol(col, chaine)
	ColAlign[col] = {};
	local tchaine = chaine:Split('|');		-- Ex : 2003,right|2002,left 
	for i = 1, #tchaine do					--> 2003,right
		local tval = tchaine[i]:Split(',');	-- tval[1] = 2003, tval[2] = right
		local valeur = tostring(tval[1]);
		ColAlign[col][valeur] = tval[2];
	end
end

function GetSetDiscipline(i)
	local idxcourse = i + 1;
	local nbdisc = 0;
	local retour_discipline = '';
	local retour_diffrun = '';
	local discipline = tMatrice_Courses:GetCell('Code_discipline', i);
	local bloc = tMatrice_Courses:GetCellInt('Bloc', i)
	local nombre_de_manche = tMatrice_Courses:GetCellInt('Nombre_de_manche', i);
	local coefPourcentageMaxiBloc1 = GetValuePG('coefPourcentageMaxiBloc1', '0');
	local coefPourcentageMaxiBloc2 = GetValuePG('coefPourcentageMaxiBloc2', '0');
	local retour_diff = ' Diff maxi : '..Round(tMatrice_Courses:GetCellInt('Diff_maxi', i) / 1000, 2);	--1745 -> 1.75
	if prnColonne.Diff[idxcourse].Imprimer == 0 then
		retour_diff = '';
	end
	for j = 0, tMatrice_Courses:GetNbRows() -1 do
		if tMatrice_Courses:GetCell('Code_discipline', j) == discipline then
			if j <= i then
				nbdisc = nbdisc + 1;
				retour_discipline = nbdisc;
			end
			for j = 1, nombre_de_manche do
				if j == 1 then
					retour_diffrun = ' ('..Round(tMatrice_Courses:GetCellInt('Diff_maxi_m'..j, i) / 1000, 2);
				else
					retour_diffrun = retour_diffrun..','..Round(tMatrice_Courses:GetCellInt('Diff_maxi_m'..j, i) / 1000, 2);
				end
			end
			retour_diffrun = retour_diffrun..')';
		end
		if prnColonne.Diffrun[(i+1)].Imprimer == 0 then
			retour_diffrun = '';
		end
	end
	if bloc == 1 and tonumber(coefPourcentageMaxiBloc1) == 0 then
		retour_diff = '';
		retour_diffrun = '';
	end
	if bloc == 2 and tonumber(coefPourcentageMaxiBloc2) == 0 then
		retour_diff = '';
		retour_diffrun = '';
	end
	if retour_diff:len() > 0 or retour_diffrun:len() > 0 then
		retour_discipline = retour_discipline..'-';
	end
	return retour_discipline..retour_diff..retour_diffrun;
end

function GetSetNumCourse(i)
	local nbdisc = 0;
	local retour = '';
	local discipline = tMatrice_Courses:GetCell('Code_discipline', i);
	for j = 0, tMatrice_Courses:GetNbRows() -1 do
		if j > i then
			break;
		end
		if tMatrice_Courses:GetCell('Code_discipline', j) == discipline then
			nbdisc = nbdisc + 1;
			retour = nbdisc;
		end
	end
	return retour;
end

function InitPrnColonnes()
	tMatrice_Courses = base:GetTable('_Matrice_Courses');
	ImprimerColonnes = GetValuePG('imprimerColonnes', 'Code_coureur,Code,center,1|Identite,Identité,left,1|Sexe,S.,center,0|An,An,center,1|Categ,Cat.,center,1|Nation,Nat.,center,0|Comite,CR,center,1|Club,Club,left,1|Groupe,Groupe,left,0|Equipe,Equipe,left,0|Critere,Critère,left,0|Liste1,Liste,center,0|Liste2,Liste,center,0|Delta,Delta,center,0');
	PrendreBloc1 = GetValuePG('comboPrendreBloc1', '1.Classement général');
	ImprimerBloc1 = GetValuePG('imprimerBloc1', 'Clt,0|Tps,0|Diff,0|Pts,1|Cltrun,0|Tpsrun,0|Diffrun,0|Ptsrun,0|Ptstotal,0|EtapeClt,0|EtapePts,0');
	PrendreBloc2 = GetValuePG('comboPrendreBloc2', '1.Classement général');
	ImprimerBloc2 = GetValuePG('imprimerBloc2', 'Clt,0|Tps,0|Diff,0|Pts,1|Cltrun,0|Tpsrun,0|Diffrun,0|Ptsrun,0|Ptstotal,0');
	ImprimerCombiSaut = GetValuePG('imprimerCombiSaut', 'Cltcs,1|Lng_saut,1|Clt_saut,1|Pts_saut,1|Tps_alpin,1|Clt_alpin,1|Pts_alpin,1|Ptstotalcs,1');
	row1haut = false;
	ColAlign = {};
	local chaine = GetValuePG('Sexe_align', '');
	if chaine:len() > 0 then
		SetAlignCol('Sexe_align', chaine);
	end
	chaine = GetValuePG('Nation_align', '');
	if chaine:len() > 0 then
		SetAlignCol('Nation', chaine);
	end
	chaine = GetValuePG('Comite_align', '');
	if chaine:len() > 0 then
		SetAlignCol('Comite', chaine);
	end
	chaine = GetValuePG('An_align','');
	if chaine:len() > 0 then
		SetAlignCol('An', chaine);
	end
	chaine = GetValuePG('Categ_align', '');
	if chaine:len() > 0 then
		SetAlignCol('Categ', chaine);
	end
	
	-- Ex ImprimerColonnes = Code_coureur,Code,center,1|Identite,Identité,left,1|Sexe,S.,center,1|An,An,center,1|Categ,Cat.,center,0|Nation,Nat.,center,0|Comite,CR,center,0|Club,Club,left,0|Groupe,Groupe,left,0|Equipe,Equipe,left,0|Critere,Critère,left,0|Liste1,Liste,center,0|Liste2,Liste,center,0|Delta,Delta,center,0
	tColCoureur = ImprimerColonnes:Split('|');
	prnColonne = {};
	colstartrace = 3;
	for i = 1, #tColCoureur do
		tConfigColonnes = tColCoureur[i]:Split(',');
		local col = tConfigColonnes[1];
		local label = tConfigColonnes[2];
		local align = tConfigColonnes[3];
		local imprimer = tonumber(tConfigColonnes[4]) or 0;
		prnColonne[col] = {};
		prnColonne[col].Colonne = col;
		prnColonne[col].Label = label;
		prnColonne[col].Align = align;
		prnColonne[col].Imprimer = imprimer;
		if imprimer > 0 then
			colstartrace = colstartrace + 1;
		end
	end
	-- bloc1 : Clt,0,|Tps,0,|Diff,0,|Pts,1,|Cltrun,0,|Tpsrun,0,|Diffrun,0,|Ptsrun,1,|Ptstotal,1,|EtapeClt,0,|EtapePts,0,
	prnBloc1 = {};
	prnBloc2 = {};
	prnCombiSaut = {};
	tColBloc1 = ImprimerBloc1:Split('|');
	for i = 1, #tColBloc1 do
		tConfigColonnes = tColBloc1[i]:Split(',');
		if #tConfigColonnes < 3 then table.insert(tConfigColonnes, tConfigColonnes[1]); end
		local col = tConfigColonnes[1];
		local label = tConfigColonnes[3];
		if string.find(label, 'run') then label = 'M'; end
		label = string.gsub(label, 'Ptstotal', 'Total');
		label = string.gsub(label, 'Etape', '');
		local imprimer = tonumber(tConfigColonnes[2]) or 0;
		prnBloc1[col] = {};
		prnBloc1[col].Label = label;
		prnBloc1[col].Imprimer = imprimer;
		prnColonne[col] = prnColonne[col] or {};
		for j = 1, tMatrice_Courses:GetNbRows() do
			prnColonne[col][j] = {};
		end
	end
	prnBloc2 = {};
	tColBloc2 = ImprimerBloc2:Split('|');
	for i = 1, #tColBloc2 do
		tConfigColonnes = tColBloc2[i]:Split(',');
		local col = tConfigColonnes[1];
		local imprimer = tonumber(tConfigColonnes[2]) or 0;
		prnBloc2[col] = {};
		prnBloc2[col].Label = prnBloc1[col].Label;
		prnBloc2[col].Imprimer = imprimer;
	end
	
	-- ImprimerCombiSaut : Cltcs,1|Lng_saut,1|Clt_saut,1|Pts_saut,1|Tps_alpin,1|Clt_alpin,1|Pts_alpin,1|Ptstotalcs,1
	tColCombiSaut = ImprimerCombiSaut:Split('|');
	for i = 1, #tColCombiSaut do
		tConfigColonnes = tColCombiSaut[i]:Split(',');
		local col = tConfigColonnes[1];
		local imprimer = tonumber(tConfigColonnes[2]) or 0;
		prnCombiSaut[col] = {};
		prnCombiSaut[col].Label = col;
		prnCombiSaut[col].Imprimer = imprimer;
	end
	prnCombiSaut.Cltcs.Label = 'Clt';
	prnCombiSaut.Lng_saut.Label = 'Lng';
	prnCombiSaut.Clt_saut.Label = 'C.Saut';
	prnCombiSaut.Pts_saut.Label = 'P.Saut';
	prnCombiSaut.Tps_alpin.Label = 'Tps';
	prnCombiSaut.Clt_alpin.Label = 'Clt';
	prnCombiSaut.Pts_alpin.Label = 'Pts';
	prnCombiSaut.Ptstotalcs.Label = 'Tot.';
	bloc1_last = 0;
	local nbcol_body = 0;
	local col_start =  colstartrace ;
	arCourses = {};
	prnColonne.Clt.Label = prnBloc1['Clt'].Label;
	prnColonne.Tps.Label = prnBloc1['Tps'].Label;
	prnColonne.Diff.Label = prnBloc1['Diff'].Label;
	prnColonne.Pts.Label = prnBloc1['Pts'].Label;
	prnColonne.Cltrun.Label = prnBloc1['Cltrun'].Label;
	prnColonne.Tpsrun.Label = prnBloc1['Tpsrun'].Label;
	prnColonne.Diffrun.Label = prnBloc1['Diffrun'].Label;
	prnColonne.Ptsrun.Label = prnBloc1['Ptsrun'].Label;
	prnColonne.Ptstotal.Label = prnBloc1['Ptstotal'].Label;
	prnColonne.EtapeClt.Label = prnBloc1['EtapeClt'].Label;
	prnColonne.EtapePts.Label = prnBloc1['EtapePts'].Label;
	local bloc2_existe = false;
	local etape_ajoutee = false;
	for i = 0, tMatrice_Courses:GetNbRows() -1 do
		local idxcourse = i + 1;
		local bloc = tMatrice_Courses:GetCellInt('Bloc', i);
		local discipline = tMatrice_Courses:GetCell('Code_discipline', i);
		if bloc == 2 then
			bloc2_existe = true;
		end
		local prnBlocx = {};
		if discipline ~= 'CS' then
			if bloc == 1 then
				prnBlocx = prnBloc1;
			else
				prnBlocx = prnBloc2;
			end
		else
			prnBlocx = prnCombiSaut;
		end

		if bloc == 1 then
			bloc1_last = i; 
		end
		local nb_run = tMatrice_Courses:GetCellInt('Nombre_de_manche', i);
		local prendre = tMatrice_Courses:GetCell('Prendre', i);
		local nbcol_course = 0;
	-- bloc1 : Clt,1|Tps,1|Diff,1|Pts,1|Cltrun,1|Tpsrun,1|Diffrun,1|Ptsrun,1|Ptstotal,1|EtapeClt,0|EtapePts
		if discipline ~= 'CS' then
			if string.find(prendre, 'à') then
				prnBlocx.Pts.Imprimer = 0;
				prnBlocx.Ptstotal.Imprimer = 0;
				prnBlocx['Ptsrun'].Imprimer = 1;
			end
			if string.find(prendre, 'Idem') then
				prnBlocx.Ptstotal.Imprimer = 0;
				prnBlocx.Pts.Imprimer = 1;
			end

			prnColonne.Clt[idxcourse].Imprimer = prnBlocx['Clt'].Imprimer;
			prnColonne.Tps[idxcourse].Imprimer = prnBlocx['Tps'].Imprimer;
			prnColonne.Diff[idxcourse].Imprimer = prnBlocx['Diff'].Imprimer;
			prnColonne.Pts[idxcourse].Imprimer = prnBlocx['Pts'].Imprimer;
			prnColonne.Cltrun[idxcourse].Imprimer = prnBlocx['Cltrun'].Imprimer;
			prnColonne.Tpsrun[idxcourse].Imprimer = prnBlocx['Tpsrun'].Imprimer;
			prnColonne.Diffrun[idxcourse].Imprimer = prnBlocx['Diffrun'].Imprimer;
			prnColonne.Ptsrun[idxcourse].Imprimer = prnBlocx['Ptsrun'].Imprimer;
			prnColonne.Ptstotal[idxcourse].Imprimer = prnBlocx['Ptstotal'].Imprimer;
			if nb_run == 1 then
				if prnColonne.Cltrun[idxcourse].Imprimer == 1 then
					prnColonne.Cltrun[idxcourse].Imprimer = 0;
					prnColonne.Clt[idxcourse].Imprimer = 1;
				end
				if prnColonne.Tpsrun[idxcourse].Imprimer == 1 then
					prnColonne.Tpsrun[idxcourse].Imprimer = 1;
					prnColonne.Tps[idxcourse].Imprimer = 0;
				end
				if prnColonne.Diffrun[idxcourse].Imprimer == 1 then
					prnColonne.Diffrun[idxcourse].Imprimer = 0;
					prnColonne.Diff[idxcourse].Imprimer = 1;
				end
				if prnColonne.Ptsrun[idxcourse].Imprimer == 1 then
					prnColonne.Ptsrun[idxcourse].Imprimer = 0;
					prnColonne.Pts[idxcourse].Imprimer = 1;
				end
				if prnBlocx.Ptstotal.Imprimer == 1 then
					prnColonne.Pts[idxcourse].Imprimer = 0;
				end
			end
	-- bloc1 : Clt,0|Tps,0|Diff,0|Pts,1|Cltrun,0|Tpsrun,0|Diffrun,0|Ptsrun,1|Ptstotal,1	/ EtapeClt,0|EtapePts,0
			nbcol_course = prnColonne.Clt[idxcourse].Imprimer + prnColonne.Tps[idxcourse].Imprimer + prnColonne.Diff[idxcourse].Imprimer + prnColonne.Pts[idxcourse].Imprimer + (prnColonne.Cltrun[idxcourse].Imprimer * nb_run) + (prnColonne.Tpsrun[idxcourse].Imprimer * nb_run) + (prnColonne.Diffrun[idxcourse].Imprimer * nb_run) + (prnColonne.Ptsrun[idxcourse].Imprimer * nb_run) + prnColonne.Ptstotal[idxcourse].Imprimer;
			tMatrice_Courses:SetCell('Nb_col', i, nbcol_course);
		else
	-- combisaut : Cltcs,1|Lng_saut,1|Clt_saut,1|Pts_saut,1|Tps_alpin,1|Clt_alpin,1|Pts_alpin,1|Ptstotalcs,1
			nbcol_course = prnCombiSaut.Cltcs.Imprimer + prnCombiSaut.Lng_saut.Imprimer + prnCombiSaut.Clt_saut.Imprimer + prnCombiSaut.Pts_saut.Imprimer + prnCombiSaut.Tps_alpin.Imprimer + prnCombiSaut.Clt_alpin.Imprimer + prnCombiSaut.Pts_alpin.Imprimer + prnCombiSaut.Ptstotalcs.Imprimer +1;
			tMatrice_Courses:SetCell('Nb_col', i, nbcol_course);
		end
		if nbcol_course <= 4 then
			row1haut = true;
		end
		table.insert(arCourses, {Discipline = discipline, Nb_col = tMatrice_Courses:GetCellInt('Nb_col', i), Nb_run = tMatrice_Courses:GetCellInt('Nombre_de_manche', i), Prendre = tMatrice_Courses:GetCell('Prendre', i)});
		tMatrice_Courses:SetCell('Col_start', i, col_start);
		col_start = col_start + nbcol_course;
		if bloc == 2 then
			if etape_ajoutee == false then
				col_start = col_start + prnBloc1['EtapeClt'].Imprimer + prnBloc1['EtapePts'].Imprimer;
				tMatrice_Courses:SetCell('Col_start', i, tMatrice_Courses:GetCellInt('Col_start', i) + prnBloc1['EtapeClt'].Imprimer + prnBloc1['EtapePts'].Imprimer);
				etape_ajoutee = true;
			end
		end
	end
	if bloc2_existe == false then
		prnBloc1['EtapeClt'].Imprimer = 0;
		prnBloc1['EtapePts'].Imprimer = 0;
	end
	tMatrice_Courses:Snapshot('Matrice_Courses.db3');
end

function GetRowEquipier(code_coureur)
	local r = tRanking:GetIndexRow('Code_coureur', code_coureur); 
	return r;
end

function GetEquipierData(col, row)
	return tRanking:GetCell(col, row);
end

function InitRegroupement(code_evenement)
	Evenement = base:GetTable('Evenement');
	base:TableLoad(Evenement, 'Select * From Evenement Where Code = '..code_evenement);
	tRanking = base.CreateTableRanking({ code_evenement = code_evenement});
end

function ResetDates(code_evenement);
	do return end
	local cmd = 'Select * from Epreuve Where Code_evenement = '..code_evenement;
	base:TableLoad(tEpreuve, cmd);
	date_epreuve = tEpreuve:GetCell('Date_epreuve', 0,'%2D.%2M.%4Y');
	date_depart_defaut = tEpreuve:GetCell('Date_epreuve', 0,'%2D-%2M-%4Y');
	date_calendrier_update = tEpreuve:GetCell('Date_calendrier', 0,'%4Y-%2M-%2D');
	if date_calendrier_update:len() == 0 then 
		date_calendrier_update = tEpreuve:GetCell('Date_epreuve', 0,'%4Y-%2M-%2D')
		tEpreuve:SetCell('Date_calendrier', 0, date_calendrier_update);
	end
	date_epreuve_update = tEpreuve:GetCell('Date_epreuve', 0,'%4Y-%2M-%2D');
	arDate = tEpreuve:GetCell('Date_epreuve', 0):Split('/');
	local t1 = os.time( { year = arDate[3], month = arDate[2], day = arDate[1] } );
	local t2 = t1 - (3600*24);
	date_arrivee_default = os.date("%d.%m.%Y", t2);
	date_arrivee_update = os.date("%Y-%m-%d", t2);
	local cmd = 'Select * From Evenement_officiel Where Code_evenement = '..code_evenement;
	base:TableLoad(tEvenement_Officiel, cmd)
	for i = 0, tEvenement_Officiel:GetNbRows() -1 do
		if tEvenement_Officiel:GetCell('Date_arrivee', i):len() == 0 then
			tEvenement_Officiel:SetCell('Date_arrivee', i, date_arrivee_update);
		end
		if tEvenement_Officiel:GetCell('Date_depart', i):len() == 0 then
			tEvenement_Officiel:SetCell('Date_depart', i, date_calendrier_update);
		end
	end
	base:TableBulkUpdate(tEvenement_Officiel);
	local cmd = 'Select * From Resultat Where Code_evenement = '..code_evenement;
	base:TableLoad(tResultat, cmd)
	for i = 0, tResultat:GetNbRows() -1 do
		if tResultat:GetCell('Info', i):len() == 0 then
			tResultat:SetCell('Info', i, date_arrivee_default);
		end
		if tResultat:GetCell('Niveau', i):len() == 0 then
			tResultat:SetCell('Niveau', i, date_calendrier_update);
		end
	end
	base:TableBulkUpdate(tResultat);
end

function GetOfficiel(code_evenement, fonction, data_complete, return_table)
	-- s'il n'y a qu'un seul record dans Evenement_Officiel, valeurs de data_complete : false --> identité seule, true --> toutes les données de la table
	-- si return_table == true, on retourne la table et l'identité
	data = '';
	Evenement_Officiel = base:GetTable('Evenement_Officiel');
	local cmd = 'Select * from Evenement_Officiel Where Code_evenement = '..code_evenement..' And Fonction = "'..fonction..'"';
	base:TableLoad(Evenement_Officiel, cmd);
	if Evenement_Officiel:GetNbRows() == 1 then
		data = Evenement_Officiel:GetCell('Prenom', 0)..' '..Evenement_Officiel:GetCell('Nom', 0):upper();
		if data_complete == true then
			if Evenement_Officiel:GetCell('Tel_mobile', 0) ~= '' then
				data = data..'\n'..'Mobile :'..Evenement_Officiel:GetCell('Tel_mobile', 0);
			elseif Evenement_Officiel:GetCell('Tel_fixe', 0) ~= '' then
				data = data..'\n'..'Tel :'..Evenement_Officiel:GetCell('Tel_fixe', 0);
			end
			if Evenement_Officiel:GetCell('Email', 0) ~= '' then
				data = data..'\n'..'Mail :'..Evenement_Officiel:GetCell('Email', 0);
			end
			if Evenement_Officiel:GetCell('Adresse1', 0) ~= '' then
				data = data..'\n'..Evenement_Officiel:GetCell('Adresse1', 0);
			end
			if Evenement_Officiel:GetCell('Adresse2', 0) ~= '' then
				data = data..'\n'..Evenement_Officiel:GetCell('Adresse2', 0);
			end
			if Evenement_Officiel:GetCell('Code_postal', 0) ~= '' then
				data = data..'\n'..Evenement_Officiel:GetCell('Code_postal', 0)..' '..Evenement_Officiel:GetCell('Ville', 0);
			end
		end 
	end
	if return_table == true then
		return Evenement_Officiel;
	else
		return data;
	end
end

function GetDatesCoureur(params,full)
	local data = '';
	Epreuve = base:GetTable('Epreuve');
	local cmd = 'Select * from Epreuve Where Code_evenement = '..params.code_evenement;
	base:TableLoad(Epreuve, cmd);
	local date_epreuve = Epreuve:GetCell('Date_epreuve', 0, '%4Y-%2M-%2D');
	day, month, year = Epreuve:GetCell('Date_epreuve', 0, '%2D-%2M-%4Y'):match("(%d%d)-(%d%d)-(%d%d%d%d)");
	start_time = os.time({day = day, month = month, year = year})
	start_date = os.date("%Y-%m-%d", start_time);
	arrival_time = os.time({day = day - 1, month = month, year = year});
	if full == false then
		arrival_date = os.date("%d.%m.%y", arrival_time);
	else
		arrival_date = os.date("%d.%m.%Y", arrival_time);
	end

	end_time = start_time;
	if full == false then
		end_date = os.date("%d.%m.%y", end_time);
	else
		end_date = os.date("%d.%m.%Y", end_time);
	end
	return arrival_date, end_date;

end

function GetOfficielSignature(code_evenement, fonction, logo)
	local image = '';
	Evenement_Officiel = base:GetTable('Evenement_Officiel');
	local cmd = 'Select * from Evenement_Officiel Where Code_evenement = '..code_evenement..' And Fonction = "'..fonction..'"';
	base:TableLoad(Evenement_Officiel, cmd);
	if Evenement_Officiel:GetNbRows() == 1 then
		if logo == false then
			image = Evenement_Officiel:GetCell('Image_signature', 0);
		else
			image = Evenement_Officiel:GetCell('Info_supplement', 0);
		end
	end
	return image;
end

function bodyModulo(val)
	local msg = 'Liste des coureurs enlevés du formulaire \n pour cause de licence invalide :\n';
	local posit = string.find(msg,':') + 1;
	for i = body:GetNbRows() -1, 0, -1  do
		if body:GetCell('Modif_manuel', i) == "F" or body:GetCell('Modif_manuel', i) == "D" then
			if app.GetAuiFrame():MessageBox('Licence invalide pour '..body:GetCell('Identite', i)..'\nConfirmez-vous son inscription ?', "Attention à la validité des licences !!", msgBoxStyle.YES_NO+msgBoxStyle.ICON_WARNING) == msgBoxStyle.NO then 
				msg = msg.."\n"..body:GetCell('Identite', i);
				body:RemoveRowAt(i);
			end
		end
	end
	if msg:len() > posit then
		msg = msg.."\n\n"..'il reste '..body:GetNbRows()..' coureurs à inscrire';
		app.GetAuiFrame():MessageBox(msg, "Attention à la validité des licences !!", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
	end
	body:GetRecord():SetNull(); 
	nb = body:GetNbRows() % val; 
	if nb > 0 then 
		for i = nb, val-1 do 
			body:AddRow() 
		end 
	end
end
