-- Matrices / Challenges et Combinés pour skiFFS
dofile('./edition/functionPG.lua');

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

function CreateNode(parent, node_nom, attribut1, attribut2, attribut3)
	local node = xmlNode.Create(parent, xmlNodeType.ELEMENT_NODE, node_nom);
	node:ChangeAttribute('c1', attribut1);
	node:ChangeAttribute('c2', attribut2);
	node:ChangeAttribute('c3', attribut3);
	return node
end

function CreateXmlCfg()
	local utf8 = true;
	local doc_config = xmlDocument.Create();
	local nodeRoot = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "root");
	if doc_config:SetRoot(nodeRoot) == false then
		return;
	end
	
	local nodeReleve = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "Releve");
	local nodeReleveDames = xmlNode.Create(nodeReleve, xmlNodeType.ELEMENT_NODE, "Dames");
	local nodeReleveDamesannee1 = CreateNode(nodeReleveDames, 'annee1', '80', '50', '')
	local nodeReleveDamesannee2 = CreateNode(nodeReleveDames, 'annee2', '80', '50', '')
	local nodeReleveDamesannee3 = CreateNode(nodeReleveDames, 'annee3', '80', '50', '')
	local nodeReleveDamesannee4 = CreateNode(nodeReleveDames, 'annee4', '100', '60', '')
	local nodeReleveDamesannee5 = CreateNode(nodeReleveDames, 'annee5', '100', '60', '')
	local nodeReleveDamesannee6 = CreateNode(nodeReleveDames, 'annee6', '120', '80', '250,100')
	local nodeReleveDamesannee7 = CreateNode(nodeReleveDames, 'annee7', '140', '', '250,100')
	local nodeReleveDamesannee8 = CreateNode(nodeReleveDames, 'annee8', '160', '', '300,120')
	local nodeReleveDamesannee9 = CreateNode(nodeReleveDames, 'annee9', '15a|240', '', '400,125')
	local nodeReleveDamesannee10 = CreateNode(nodeReleveDames, 'annee10', '15a|400', '', '500,150')
	
	local nodeReleveHommes = xmlNode.Create(nodeReleve, xmlNodeType.ELEMENT_NODE, "Hommes");
	local nodeReleveHommesannee1 = CreateNode(nodeReleveHommes, 'annee1', '100', '75', '')
	local nodeReleveHommesannee2 = CreateNode(nodeReleveHommes, 'annee2', '100', '75', '')
	local nodeReleveHommesannee3 = CreateNode(nodeReleveHommes, 'annee3', '100', '75', '')
	local nodeReleveHommesannee4 = CreateNode(nodeReleveHommes, 'annee4', '150', '110', '')
	local nodeReleveHommesannee5 = CreateNode(nodeReleveHommes, 'annee5', '150', '110', '')
	local nodeReleveHommesannee6 = CreateNode(nodeReleveHommes, 'annee6', '200', '160', '')
	local nodeReleveHommesannee7 = CreateNode(nodeReleveHommes, 'annee7', '15a|260', '', '350,230')
	local nodeReleveHommesannee8 = CreateNode(nodeReleveHommes, 'annee8', '20a|400', '', '450,270')
	local nodeReleveHommesannee9 = CreateNode(nodeReleveHommes, 'annee9', '30a', '', '40a,15a')
	local nodeReleveHommesannee10 = CreateNode(nodeReleveHommes, 'annee10', '40a', '', '50a,10a')

	local nodeEspoirs = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "Espoirs");
	local nodeEspoirsDames = xmlNode.Create(nodeEspoirs, xmlNodeType.ELEMENT_NODE, "Dames");
	local nodeEspoirsDamesannee1 = CreateNode(nodeEspoirsDames, 'annee1', '', '', '')
	local nodeEspoirsDamesannee2 = CreateNode(nodeEspoirsDames, 'annee2', '', '', '')
	local nodeEspoirsDamesannee3 = CreateNode(nodeEspoirsDames, 'annee3', '', '', '')
	local nodeEspoirsDamesannee4 = CreateNode(nodeEspoirsDames, 'annee4', '', '', '')
	local nodeEspoirsDamesannee5 = CreateNode(nodeEspoirsDames, 'annee5', '', '', '')
	local nodeEspoirsDamesannee6 = CreateNode(nodeEspoirsDames, 'annee6', '150', '|150', '')
	local nodeEspoirsDamesannee7 = CreateNode(nodeEspoirsDames, 'annee7', '250', '', '500,250')
	local nodeEspoirsDamesannee8 = CreateNode(nodeEspoirsDames, 'annee8', '300', '', '600,350')
	local nodeEspoirsDamesannee9 = CreateNode(nodeEspoirsDames, 'annee9', '30a', '', '40a,15a')
	local nodeEspoirsDamesannee10 = CreateNode(nodeEspoirsDames, 'annee10', '40a', '', '50a,20a')

 	local nodeEspoirsHommes = xmlNode.Create(nodeEspoirs, xmlNodeType.ELEMENT_NODE, "Hommes");
	local nodeEspoirsHommesannee1 = CreateNode(nodeEspoirsHommes, 'annee1', '', '', '')
	local nodeEspoirsHommesannee2 = CreateNode(nodeEspoirsHommes, 'annee2', '', '', '')
	local nodeEspoirsHommesannee3 = CreateNode(nodeEspoirsHommes, 'annee3', '', '', '')
	local nodeEspoirsHommesannee4 = CreateNode(nodeEspoirsHommes, 'annee4', '', '', '')
	local nodeEspoirsHommesannee5 = CreateNode(nodeEspoirsHommes, 'annee5', '', '', '')
	local nodeEspoirsHommesannee6 = CreateNode(nodeEspoirsHommes, 'annee6', '350', '', '500,250')
	local nodeEspoirsHommesannee7 = CreateNode(nodeEspoirsHommes, 'annee7', '450', '', '600,300')
	local nodeEspoirsHommesannee8 = CreateNode(nodeEspoirsHommes, 'annee8', '550', '', '750,450')
	local nodeEspoirsHommesannee9 = CreateNode(nodeEspoirsHommes, 'annee9', '100a', '', '120a,30a')
	local nodeEspoirsHommesannee10 = CreateNode(nodeEspoirsHommes, 'annee10', '100a', '', '120a,30a')

 	-- local nodeCNE = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "CNE");
	-- local nodeCNEDames = xmlNode.Create(nodeCNE, xmlNodeType.ELEMENT_NODE, "Dames");
	-- local nodeCNEDamesannee1 = CreateNode(nodeCNEDames, 'annee1', '', '', '')
	-- local nodeCNEDamesannee2 = CreateNode(nodeCNEDames, 'annee2', '', '', '')
	-- local nodeCNEDamesannee3 = CreateNode(nodeCNEDames, 'annee3', '100', '60', '')
	-- local nodeCNEDamesannee4 = CreateNode(nodeCNEDames, 'annee4', '100', '60', '')
	-- local nodeCNEDamesannee5 = CreateNode(nodeCNEDames, 'annee5', '100', '60', '')
	-- local nodeCNEDamesannee6 = CreateNode(nodeCNEDames, 'annee6', '120', '80', '250,100')
	-- local nodeCNEDamesannee7 = CreateNode(nodeCNEDames, 'annee7', '140', '', '250,100')
	-- local nodeCNEDamesannee8 = CreateNode(nodeCNEDames, 'annee8', '160', '', '300,120')
	-- local nodeCNEDamesannee9 = CreateNode(nodeCNEDames, 'annee9', '15a|240', '', '300,125')
	-- local nodeCNEDamesannee10 = CreateNode(nodeCNEDames, 'annee10', '15a|400', '', '500,150')
 
 	-- local nodeCNEHommes = xmlNode.Create(nodeCNE, xmlNodeType.ELEMENT_NODE, "Hommes");
	-- local nodeCNEHommesannee1 = CreateNode(nodeCNEHommes, 'annee1', '100', '75', '')
	-- local nodeCNEHommesannee2 = CreateNode(nodeCNEHommes, 'annee2', '100', '75', '')
	-- local nodeCNEHommesannee3 = CreateNode(nodeCNEHommes, 'annee3', '100', '75', '')
	-- local nodeCNEHommesannee4 = CreateNode(nodeCNEHommes, 'annee4', '150', '110', '')
	-- local nodeCNEHommesannee5 = CreateNode(nodeCNEHommes, 'annee5', '150', '110', '')
	-- local nodeCNEHommesannee6 = CreateNode(nodeCNEHommes, 'annee6', '200', '160', '')
	-- local nodeCNEHommesannee7 = CreateNode(nodeCNEHommes, 'annee7', '15a|260', '', '350,230')
	-- local nodeCNEHommesannee8 = CreateNode(nodeCNEHommes, 'annee8', '20a|400', '', '450,270')
	-- local nodeCNEHommesannee9 = CreateNode(nodeCNEHommes, 'annee9', '30a', '', '40a,15a')
	-- local nodeCNEHommesannee10 = CreateNode(nodeCNEHommes, 'annee10', '40a', '', '50a,10a')

 	-- local nodeCIE = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "CIE");
	-- local nodeCIEDames = xmlNode.Create(nodeCIE, xmlNodeType.ELEMENT_NODE, "Dames");
	-- local nodeCIEDamesannee1 = CreateNode(nodeCIEDames, 'annee1', '', '', '')
	-- local nodeCIEDamesannee2 = CreateNode(nodeCIEDames, 'annee2', '', '', '')
	-- local nodeCIEDamesannee3 = CreateNode(nodeCIEDames, 'annee3', '', '', '')
	-- local nodeCIEDamesannee4 = CreateNode(nodeCIEDames, 'annee4', '', '', '')
	-- local nodeCIEDamesannee5 = CreateNode(nodeCIEDames, 'annee5', '', '', '')
	-- local nodeCIEDamesannee6 = CreateNode(nodeCIEDames, 'annee6', '', '', '')
	-- local nodeCIEDamesannee7 = CreateNode(nodeCIEDames, 'annee7', '550', '700,350', '')
	-- local nodeCIEDamesannee8 = CreateNode(nodeCIEDames, 'annee8', '600', '800,450', '')
	-- local nodeCIEDamesannee9 = CreateNode(nodeCIEDames, 'annee9', '150a', '100a,40a', '')
	-- local nodeCIEDamesannee10 = CreateNode(nodeCIEDames, 'annee10', '200a', '100a,50a', '')

 	-- local nodeCIEHommes = xmlNode.Create(nodeCIE, xmlNodeType.ELEMENT_NODE, "Hommes");
	-- local nodeCIEHommesannee1 = CreateNode(nodeCIEHommes, 'annee1', '', '', '')
	-- local nodeCIEHommesannee2 = CreateNode(nodeCIEHommes, 'annee2', '', '', '')
	-- local nodeCIEHommesannee3 = CreateNode(nodeCIEHommes, 'annee3', '', '', '')
	-- local nodeCIEHommesannee4 = CreateNode(nodeCIEHommes, 'annee4', '', '', '')
	-- local nodeCIEHommesannee5 = CreateNode(nodeCIEHommes, 'annee5', '', '', '')
	-- local nodeCIEHommesannee6 = CreateNode(nodeCIEHommes, 'annee6', '500', '550,500', '')
	-- local nodeCIEHommesannee7 = CreateNode(nodeCIEHommes, 'annee7', '600', '750,600', '')
	-- local nodeCIEHommesannee8 = CreateNode(nodeCIEHommes, 'annee8', '750', '900,550', '')
	-- local nodeCIEHommesannee9 = CreateNode(nodeCIEHommes, 'annee9', '200a', '200a,150a', '')
	-- local nodeCIEHommesannee10 = CreateNode(nodeCIEHommes, 'annee10', '200a', '200a,150a', '')

	nodeRoot:AddChild(nodeReleve);
	nodeRoot:AddChild(nodeEspoirs);
	-- nodeRoot:AddChild(nodeCNE);
	-- nodeRoot:AddChild(nodeCIE);
	doc_config:SaveFile(app.GetPath()..'/liste_ministerielle_cfg.xml');
	doc_config:Delete();

end

function GetNode()	-- lecture d'une valeur du XML 
	local node = nil;
	if listeMinisterielle.comboNiveau == 'Relève' then
		listeMinisterielle.comboNiveau = 'Releve';
	end
	if string.find(listeMinisterielle.comboNiveau, 'CNE') then
		listeMinisterielle.comboNiveau = 'CNE';
	end
	if string.find(listeMinisterielle.comboNiveau, 'CIE') then
		listeMinisterielle.comboNiveau = 'CIE';
	end
	local anneexml = 'annee'..listeMinisterielle.indexAnneeDebut+1;
	local strnode = 'root/'..listeMinisterielle.comboNiveau..'/'..listeMinisterielle.comboSexe..'/'..anneexml;
	if doc_cfg:FindFirst(strnode) then
		node = doc_cfg:FindFirst(strnode);
	end
	return node;
end

function GetNodex(niveau, sexe, idxannee)	-- lecture d'une valeur du XML 
	if niveau == 'Relève' then
		niveau = 'Releve';
	end
	if string.find(niveau, 'CNE') then
		niveau = 'CNE';
	end
	if string.find(niveau, 'CIE') then
		niveau = 'CIE';
	end
	local node = nil;
	local anneexml = 'annee'..listeMinisterielle.indexAnneeDebut+1;
	local strnode = 'root/'..niveau..'/'..sexe..'/annee'..idxannee;
	if doc_cfg:FindFirst(strnode) then
		node = doc_cfg:FindFirst(strnode);
	end
	return node;
end

function ChargeDisciplines()	-- charge les disciplines de l'activité pour la saison choisie.
	local suffixe = '';
	suffixe = " And Not Code LIKE 'P%' And Not Code LIKE 'TE%' And Not Code LIKE 'KO%' ";
	local cmd = "Select * From Discipline Where Code_activite = 'ALP' And Code_entite = 'FIS' And Code_saison = '"..listeMinisterielle.Saison.."'"..suffixe.." ORDER BY Ordre";;
	base:TableLoad(Discipline, cmd);
	if Discipline:GetNbRows() > 0 then
		local row = Discipline:AddRow();
		Discipline:SetCell('Code_activite', row, Discipline:GetCell('Code_activite', 0));
		Discipline:SetCell('Code_entite', row, Discipline:GetCell('Code_entite', 0));
		Discipline:SetCell('Code_saison', row, Discipline:GetCell('Code_saison', 0));
		Discipline:SetCell('Code_origine', row, Discipline:GetCell('Code_origine', 0));
		Discipline:SetCell('Code', row, 'TEC');
		Discipline:SetCell('Ordre', row, 20);
		Discipline:SetCell('Officiel', row, 'N');
		Discipline:SetCell('Code_international', row, 'TEC');
		Discipline:SetCell('Libelle', row, 'Discipline fictive Technique');
		row = Discipline:AddRow();
		Discipline:SetCell('Code_activite', row, Discipline:GetCell('Code_activite', 0));
		Discipline:SetCell('Code_entite', row, Discipline:GetCell('Code_entite', 0));
		Discipline:SetCell('Code_saison', row, Discipline:GetCell('Code_saison', 0));
		Discipline:SetCell('Code_origine', row, Discipline:GetCell('Code_origine', 0));
		Discipline:SetCell('Code', row, 'VIT');
		Discipline:SetCell('Ordre', row, 21);
		Discipline:SetCell('Officiel', row, 'N');
		Discipline:SetCell('Code_international', row, 'VIT');
		Discipline:SetCell('Libelle', row, 'Discipline fictive Vitesse');
	end
end

function SetCriteres()
	bolTechVit = false;
	-- Classement_Coureur est construit
	-- récupération des critères
	local bolc1aParAnnee = false;
	local bolc1bParAnnee = false;
	local bolc2aParAnnee = false;
	local bolc2bParAnnee = false;
	local bolc3aParAnnee = false;
	local bolc3bParAnnee = false;
	local bolc1bOU = false;
	local bolc2aOU = false;
	local bolc2bOU = false;
	local bolc3bOU = false;
	local bolc4bOU = false;
	local bolc5bOU = false;
	local bolc6bOU = false;

	local c1a = dlgConfig:GetWindowName('gxpremiersc1a'):GetValue();
	c1a = tonumber(c1a) or 0;
	if dlgConfig:GetWindowName('chkc1a'):GetValue() == true then
		bolc1aParAnnee = true;
	end
	local c1b = dlgConfig:GetWindowName('gxpremiersc1b'):GetValue();
	c1b = tonumber(c1b) or 0;
	if dlgConfig:GetWindowName('chkc1b'):GetValue() == true then
		bolc1bParAnnee = true;
	end
	if dlgConfig:GetWindowName('chkouc1b'):GetValue() == true then
		bolc1bOU = true;
	end

	local c2a = dlgConfig:GetWindowName('gxpremiersc2a'):GetValue();
	c2a = tonumber(c2a) or 0;
	if dlgConfig:GetWindowName('chkc2a'):GetValue() == true then
		bolc2aParAnnee = true;
	end
	if dlgConfig:GetWindowName('chkouc2a'):GetValue() == true then
		bolc2aOU = true;
	end

	local c2b = dlgConfig:GetWindowName('gxpremiersc2b'):GetValue();
	c2b = tonumber(c2b) or 0;
	if dlgConfig:GetWindowName('chkc2b'):GetValue() == true then
		bolc2bParAnnee = true;
	end
	if dlgConfig:GetWindowName('chkouc2b'):GetValue() == true then
		bolc2bOU = true;
	end
		
	local c3a = dlgConfig:GetWindowName('gxpremiersc3a'):GetValue();
	c3a = tonumber(c3a) or 0;
	if dlgConfig:GetWindowName('chkc3a'):GetValue() == true then
		bolc3aParAnnee = true;
	end
	local c3b = dlgConfig:GetWindowName('gxpremiersc3b'):GetValue();
	c3b = tonumber(c3b) or 0;
	if dlgConfig:GetWindowName('chkc3b'):GetValue() == true then
		bolc3bParAnnee = true;
	end

	-- étude du critère 2 : discipline vitesse
	local c3 = dlgConfig:GetWindowName('gxpremiersc2a'):GetValue();
	
	if bolc2aOU == true then
		bolTechVit = true;
	end
	
	-- cas particulier
	--	on a c1="150" et c2 ="/200"   => 150 en technique OU 200 en vitesse pour remplir le critère
	
	-- Col1 = les Pts Techniques sont sélectionnés
	-- Col2 = les Pts Vitesses sont sélectionnés
	-- Col3 = les Pts Techniques par année sont sélectionnés
	-- Col4 = les Pts Vitesses par année sont sélectionnés
	-- Col5 = on prend 1 vitesse + 1 technique et on met dedans la colonne choisie
	for row = 0, Classement_Coureur:GetNbRows() -1 do
		Classement_Coureur:SetCell('Col1', row, 0);
		Classement_Coureur:SetCell('Col2', row, 0);
		Classement_Coureur:SetCell('Col3', row, 0);
		Classement_Coureur:SetCell('Col4', row, 0);
		Classement_Coureur:SetCell('Col5', row, '');
		local clt_tech = Classement_Coureur:GetCellInt('Clt_technique', row, 10000);
		local clt_vitesse = Classement_Coureur:GetCellInt('Clt_vitesse', row, 10000);
		local clt_tech_annee = Classement_Coureur:GetCellInt('Clt_technique_annee', row, 10000);
		local clt_vitesse_annee = Classement_Coureur:GetCellInt('Clt_vitesse_annee', row, 10000);
		if Classement_Coureur:GetCellInt('Clt_SL_Annee', row) < Classement_Coureur:GetCellInt('Clt_GS_Annee', row) then
			Classement_Coureur:SetCell('Best_tech_annee', row, ' (SL) ');
		else
			Classement_Coureur:SetCell('Best_tech_annee', row, ' (GS) ');
		end
		if Classement_Coureur:GetCellInt('Clt_SG_Annee', row) < Classement_Coureur:GetCellInt('Clt_DH_Annee', row) then
			Classement_Coureur:SetCell('Best_vit_annee', row, ' (SG) ');
		else
			Classement_Coureur:SetCell('Best_vit_annee', row, ' (DH) ');
		end
		local critere = 0;
		local bolcritere1 = false;
		local bolcritere2 = false;
		local txtcol5 = 'Z';
		if bolTechVit == false then
			-- la technique
			if c1a > 0 then
				if bolc1aParAnnee == false then
					if clt_tech > 0 and clt_tech <= c1a then
						bolcritere1 = true;
						txtcol5 = txtcol5..',1';
						Classement_Coureur:SetCell('Col1', row, 1);
					end
				else
					if clt_tech_annee > 0 and clt_tech_annee <= c1a then
						bolcritere1 = true;
						txtcol5 = txtcol5..',1';
						Classement_Coureur:SetCell('Col3', row, 1);
					end
				end
			end
			if c1b > 0 then
				if bolc1bParAnnee == false then
					if clt_tech > 0 and clt_tech <= c1b then
						bolcritere1 = true;
						txtcol5 = txtcol5..',1';
						Classement_Coureur:SetCell('Col1', row, 1);
					end
				else
					if clt_tech_annee > 0 and clt_tech_annee <= c1b then
						bolcritere1 = true;
						txtcol5 = txtcol5..',1';
						Classement_Coureur:SetCell('Col3', row, 1);
					end
				end
			end
			if bolcritere1 == true then
				critere = critere + 1;
			end

			-- la vitesse 
			if c2a > 0 then
				if bolc2aParAnnee == false then
					if clt_vitesse > 0 and clt_vitesse <= c2a then
						bolcritere2 = true;
						txtcol5 = txtcol5..' / 2';
						Classement_Coureur:SetCell('Col2', row, 1);
					end
				else
					if clt_vitesse_annee > 0 and clt_vitesse_annee <= c2a then
						bolcritere2 = true;
						txtcol5 = txtcol5..' / 2';
						Classement_Coureur:SetCell('Col4', row, 1);
					end
				end
			end
			if c2b > 0 then
				if bolc2bParAnnee == false then
					if clt_vitesse > 0 and clt_vitesse <= c2b then
						bolcritere2 = true;
						txtcol5 = txtcol5..',2';
						Classement_Coureur:SetCell('Col2', row, 1);
					end
				else
					if clt_vitesse_annee > 0 and clt_vitesse_annee <= c2b then
						bolcritere2 = true;
						txtcol5 = txtcol5..',2';
						Classement_Coureur:SetCell('Col4', row, 1);
					end
				end
			end
			if bolcritere2 == true then
				critere = critere + 1;
			end
		else
			local bolPrendreTech = false;
			local bolPrendreTechAnnee = false;
			local bolPrendreVit = false;
			local bolPrendreVitAnnee = false;
			if c1a > 0 then
				if bolc1aParAnnee == false then
					if clt_tech > 0 and clt_tech <= c1a then
						bolPrendreTech = true;
						txtcol5 = txtcol5..',1';
					end
				else
					if clt_tech_annee > 0 and clt_tech_annee <= c1a then
						bolPrendreTechAnnee = true; 
						txtcol5 = txtcol5..',1';
					end
				end
			end
			if c1b > 0 then
				if bolc1bParAnnee == false then
					if clt_tech > 0 and clt_tech <= c1b then
						bolPrendreTech = true; 
						txtcol5 = txtcol5..',1';
					end
				else
					if clt_tech_annee > 0 and clt_tech_annee <= c1b then
						bolPrendreTechAnnee = true; 
						txtcol5 = txtcol5..',1';
					end
				end
			end
			-- la vitesse 
			if c2a > 0 then
				if bolc2aParAnnee == false then
					if clt_vitesse > 0 and clt_vitesse <= c2a then
						bolPrendreVit = true;
						txtcol5 = txtcol5..' / 2';
					end
				else
					if clt_vitesse_annee > 0 and clt_vitesse_annee <= c2a then
						bolPrendreVitAnnee = true;
						txtcol5 = txtcol5..' / 2';
					end
				end
			end
			if c2b > 0 then
				if bolc2bParAnnee == false then
					if clt_vitesse > 0 and clt_vitesse <= c2b then
						bolPrendreVit = true;
						txtcol5 = txtcol5..',2';
					end
				else
					if clt_vitesse_annee > 0 and clt_vitesse_annee <= c2b then
						bolPrendreVitAnnee = true;
						txtcol5 = txtcol5..',2';
					end
				end
			end
			if bolPrendreTech == true then
				critere = critere + 1;
				Classement_Coureur:SetCell('Col1', row, 1);
			end
			if bolPrendreTechAnnee == true then
				critere = critere + 1;
				Classement_Coureur:SetCell('Col3', row, 1);
			end
			if bolPrendreVit == true then
				critere = critere + 1;
				Classement_Coureur:SetCell('Col2', row, 1);
			end
			if bolPrendreVitAnnee == true then
				critere = critere + 1;
				Classement_Coureur:SetCell('Col4', row, 1);
			end
		end
		
		-- deux discipline 1 technique ET 1 vitesse
		local boltech = false;
		local boltechannee = false;
		local bolvit = false;
		local bolvitannee = false;
		local boltechnique = false;
		local bolvitesse = false;
		if c3a > 0 then
			if bolc3aParAnnee == false then
				if clt_tech > 0 and clt_tech <= c3a then
					boltech = true;
					boltechnique = true;
				end
			else
				if clt_tech_annee > 0 and clt_tech_annee <= c3a then
					boltechannee = true;
					boltechnique = true;
				end
			end
		end
		if c3b > 0 then
			if bolc3bParAnnee == false then
				if clt_vitesse > 0 and clt_vitesse <= c3b then
					bolvit = true;
					bolvitesse = true;
				end
			else
				if clt_vitesse_annee > 0 and clt_vitesse_annee <= c3b then
					bolvitannee = true;
					bolvitesse = true;
				end
			end
		end
		if boltechnique == true and bolvitesse == true then
			critere = critere + 1;
			txtcol5 = txtcol5..' / 3';
			if boltech == true then
				Classement_Coureur:SetCell('Col1', row, 1);
				txtcol5 = txtcol5..',A';
			end
			if boltechannee == true then
				Classement_Coureur:SetCell('Col3', row, 1);
				txtcol5 = txtcol5..',C';
			end
			if bolvit == true then
				Classement_Coureur:SetCell('Col2', row, 1);
				txtcol5 = txtcol5..',B';
			end
			if bolvitannee == true then
				Classement_Coureur:SetCell('Col4', row, 1);
				txtcol5 = txtcol5..',D';
			end
		end
		txtcol5 = string.gsub(txtcol5, 'Z', '');
		if txtcol5:sub(1, 1) == ',' then
			txtcol5 = string.sub(txtcol5,2);
		end
		Classement_Coureur:SetCell('Col5', row, txtcol5);
		Classement_Coureur:SetCell('Est_critere', row, critere);
	end
	Classement_Coureur:Snapshot('Classement_Coureur.db3');
end

function SetClassement_Coureur_Annee()
	Classement_Coureur:ChangeColumn('Clt_SL_Annee', 'ranking');
	Classement_Coureur:ChangeColumn('Clt_GS_Annee', 'ranking');
	Classement_Coureur:ChangeColumn('Clt_DH_Annee', 'ranking');
	Classement_Coureur:ChangeColumn('Clt_SG_Annee', 'ranking');
	Classement_Coureur:ChangeColumn('Clt_technique_annee', 'ranking');
	Classement_Coureur:ChangeColumn('Clt_vitesse_annee', 'ranking');
	Classement_Coureur:SetRanking('Clt_SL_Annee', 'Pts_SL', 'An')
	Classement_Coureur:SetRanking('Clt_GS_Annee', 'Pts_GS', 'An')
	Classement_Coureur:SetRanking('Clt_DH_Annee', 'Pts_DH', 'An')
	Classement_Coureur:SetRanking('Clt_SG_Annee', 'Pts_SG', 'An')
	Classement_Coureur:SetRanking('Clt_technique_annee', 'Pts_technique', 'An')
	Classement_Coureur:SetRanking('Clt_vitesse_annee', 'Pts_vitesse', 'An')
	
	-- Classement_Coureur:Snapshot('Classement_Coureur.db3');
	
end

function BuildClassementCoureur()	-- construction de la table des classements
	local sexe = 'M';
	if listeMinisterielle.comboSexe == 'Dames' then
		sexe = 'F';
	end
	local cmd = "SELECT cou.Code_coureur, 0 Est_critere, cou.Code_nation Nation, cou.Code_comite Comite, CONCAT(cou.Nom, ' ',cou.Prenom) Identite,  DATE_FORMAT(cou.Naissance,'%Y') An, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASL') Pts_SL, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASL') Clt_SL, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IAGS') Pts_GS, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IAGS') Clt_GS, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASG') Pts_SG, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IASG') Clt_SG, "..
		"(Select Pts From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IADH') Pts_DH, "..
		"(Select Clt From Classement_coureur cla1 WHERE cla1.Code_coureur = cou.Code_coureur AND cla1.Code_liste = "..listeMinisterielle.comboListe.." AND cla1.Type_classement='IADH') Clt_DH "..
		"FROM Coureur cou "..
		"WHERE cou.Code_coureur LIKE 'FIS%' And cou.Sexe ='"..sexe.."'";
	Classement_Coureur = base:TableLoad(cmd);
	Classement_Coureur:OrderBy('Clt_technique');
	ReplaceTableEnvironnement(Classement_Coureur, 'Classement_Coureur');
	Classement_Coureur:AddColumn({ name = 'Pts_technique', label = 'Pts_technique', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_technique', label = 'Clt_technique', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Pts_vitesse', label = 'Pts_vitesse', type = sqlType.DOUBLE, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_vitesse', label = 'Clt_vitesse', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_SL_Annee', label = 'Clt_SL_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_GS_Annee', label = 'Clt_GS_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_DH_Annee', label = 'Clt_DH_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_SG_Annee', label = 'Clt_SG_Annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_technique_annee', label = 'Clt_technique_annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Clt_vitesse_annee', label = 'Clt_vitesse_annee', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Best_tech', label = 'Best_tech', type = sqlType.TEXT, width = 20, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Best_tech_annee', label = 'Best_tech_annee', type = sqlType.TEXT, width = 20, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Best_vit', label = 'Best_vit', type = sqlType.TEXT, width = 20, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Best_vit_annee', label = 'Best_vit_annee', type = sqlType.TEXT, width = 20, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col1', label = 'Col1', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col2', label = 'Col2', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col3', label = 'Col3', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col4', label = 'Col4', type = sqlType.LONG, style = sqlStyle.NULL });
	Classement_Coureur:AddColumn({ name = 'Col5', label = 'Col5', type = sqlType.TEXT, width = 20, style = sqlStyle.NULL });
	Classement_Coureur:OrderBy('Clt_technique DESC');
	last_clt_technique = Classement_Coureur:GetCellInt('Clt_technique', 0, -1);
	Classement_Coureur:OrderBy('Clt_vitesse DESC');
	last_clt_vitesse = Classement_Coureur:GetCellInt('Clt_vitesse', 0, -1);
	for row = Classement_Coureur:GetNbRows() -1, 0, -1 do
		local cltSL = Classement_Coureur:GetCellInt('Clt_SL', row, -1);
		local cltGS = Classement_Coureur:GetCellInt('Clt_GS', row, -1);
		local cltSG = Classement_Coureur:GetCellInt('Clt_SG', row, -1);
		local cltDH = Classement_Coureur:GetCellInt('Clt_DH', row, -1);
		if cltSL < 0 and cltGS < 0 and cltSG < 0 and cltDH < 0 then
			Classement_Coureur:RemoveRowAt(row);
		end
	end

	listeMinisterielle.filter_annees = "'-1'";
	num_annee_debut = tonumber(dlgConfig:GetWindowName('comboAnneeDebut'):GetValue()) or 0;
	num_annee_fin = tonumber(dlgConfig:GetWindowName('comboAnneeFin'):GetValue()) or 0;
	for i = num_annee_debut, num_annee_fin do
		listeMinisterielle.filter_annees = listeMinisterielle.filter_annees..",'"..tostring(i).."'";
	end
	local filter = "$(An):In("..listeMinisterielle.filter_annees..")";
	Classement_Coureur:Filter(filter, true)
	SetClassement_Coureur_Annee();

	for row = 0, Classement_Coureur:GetNbRows()-1 do
		local cltSL = Classement_Coureur:GetCellInt('Clt_SL', row, 10000);
		local ptsSL = Classement_Coureur:GetCellDouble('Pts_SL', row, 10000);
		local cltGS = Classement_Coureur:GetCellInt('Clt_GS', row, 10000);
		local ptsGS = Classement_Coureur:GetCellDouble('Pts_GS', row, 10000);
		local cltSG = Classement_Coureur:GetCellInt('Clt_SG', row, 10000);
		local cltSGannee = Classement_Coureur:GetCellInt('Clt_SG_Annee', row, 10000);
		local ptsSG = Classement_Coureur:GetCellDouble('Pts_SG', row, 10000);
		local cltDH = Classement_Coureur:GetCellInt('Clt_DH', row, 10000);
		local cltDHannee = Classement_Coureur:GetCellInt('Clt_DH_Annee', row, 10000);
		local ptsDH = Classement_Coureur:GetCellDouble('Pts_DH', row, 10000);
		local cltTect = math.min(cltSL, cltGS);
		if cltTect < 10000 then
			if cltSL < cltGS then
				Classement_Coureur:SetCell('Pts_technique', row, ptsSL);
				Classement_Coureur:SetCell('Clt_technique', row, cltSL);
				Classement_Coureur:SetCell('Best_tech', row, ' (SL) ');
			else
				Classement_Coureur:SetCell('Pts_technique', row, ptsGS);
				Classement_Coureur:SetCell('Clt_technique', row, cltGS);
				Classement_Coureur:SetCell('Best_tech', row, ' (GS) ');
			end
		end
		local cltVit = math.min(cltSG, cltDH);
		if cltVit < 10000 then
			if cltSG < cltDH then
				Classement_Coureur:SetCell('Pts_vitesse', row, ptsSG);
				Classement_Coureur:SetCell('Clt_vitesse', row, cltSG);
				Classement_Coureur:SetCell('Best_vit', row, ' (SG) ');
			else
				Classement_Coureur:SetCell('Pts_vitesse', row, ptsDH);
				Classement_Coureur:SetCell('Clt_vitesse', row, cltDH);
				Classement_Coureur:SetCell('Best_vit', row, ' (DH) ');
			end
		end
	end
	--Classement_Coureur:Filter(listeMinisterielle.filter_annees, true);
	for row = 0, Classement_Coureur:GetNbRows()-1 do
		local cltSLannee = Classement_Coureur:GetCellInt('Clt_SL_Annee', row, 10000);
		local cltGSannee = Classement_Coureur:GetCellInt('Clt_GS_Annee', row, 10000);
		local cltSGannee = Classement_Coureur:GetCellInt('Clt_SG_Annee', row, 10000);
		local cltDHannee = Classement_Coureur:GetCellInt('Clt_DH_Annee', row, 10000);
		local cltTectannee = math.min(cltSLannee, cltGSannee);
		local cltVitannee = math.min(cltSGannee, cltDHannee);
		if cltTectannee < 10000 then
			if cltSLannee < cltGSannee then
				Classement_Coureur:SetCell('Clt_technique_annee', row, cltSLannee);
			else
				Classement_Coureur:SetCell('Clt_technique_annee', row, cltGSannee);
			end
		end
		if cltVitannee < 10000 then
			if cltSGannee < cltDHannee then
				Classement_Coureur:SetCell('Clt_vitesse_annee', row, cltSGannee);
			else
				Classement_Coureur:SetCell('Clt_vitesse_annee', row, cltDHannee);
			end
		end
	end
	Classement_Coureur:Filter("$(Nation):In('FRA')", true);

	SetCriteres();
	OnPrintAnalyse();
end

function OnPrintAnalyse()
	-- Creation du Report
	listeMinisterielle.Critere1  = 'Néant';
	listeMinisterielle.Critere2  = 'Néant';
	listeMinisterielle.Critere3  = 'Néant';
	local xc1a = dlgConfig:GetWindowName('gxpremiersc1a'):GetValue();
	local xc1b = dlgConfig:GetWindowName('gxpremiersc1b'):GetValue();
	local xc2a = dlgConfig:GetWindowName('gxpremiersc2a'):GetValue();
	local xc2b = dlgConfig:GetWindowName('gxpremiersc2b'):GetValue();
	local xc3a = dlgConfig:GetWindowName('gxpremiersc3a'):GetValue();
	local xc3b = dlgConfig:GetWindowName('gxpremiersc3b'):GetValue();
	if xc1a:len() > 0 then
		listeMinisterielle.Critere1 = "Etre dans les "..xc1a..' mondiaux';
		if dlgConfig:GetWindowName('chkc1a'):GetValue() == true then
			listeMinisterielle.Critere1 = listeMinisterielle.Critere1.." de son année ";
		end
	end
	if xc1b:len() > 0 then
		listeMinisterielle.Critere1 = listeMinisterielle.Critere1.. ' OU être dans les '..xc1b..' mondiaux';
		if dlgConfig:GetWindowName('chkc1b'):GetValue() == true then
			listeMinisterielle.Critere1 = listeMinisterielle.Critere1.." de son année ";
		end
	end
	
	if xc2a:len() > 0 then
		if dlgConfig:GetWindowName('chkouc2a'):GetValue() == true then
			listeMinisterielle.Critere2 = 'OU être dans les '..xc2a..' mondiaux';
		else
			listeMinisterielle.Critere2 = "Etre dans les "..xc2a..' mondiaux';
		end
		if dlgConfig:GetWindowName('chkc2a'):GetValue() == true then
			listeMinisterielle.Critere2 = listeMinisterielle.Critere2.." de son année ";
		end
	end
	if xc2b:len() > 0 then
		listeMinisterielle.Critere2 = listeMinisterielle.Critere2..' OU être dans les '..xc2b..' mondiaux';
		if dlgConfig:GetWindowName('chkc2b'):GetValue() == true then
			listeMinisterielle.Critere2 = listeMinisterielle.Critere2.." de son année ";
		end
	end
	
	if xc3a:len() > 0 then
		listeMinisterielle.Critere3 = "En Technique, être dans les "..xc3a..' mondiaux';
		if dlgConfig:GetWindowName('chkc3a'):GetValue() == true then
			listeMinisterielle.Critere3 = listeMinisterielle.Critere3.." de son année ";
		end
	end
	if xc3b:len() > 0 then
		listeMinisterielle.Critere3 = listeMinisterielle.Critere3.. ' ET en Vitesse être dans les '..xc3b..' mondiaux';
		if dlgConfig:GetWindowName('chkc3b'):GetValue() == true then
			listeMinisterielle.Critere3 = listeMinisterielle.Critere3.." de son année ";
		end
	end
	if listeMinisterielle.Critere3:len() > 10 then
		listeMinisterielle.Critere3 = listeMinisterielle.Critere3.. '  (répéré par un signe "X")';
	end

	Classement_Coureur:OrderBy('Est_critere DESC, Pts_technique')
	report = wnd.LoadTemplateReportXML({
		xml = './process/liste_ministerielle.xml',
		node_name = 'root/panel',
		node_attr = 'id',
		node_value = 'printanalyse',
		title = "Edition des coureurs selon les critères",
		base = base,
		body = Classement_Coureur,
		margin_first_top = 120,
		margin_first_left = 100,
		margin_first_right = 100,
		margin_first_bottom = 100,
		margin_top = 120,
		margin_left = 100,
		margin_right = 100,
		margin_bottom = 100,
		paper_orientation = 'landscape',
		params = {Niveau = ' - Pour le niveau : '..listeMinisterielle.comboNiveau, Liste = listeMinisterielle.comboListe, Version = script_version, Critere1 = listeMinisterielle.Critere1, Critere2 = listeMinisterielle.Critere2, Critere3 = listeMinisterielle.Critere3, AnneeDebut = num_annee_debut, AnneeFin = num_annee_fin}
	});
	-- report:SetZoom(10)
end

function OnSavedlgBackoffice()
	if not doc_cfg then
		do return end
	end
	for i = 1, 10 do
		local c1 = '';
		local c2 = '';
		local c3 = '';
		node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i);
		assert(node ~= nil);
		local col1 = dlgBackoffice:GetWindowName('unetechniquea'..i):GetValue();
		local col2 = dlgBackoffice:GetWindowName('unetechniqueb'..i):GetValue();
		local col3 = dlgBackoffice:GetWindowName('unevitessea'..i):GetValue();
		local col4 = dlgBackoffice:GetWindowName('unevitesseb'..i):GetValue();
		local col5 = dlgBackoffice:GetWindowName('deuxvitessea'..i):GetValue();
		local col6 = dlgBackoffice:GetWindowName('deuxvitesseb'..i):GetValue();
		local col7 = dlgBackoffice:GetWindowName('deuxtechniquea'..i):GetValue();
		local col8 = dlgBackoffice:GetWindowName('deuxtechniqueb'..i):GetValue();
		local chkouc2b = dlgBackoffice:GetWindowName('chkouc2b'..i):GetValue();
		
		if col1:len() > 0 then
			col1 = col1..'a';
		end
		if col3:len() > 0 then
			col3 = col3..'a';
		end
		if col5:len() > 0 then
			col5 = col5..'a';
		end
		if col7:len() > 0 then
			col7 = col7..'a';
		end
		
		if col1:len() > 0 and col2:len() > 0 then
			col2 = '|'..col2;
		end
		if chkouc2b == true then
			if col3:len() > 0 then
				col3 = '|'..col3;
			end
			if col4:len() > 0 then
				col4 = '|'..col4;
			end
		else
			if col3:len() > 0 and col4:len() > 0 then
				col4 = ','..col4;
			end
		end
		if col5:len() > 0 and col6:len() > 0 then
			col6 = ','..col6;
		end
		if col7:len() > 0 and col8:len() > 0 then
			col8 = ','..col8;
		end
		c1 = col1..col2;
		c2 = col3..col4;
		if (col5:len() > 0 or col6:len() > 0) and (col7:len() > 0 or col8:len() > 0) then
			c3 = col5..col6..','..col7..col8;
		end
		node:ChangeAttribute('c1', c1);
		node:ChangeAttribute('c2', c2);
		node:ChangeAttribute('c3', c3);
		doc_cfg:SaveFile();
		doc_cfg:Delete();
		XML_cfg = app.GetPath().."/liste_ministerielle_cfg.xml";
		doc_cfg = xmlDocument.Create(XML_cfg);
	end
	SetDataAnalyse();
	dlgBackoffice:EndModal();
end

function SetAnalyseGauche(c1,c2,c3)	-- c1, c2 et c3 sont des valeurs de critères
	dlgConfig:GetWindowName('chkc1a'):SetValue(false);
	dlgConfig:GetWindowName('chkc1b'):SetValue(false);
	dlgConfig:GetWindowName('chkouc1b'):SetValue(false);
	dlgConfig:GetWindowName('chkc2a'):SetValue(false);
	dlgConfig:GetWindowName('chkc2b'):SetValue(false);
	dlgConfig:GetWindowName('chkc3a'):SetValue(false);
	dlgConfig:GetWindowName('chkc3b'):SetValue(false);
	dlgConfig:GetWindowName('chkouc2a'):SetValue(false);
	dlgConfig:GetWindowName('chkouc2b'):SetValue(false);
	dlgConfig:GetWindowName('gxpremiersc1a'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc1b'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc2a'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc2b'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc3a'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc3b'):SetValue('');
	listeMinisterielle.par_annee = false;
	local tc1 = c1:Split('|');		--	exemple dans c1 : 15a|240 => 15ème dans l'année d'âge ou 240ème mondial mettre 15 dans la première ligne cocher année et mettre 250 en ligne 2, décocher ou et décocher année d'âge
	if #tc1 > 1 then	-- on a 2 critères
		dlgConfig:GetWindowName('gxpremiersc1a'):SetValue(string.gsub(tc1[1], "%D", ""));
		if string.find(tc1[1], 'a') then
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chkc1a'):SetValue(true);
		end
		dlgConfig:GetWindowName('chkouc1b'):SetValue(true);
		if string.find(tc1[2], 'a') then
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chkc1b'):SetValue(true);
		end
		dlgConfig:GetWindowName('gxpremiersc1b'):SetValue(string.gsub(tc1[2], "%D", ""));
	else	-- critère simple
		dlgConfig:GetWindowName('gxpremiersc1a'):SetValue(string.gsub(tc1[1], "%D", ""));
		if string.find(tc1[1], 'a') then
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chkc1a'):SetValue(true);
		end
	end
	
	local tc2 = c2:Split('|');		--	exemple dans c2 : |240 => ou être 250 en ... on active le ou à la ligne 1
	if #tc2 > 1 then	-- on a 2 critères dont le premier peut être vide. C'est alors un OU entre technique et vitesse
		if tc2[1]:len() == 0 then
			dlgConfig:GetWindowName('chkouc2a'):SetValue(true);
			dlgConfig:GetWindowName('gxpremiersc2a'):SetValue(string.gsub(tc2[2], "%D", ""));
			if string.find(tc2[2], 'a') then
				listeMinisterielle.par_annee = true;
				dlgConfig:GetWindowName('chkc2a'):SetValue(true);
			end
		else
			dlgConfig:GetWindowName('gxpremiersc2a'):SetValue(string.gsub(tc2[1], "%D", ""));
			if string.find(tc2[1], 'a') then
				listeMinisterielle.par_annee = true;
				dlgConfig:GetWindowName('chkc2a'):SetValue(true);
			end
			dlgConfig:GetWindowName('chkouc2b'):SetValue(true);
			if string.find(tc2[2], 'a') then
				listeMinisterielle.par_annee = true;
				dlgConfig:GetWindowName('chkc2b'):SetValue(true);
			end
			dlgConfig:GetWindowName('gxpremiersc2b'):SetValue(string.gsub(tc2[2], "%D", ""));
		end
	else	-- critère simple
		dlgConfig:GetWindowName('gxpremiersc2a'):SetValue(string.gsub(tc2[1], "%D", ""));
		if string.find(tc2[1], 'a') then
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chkc2a'):SetValue(true);
		end
	end
	
	local tc3 = c3:Split(',');	-- sépare technique et vitesse
	if #tc3 > 1 then	-- on a 2 critères dont le premier peut être vide. C'est alors un OU entre technique et vitesse
		dlgConfig:GetWindowName('gxpremiersc3a'):SetValue(string.gsub(tc3[1], "%D", ""));
		if string.find(tc3[1], 'a') then
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chkc3a'):SetValue(true);
		end
		dlgConfig:GetWindowName('gxpremiersc3b'):SetValue(string.gsub(tc3[2], "%D", ""));
		if string.find(tc3[2], 'a') then
			listeMinisterielle.par_annee = true;
			dlgConfig:GetWindowName('chkc3b'):SetValue(true);
		end
	end
	dlgConfig:GetWindowName('gxpremiersc1b'):Enable(dlgConfig:GetWindowName('chkouc1b'):GetValue());
	dlgConfig:GetWindowName('gxpremiersc2b'):Enable(dlgConfig:GetWindowName('chkouc2b'):GetValue());
end

function SetDataAnalyse()
	dlgConfig:GetWindowName('chkc1a'):SetValue(false);
	dlgConfig:GetWindowName('chkc1b'):SetValue(false);
	dlgConfig:GetWindowName('chkc2a'):SetValue(false);
	dlgConfig:GetWindowName('chkc2b'):SetValue(false);
	dlgConfig:GetWindowName('chkc3a'):SetValue(false);
	dlgConfig:GetWindowName('chkc3b'):SetValue(false);
	dlgConfig:GetWindowName('chkouc1b'):SetValue(false);
	dlgConfig:GetWindowName('chkouc2a'):SetValue(false);
	dlgConfig:GetWindowName('chkouc2b'):SetValue(false);
	dlgConfig:GetWindowName('gxpremiersc1a'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc1b'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc2a'):SetValue('');
	dlgConfig:GetWindowName('gxpremiersc2b'):SetValue('');
	
	listeMinisterielle.node = GetNode();
	assert(listeMinisterielle.node ~= nil)
	local c1 = listeMinisterielle.node:GetAttribute("c1");
	local c2 = listeMinisterielle.node:GetAttribute("c2");
	local c3 = listeMinisterielle.node:GetAttribute("c3");
	SetAnalyseGauche(c1, c2, c3);
end

function OnChangeComboAnneeDebut()
	listeMinisterielle.comboAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetValue();
	listeMinisterielle.indexAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetSelection();
	SetDataAnalyse();
end

function AfficheNode(node, idx)
	dlgBackoffice:GetWindowName('unetechniquea'..idx):SetValue('');
	dlgBackoffice:GetWindowName('unetechniqueb'..idx):SetValue('');
	dlgBackoffice:GetWindowName('unevitessea'..idx):SetValue('');
	dlgBackoffice:GetWindowName('unevitesseb'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxvitessea'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxvitesseb'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxtechniquea'..idx):SetValue('');
	dlgBackoffice:GetWindowName('deuxtechniqueb'..idx):SetValue('');
	dlgBackoffice:GetWindowName('chkouc2b'..idx):SetValue(false);
	
	dlgBackoffice:GetWindowName('unetechniquea'..idx):Enable(true);
	dlgBackoffice:GetWindowName('unetechniqueb'..idx):Enable(true);
	dlgBackoffice:GetWindowName('unevitessea'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxvitessea'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxvitesseb'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxtechniquea'..idx):Enable(true);
	dlgBackoffice:GetWindowName('deuxtechniqueb'..idx):Enable(true);
	dlgBackoffice:GetWindowName('chkouc2b'..idx):Enable(true);

	local c1 = node:GetAttribute("c1");
	local c2 = node:GetAttribute("c2");
	local c3 = node:GetAttribute("c3");
	if c1:len() > 0 then
		if c1 ~= '' then
			local tc1 = c1:Split('|');
			for i = 1, #tc1 do
				if string.find(tc1[i], 'a') then	-- on est par année d'âge
					tc1[i] = string.gsub(tc1[i], "%D", "");
					dlgBackoffice:GetWindowName('unetechniquea'..idx):SetValue(tc1[i]);
				else
					dlgBackoffice:GetWindowName('unetechniqueb'..idx):SetValue(tc1[i]);
				end
			end
		end
	end
	if c2:len() > 0 then
		-- dlgBackoffice:GetWindowName('unevitessea'..idx):SetValue(c2);
		local tc2 = c2:Split('|');
		if #tc2 > 1 then
			if tc2[1]:len() == 0 then	-- c'est un ou entre technique et vitesse
				dlgBackoffice:GetWindowName('chkouc2b'..idx):SetValue(true);
				-- dlgBackoffice:GetWindowName('unevitessea'..idx):SetValue(tc2[2]);
				if string.find(tc2[2], 'a') then
					dlgBackoffice:GetWindowName('unevitessea'..idx):SetValue(tc2[2]);
				else
					dlgBackoffice:GetWindowName('unevitesseb'..idx):SetValue(tc2[2]);
				end
			else						-- c'est un choix entre par année et mondial
				dlgBackoffice:GetWindowName('unevitessea'..idx):SetValue(tc2[1]);
				dlgBackoffice:GetWindowName('unevitesseb'..idx):SetValue(tc2[2]);
			end
		else
			if string.find(tc2[1], 'a') then
				dlgBackoffice:GetWindowName('unevitessea'..idx):SetValue(tc2[1]);
			else
				dlgBackoffice:GetWindowName('unevitesseb'..idx):SetValue(tc2[1]);
			end
		end
	end
	
	if c3:len() > 0 then
		local tc3 = c3:Split(',');
		if #tc3 > 1 then
			if string.find(tc3[1], 'a') then	-- on est par année d'âge
				tc3[1] = string.gsub(tc3[1], "%D", "");
				dlgBackoffice:GetWindowName('deuxvitessea'..idx):SetValue(tc3[1]);
			else
				dlgBackoffice:GetWindowName('deuxvitesseb'..idx):SetValue(tc3[1]);
			end
			if string.find(tc3[2], 'a') then	-- on est par année d'âge
				tc3[2] = string.gsub(tc3[2], "%D", "");
				dlgBackoffice:GetWindowName('deuxtechniquea'..idx):SetValue(tc3[2]);
			else
				dlgBackoffice:GetWindowName('deuxtechniqueb'..idx):SetValue(tc3[2]);
			end
		end
	end
end

function AfficheBackOffice()
	dlgBackoffice = wnd.CreateDialog(
		{
		width = listeMinisterielle.dlgPosit.width,
		height = listeMinisterielle.dlgPosit.height,
		x = listeMinisterielle.dlgPosit.x,
		y = listeMinisterielle.dlgPosit.y,
		label='Gestion des critères', 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgBackoffice:LoadTemplateXML({ 
		xml = './process/liste_ministerielle.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'backoffice', 		-- Facultatif si le node_name est unique ...
		params = {Affichage = listeMinisterielle.affichage}
	});

	-- remplissage des Combo
	dlgBackoffice:GetWindowName('comboNiveau'):Append("Releve");
	dlgBackoffice:GetWindowName('comboNiveau'):Append("Espoirs");
	-- dlgBackoffice:GetWindowName('comboNiveau'):Append("Accès CNE");
	-- dlgBackoffice:GetWindowName('comboNiveau'):Append("Accès CIE");
	dlgBackoffice:GetWindowName('comboSexe'):Append("Dames");
	dlgBackoffice:GetWindowName('comboSexe'):Append("Hommes");
	dlgBackoffice:GetWindowName('comboNiveau'):SetValue(listeMinisterielle.comboNiveau);
	dlgBackoffice:GetWindowName('comboSexe'):SetValue(listeMinisterielle.comboSexe);
	local debut = tonumber(listeMinisterielle.Saison) - 27;
	-- lecture des nodes
	for i = 1, 10 do
		debut = debut + 1;
		dlgBackoffice:GetWindowName('annee'..i):SetValue(debut);
		node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i)
		if node then
			AfficheNode(node, i);
		else
			app.GetAuiFrame():MessageBox(
			"Erreur de lecture du fichier XML !!", 
			"Erreur !!!",
			msgBoxStyle.OK + msgBoxStyle.ICON_WARNING); 
		end
	end
	
	-- Toolbar 
	local tbedit1 = dlgBackoffice:GetWindowName('tbedit1');
	local btnSaveEdit = tbedit1:AddTool("Enregistrer", "./res/vpe32x32_save.png");
	tbedit1:AddSeparator();
	local btnRetour = tbedit1:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit1:AddSeparator();
	tbedit1:Realize();
	
	-- Bind
	tbedit1:Bind(eventType.MENU, OnSavedlgBackoffice, btnSaveEdit);
	tbedit1:Bind(eventType.MENU, function(evt) dlgBackoffice:EndModal(idButton.CANCEL) end, btnRetour);
	dlgBackoffice:Bind(eventType.COMBOBOX, 
		function(evt)
			listeMinisterielle.comboNiveau = dlgBackoffice:GetWindowName('comboNiveau'):GetValue();
			for i = 1, 10 do
				local node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i);
				if node then
					AfficheNode(node, i);
				else
					app.GetAuiFrame():MessageBox(
					"Erreur de lecture du fichier XML !!", 
					"Erreur !!!",
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
				end
			end
		end, 
		dlgBackoffice:GetWindowName('comboNiveau'))
		
	dlgBackoffice:Bind(eventType.COMBOBOX, 
		function(evt) 
			listeMinisterielle.comboSexe = dlgBackoffice:GetWindowName('comboSexe'):GetValue();
			for i = 1, 10 do
				local node = GetNodex(listeMinisterielle.comboNiveau, listeMinisterielle.comboSexe, i)
				if node then
					AfficheNode(node, i);
				else
					app.GetAuiFrame():MessageBox(
					"Erreur de lecture du fichier XML !!", 
					"Erreur !!!",
					msgBoxStyle.OK + msgBoxStyle.ICON_WARNING);
				end
			end
		end, 
		dlgBackoffice:GetWindowName('comboSexe'))
	dlgBackoffice:Fit();
	dlgBackoffice:ShowModal();
end

function AffichagedlgConfiguration()

	-- Creation de la boîte de dialogue
	dlgConfig = wnd.CreateDialog(
		{
		width = listeMinisterielle.dlgPosit.width,
		height = listeMinisterielle.dlgPosit.height,
		x = listeMinisterielle.dlgPosit.x,
		y = listeMinisterielle.dlgPosit.y,
		label='Configuration des paramètres', 
		icon='./res/32x32_ffs.png'
		});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgConfig:LoadTemplateXML({ 
		xml = './process/liste_ministerielle.xml', 	-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'configgenerale', 		-- Facultatif si le node_name est unique ...
		params = {Affichage = listeMinisterielle.affichage}
	});

	-- remplissage des Combo
	dlgConfig:GetWindowName('comboNiveau'):Append("Relève");
	dlgConfig:GetWindowName('comboNiveau'):Append("Espoirs");
	-- dlgConfig:GetWindowName('comboNiveau'):Append("Accès CNE");
	-- dlgConfig:GetWindowName('comboNiveau'):Append("Accès CIE");
	dlgConfig:GetWindowName('comboSexe'):Append("Dames");
	dlgConfig:GetWindowName('comboSexe'):Append("Hommes");
	dlgConfig:GetWindowName('comboListe'):Clear();
	local debut = tonumber(listeMinisterielle.Saison) - 27;
	for i = 1, 10 do
		debut = debut + 1;
		dlgConfig:GetWindowName('comboAnneeDebut'):Append(debut);
		dlgConfig:GetWindowName('comboAnneeFin'):Append(debut);
	end
	for row = 0, Liste:GetNbRows() -1 do
		dlgConfig:GetWindowName('comboListe'):Append(Liste:GetCell('Code_liste', row));
	end
	dlgConfig:GetWindowName('comboListe'):SetValue(listeMinisterielle.comboListe);
	dlgConfig:GetWindowName('comboNiveau'):SetValue(listeMinisterielle.comboNiveau);
	dlgConfig:GetWindowName('comboSexe'):SetValue(listeMinisterielle.comboSexe);
	dlgConfig:GetWindowName('comboAnneeDebut'):SetValue(listeMinisterielle.comboAnneeDebut);
	dlgConfig:GetWindowName('comboAnneeFin'):SetValue(listeMinisterielle.comboAnneeFin);
	-- lecture des nodes
	SetDataAnalyse();
	
	local cmd = '';
	-- Toolbar 
	local tbedit1 = dlgConfig:GetWindowName('tbedit1');
	tbedit1:AddSeparator();
	local btnAnalyse = tbedit1:AddTool("Lancer l'analyse", "./res/32x32_ranking.png");
	tbedit1:AddSeparator();
	local btnGestion = tbedit1:AddTool("Back Office", "./res/32x32_param.png");
	tbedit1:AddSeparator();
	local btnRetour = tbedit1:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit1:AddSeparator();
	tbedit1:Realize();

	
	-- Bind
	tbedit1:Bind(eventType.MENU, 
		function(evt) 
			BuildClassementCoureur();
		end, btnAnalyse);
	tbedit1:Bind(eventType.MENU, 
		function(evt) 
			AfficheBackOffice();
		end, btnGestion);
	tbedit1:Bind(eventType.MENU, function(evt) dlgConfig:EndModal(idButton.CANCEL) end, btnRetour);
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			listeMinisterielle.comboListe = tonumber(dlgConfig:GetWindowName('comboListe'):GetValue()) or 0;
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboListe'))
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt)
			listeMinisterielle.comboNiveau = dlgConfig:GetWindowName('comboNiveau'):GetValue();
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboNiveau'))
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			listeMinisterielle.comboSexe = dlgConfig:GetWindowName('comboSexe'):GetValue();
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboSexe'))
	dlgConfig:Bind(eventType.COMBOBOX, 
		function(evt) 
			listeMinisterielle.comboAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetValue();
			listeMinisterielle.indexAnneeDebut = dlgConfig:GetWindowName('comboAnneeDebut'):GetSelection();
			dlgConfig:GetWindowName('comboAnneeFin'):SetValue(listeMinisterielle.comboAnneeDebut);
			SetDataAnalyse();
		end, 
		dlgConfig:GetWindowName('comboAnneeDebut'))
		
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
		end, 
		dlgConfig:GetWindowName('gxpremiersc1a'))
	dlgConfig:Bind(eventType.TEXT, 
		function(evt) 
		end, 
		dlgConfig:GetWindowName('gxpremiersc1b'))
	dlgConfig:Bind(eventType.CHECKBOX,
		function(evt) 
			dlgConfig:GetWindowName('gxpremiersc1b'):Enable(dlgConfig:GetWindowName('chkouc1b'):GetValue()); 
		end, dlgConfig:GetWindowName('chkouc1b'))
		
	dlgConfig:Bind(eventType.CHECKBOX,
		function(evt) 
			dlgConfig:GetWindowName('gxpremiersc2b'):Enable(dlgConfig:GetWindowName('chkouc2b'):GetValue()); 
		end, dlgConfig:GetWindowName('chkouc2b'))
	dlgConfig:Fit();
	dlgConfig:ShowModal();
	if base then
		base:Delete()
	end
	if doc then
		doc:Delete();
	end
	if doc_cfg then
		doc_cfg:Delete();
	end
end

function main(cparams)

	XML_cfg = app.GetPath().."/liste_ministerielle_cfg.xml";
	if not app.FileExists(XML_cfg) then
		CreateXmlCfg();
	end
	doc_cfg = xmlDocument.Create(XML_cfg);
	XML = app.GetPath().."/process/liste_ministerielle.xml";
	doc = xmlDocument.Create(XML);
	listeMinisterielle = {};
	listeMinisterielle.affichage = false;	
	script_version = "2.7"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.2,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 
		indice_return = 7;
		local url = 'https://agilsport.fr/bta_alpin/versionsPG.txt'
		version = curl.AsyncGET(wnd.GetParentFrame(), url);
	end

	local updatefile = './tmp/updatesPG.txt';
	if app.FileExists(updatefile) then
		local f = io.open(updatefile, 'r')
		for lines in f:lines() do
			alire = lines;
		end
		io.close(f);
		app.RemoveFile(updatefile);
		app.LaunchDefaultEditor('./'..alire);
	end
	
	-- app.GetAuiFrame():MessageBox(
	-- "Vous n'avez plus accès à ce développement.", 
	-- "Erreur !!!",
	-- msgBoxStyle.OK + msgBoxStyle.ICON_WARNING); 
	-- do return false; end

	listeMinisterielle.dlgPosit = {};
	listeMinisterielle.dlgPosit.width = display:GetSize().width * .7;
	listeMinisterielle.dlgPosit.height = display:GetSize().height * .9;
	listeMinisterielle.dlgPosit.x = (display:GetSize().width - listeMinisterielle.dlgPosit.width) / 2;
	listeMinisterielle.dlgPosit.y = (display:GetSize().height - listeMinisterielle.dlgPosit.height) / 3;
	listeMinisterielle.debug = false;
	base = sqlBase.Clone();
	Liste = base:GetTable('Liste');
	local cmd = "SELECT * FROM Liste WHERE Type_classement = 'IAU' ORDER BY Seasoncode DESC, Code_liste DESC";
	base:TableLoad(Liste, cmd);
	listeMinisterielle.Saison = Liste:GetCell('Seasoncode', 0);
	
	-- listeMinisterielle.Saison = listeMinisterielle.Saison - 1; -- pour voir les critères n-1 
	
	listeMinisterielle.comboAnneeDebut = tonumber(listeMinisterielle.Saison) -24;
	listeMinisterielle.indexAnneeDebut = 2;
	listeMinisterielle.comboAnneeFin = tonumber(listeMinisterielle.Saison) -22;
	listeMinisterielle.indexAnneeFin = listeMinisterielle.indexAnneeDebut + 2;
	listeMinisterielle.par_annee = false;
	listeMinisterielle.comboListe = Liste:GetCellInt('Code_liste',0);
	listeMinisterielle.comboSexe = "Dames";
	listeMinisterielle.comboNiveau = "Relève";
	Discipline = base:GetTable('Discipline');
	ChargeDisciplines();
	Evenement_Matrice = base:GetTable('Evenement_Matrice');
	Type_Classement = base:GetTable('Type_Classement');
	tSexe = {'F', 'M'};
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
	AffichagedlgConfiguration();
end

if not listeMinisterielle then
	main()
end
