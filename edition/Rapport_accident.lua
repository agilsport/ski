-- Saisie du rapport d'accident pour skiFFS
--2.5

dofile('./interface/adv.lua');
dofile('./interface/interface.lua');

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

-- Point Entree Principal
function main(params)
	version_script = '2.5';
	dlgrapport = {}
	Tablerapport = {}
	theParams = params;

	-- local widthMax = display:GetSize().width;
	-- local widthControl = math.floor((widthMax*3)/4);
	-- local x = math.floor((widthMax-widthControl)/2);

	-- local heightMax = display:GetSize().height;
	-- local heightControl = math.floor((heightMax *3) / 4);
	-- local y = math.floor((heightMax-heightControl)/2);
	
	base = sqlBase.Clone();
	tEvenement = base:GetTable('Evenement');
	base:TableLoad(tEvenement, 'Select * From Evenement Where Code = '..params.code_evenement);
	tResultat = base:GetTable('Resultat');
	base:TableLoad(tResultat, 'Select * From Resultat Where Code_evenement = '..params.code_evenement);
	tEpreuve = base:GetTable('Epreuve');
	base:TableLoad(tEpreuve, 'Select * From Epreuve Where Code_evenement = '..params.code_evenement);
	tDiscipline = base:GetTable('Discipline');
	tRapport = base:GetTable('Rap_accident');
	CodeEvenement = theParams.code_evenement;
	codex = tEvenement:GetCell('Codex', 0);
	alert('codex'..codex)
	saison = tEvenement:GetCell('Code_saison: ', 0);
	-- on charge la table et on la copie dans une autre table et on l'inserer dans la base pour qu'elle soit detruite quand on sort des editions 
	Evenement_Officiel = base:GetTable('Evenement_Officiel');
	base:TableLoad(Evenement_Officiel, "Select * From Evenement_Officiel Where Code_evenement = "..CodeEvenement);
		
		-- tOfficielRequired = tOfficiel:Copy(); -->
		-- tOfficielRequired:SetName('Officiel_Required'); 
		-- base:AddTable(tOfficielRequired);
	--alert("Order By="..tRapport:OrderByPrimary());
	
	dlgrapport = wnd.CreateDialog({	x = 500,	-- decalage / au bord gauche de l'ecran
									y = 5,  -- decalage / au ht de l'ecran
									--width =  display:GetSize().width - 1100,
									--height = display:GetSize().height - 400;
									width=1100, -- widthControl, 
									height=400, -- heightControl, 
									style=wndStyle.CAPTION+wndStyle.CLOSE_BOX, -- pour rendre la fenetre rezizable  wndStyle.RESIZE_BORDER+
								label='Saisie du rapport: '..tEvenement:GetCell('Nom', 0), 
								icon='./res/32x32_ffs.png'
								});

	-- Creation des Controles et Placement des controles par le Template XML ...
	dlgrapport:LoadTemplateXML({ 	xml = './edition/Rapport_accident.xml', 	-- Obligatoire
										node_name = 'root/panel', 			-- Obligatoire
										node_attr = 'name', 				-- Facultatif si le node_name est unique ...
										node_value = 'config_rapport' 		-- Facultatif si le node_name est unique ...
									});

	if codex == '' then 
		if dlgrapport:MessageBox("Avertissement ?\n\nL'évènement n'a pas de codex \n\n Veuillez mettre un codex dans les paramètres évènements", "Paramètres manquants", msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION) == msgBoxStyle.OK then
			return;
		end
	else
	-- remplissage des Combo
		cmd = "Select * From Rap_accident Where Code_saison = '"..saison.."' And Evt_codex = '"..codex.."' Order by Num_rapport";	
		Rapport = base:TableLoad(cmd);
		
		
		if tonumber(Rapport:GetNbRows()) > 0 then
			LectNumfichier = LectureNumfichier(tonumber(Rapport:GetNbRows()));
		else	
			LectNumfichier = 0
		end
	end

--Si il y a deja un rapport d'enregistrer on vas cher la valeur du rapport si on créer un nouveau		
	if  tonumber(LectNumfichier) == 0 then
		dlgrapport:GetWindowName('Evt_codex'):SetValue(codex);
		dlgrapport:GetWindowName('Evt_Name'):SetValue(tEvenement:GetCell('Nom', 0));
		dlgrapport:GetWindowName('Evt_activite'):SetValue(tEvenement:GetCell('Code_activite', 0));
		dlgrapport:GetWindowName('Code_saison'):SetValue(tEvenement:GetCell('Code_saison', 0));
		dlgrapport:GetWindowName('Evt_date'):SetValue(tEpreuve:GetCell('Date_epreuve', 0));
		dlgrapport:GetWindowName('Epreuve_lieu'):SetValue(tEvenement:GetCell('Station', 0)..' / '..tEvenement:GetCell('Lieu', 0));
		dlgrapport:GetWindowName('Code_discipline'):SetValue(tEpreuve:GetCell('Code_discipline', 0));
		dlgrapport:GetWindowName('Evt_dt_name'):SetValue(base:GetOfficiel('TechnicalDelegate', 'Nom'):upper()..' '..base:GetOfficiel('TechnicalDelegate', 'Prenom'):sub(1,1):upper()..base:GetOfficiel('TechnicalDelegate', 'Prenom'):sub(2):lower()..' '..base:GetOfficiel(TechnicalDelegate, 'Nation'):Parenthesis());
		-- dlgrapport:GetWindowName('Evt_dt_email'):SetValue(base:GetOfficiel('TechnicalDelegate', 'Email'));
		dlgrapport:GetWindowName('Evt_dt_tel'):SetValue(base:GetOfficiel('TechnicalDelegate', 'Tel_mobile'));
		dlgrapport:GetWindowName('Evt_Med_Name'):SetValue(base:GetOfficiel('Doctor', 'Nom'):upper()..' '..base:GetOfficiel('Doctor', 'Prenom'):sub(1,1):upper()..base:GetOfficiel('Doctor', 'Prenom'):sub(2):lower()..' '..base:GetOfficiel(Doctor, 'Nation'):Parenthesis());
		-- dlgrapport:GetWindowName('Evt_Med_email'):SetValue(base:GetOfficiel('Doctor', 'Email'));
		dlgrapport:GetWindowName('Evt_Med_Tel'):SetValue(base:GetOfficiel('Doctor', 'Tel_mobile'));
		epr_manche = 'Select';
		epr_temps = 'Select un choix dans liste';
		Epr_neige = 'Select un choix dans liste';
		coureur_sexe = 'Select';
		Bles_tete = 'Non';
		Bles_fracture = 'Non';
		Bles_nuque = 'Non';
		Bles_entorse = 'Non'
		Bles_epaule = 'Non';
		Bles_contusion = 'Non';
		Bles_membre_sup = 'Non';
		Bles_plaie = 'Non';
		Bles_bassin = 'Non';
		Bles_ventre = 'Non';
		Bles_membre_inf = 'Non';
		Bles_musculaire = 'Non';
		Bles_genou = 'Non';
		Bles_autres = 'Non';
		Bles_cheville = 'Non';
		Bles_type_autre = 'Non';
		Evacuation = 'Sélectionner';
		Situation = 'Sélectionner';
		Evt_Sec_descip = 'Select un choix dans liste';
	-- recherche du nouveau numero de fichier a incrementer pour ne pas avoir de doublon
		--alert("index NumNewFichier = "..tonumber(Rapport:GetNbRows()));
		indexdernierFichier = tonumber(Rapport:GetNbRows()-1);
		--alert("indexdernierFichier = "..indexdernierFichier);
		NumNewFichier = Rapport:GetCellInt('Num_rapport', indexdernierFichier);
		--alert("NumNewFichier = "..NumNewFichier);
		dlgrapport:GetWindowName('Num_rapport'):SetValue(tonumber(NumNewFichier+1));
		-- valeur par default des checkbox
	else
		-- je recherche les données du rapport à lire
		cmd = "Select * From Rap_accident Where Evt_codex = '"..codex.."' And Num_rapport = "..tonumber(LectNumfichier);	
		LectRapport = base:TableLoad(cmd);
		--alert("LectNumfichier2 = "..LectNumfichier);
		i = 0;
		dlgrapport:GetWindowName('Evt_Name'):SetValue(LectRapport:GetCell('Evt_Name', i));
		dlgrapport:GetWindowName('Evt_date'):SetValue(LectRapport:GetCell('Evt_date', i));
		dlgrapport:GetWindowName('Code_saison'):SetValue(LectRapport:GetCell('Code_saison', i));
		dlgrapport:GetWindowName('Evt_activite'):SetValue(LectRapport:GetCell('Evt_activite', i));
		dlgrapport:GetWindowName('Evt_codex'):SetValue(LectRapport:GetCell('Evt_codex', i));
		dlgrapport:GetWindowName('Num_rapport'):SetValue(LectRapport:GetCell('Num_rapport', i));
		dlgrapport:GetWindowName('Epreuve_lieu'):SetValue(LectRapport:GetCell('Epreuve_lieu', i));
		dlgrapport:GetWindowName('Epreuve_piste'):SetValue(LectRapport:GetCell('Epreuve_piste', i));
		dlgrapport:GetWindowName('Code_discipline'):SetValue(LectRapport:GetCell('Code_discipline', i));
		epr_manche = LectRapport:GetCell('Epr_manche', i);
		dlgrapport:GetWindowName('Acc_heure'):SetValue(LectRapport:GetCell('Acc_heure', i));
		dlgrapport:GetWindowName('Coureur_identite'):SetValue(LectRapport:GetCell('Coureur_identite', i));
		dlgrapport:GetWindowName('Code_coureur'):SetValue(LectRapport:GetCell('Code_coureur', i));
		coureur_sexe = LectRapport:GetCell('Coureur_sexe', i);
		dlgrapport:GetWindowName('Coureur_annee'):SetValue(LectRapport:GetCell('Coureur_annee', i));
		dlgrapport:GetWindowName('Coureur_tel'):SetValue(LectRapport:GetCell('Coureur_tel', i));
		-- dlgrapport:GetWindowName('Coureur_Email'):SetValue(LectRapport:GetCell('Coureur_Email', i));
		dlgrapport:GetWindowName('Evt_cond'):SetValue(LectRapport:GetCell('Evt_cond', i));
		epr_temps = LectRapport:GetCell('Epr_temps', i);
		Bles_tete = LectRapport:GetCell('Bles_tete', i);
		Bles_fracture = LectRapport:GetCell('Bles_fracture', i);
		Bles_nuque = LectRapport:GetCell('Bles_nuque', i);
		Bles_entorse = LectRapport:GetCell('Bles_entorse', i);
		Bles_epaule = LectRapport:GetCell('Bles_epaule', i);
		Bles_contusion = LectRapport:GetCell('Bles_contusion', i);	
		Bles_membre_sup = LectRapport:GetCell('Bles_membre_sup', i);	
		Bles_plaie = LectRapport:GetCell('Bles_plaie', i);	
		Bles_bassin = LectRapport:GetCell('Bles_bassin', i);
		Bles_ventre = LectRapport:GetCell('Bles_ventre', i);	
		Bles_membre_inf = LectRapport:GetCell('Bles_membre_inf', i);	
		Bles_musculaire = LectRapport:GetCell('Bles_musculaire', i);	
		Bles_genou = LectRapport:GetCell('Bles_genou', i);	
		Bles_type_autre = LectRapport:GetCell('Bles_type_autre', i);	
		Bles_cheville = LectRapport:GetCell('Bles_cheville', i);	
		Bles_autres = LectRapport:GetCell('Bles_autres', i);	
		Situation = LectRapport:GetCell('Situation', i);	
		Evacuation = LectRapport:GetCell('Evacuation', i);
		Epr_neige = LectRapport:GetCell('Epr_neige', i);
		-- si la valeur Evt_dt_name dans la table rapaccident est vide et si la valeur du nom du DY est rempli dans la table evenement_officiel je prend les valeurs de la table evenement officiel 
		if LectRapport:GetCell('Evt_dt_name', i) == '' and base:GetOfficiel('TechnicalDelegate', 'Nom') ~= '' then
			dlgrapport:GetWindowName('Evt_dt_name'):SetValue(base:GetOfficiel('TechnicalDelegate', 'Nom'):upper()..' '..base:GetOfficiel('TechnicalDelegate', 'Prenom'):sub(1,1):upper()..base:GetOfficiel('TechnicalDelegate', 'Prenom'):sub(2):lower()..' '..base:GetOfficiel(TechnicalDelegate, 'Nation'):Parenthesis());
			-- dlgrapport:GetWindowName('Evt_dt_email'):SetValue(base:GetOfficiel('TechnicalDelegate', 'Email'));
			dlgrapport:GetWindowName('Evt_dt_tel'):SetValue(base:GetOfficiel('TechnicalDelegate', 'Tel_mobile'));
		else
			dlgrapport:GetWindowName('Evt_dt_name'):SetValue(LectRapport:GetCell('Evt_dt_name', i));
			-- dlgrapport:GetWindowName('Evt_dt_email'):SetValue(LectRapport:GetCell('Evt_dt_email', i));	
			dlgrapport:GetWindowName('Evt_dt_tel'):SetValue(LectRapport:GetCell('Evt_dt_tel', i));	
		end
		-- idem que pour le dt
		if LectRapport:GetCell('Evt_dt_name', i) == '' and base:GetOfficiel('TechnicalDelegate', 'Nom') ~= '' then
			dlgrapport:GetWindowName('Evt_Med_Name'):SetValue(base:GetOfficiel('Doctor', 'Nom'):upper()..' '..base:GetOfficiel('Doctor', 'Prenom'):sub(1,1):upper()..base:GetOfficiel('Doctor', 'Prenom'):sub(2):lower()..' '..base:GetOfficiel(Doctor, 'Nation'):Parenthesis());
			-- dlgrapport:GetWindowName('Evt_Med_email'):SetValue(base:GetOfficiel('Doctor', 'Email'));
			dlgrapport:GetWindowName('Evt_Med_Tel'):SetValue(base:GetOfficiel('Doctor', 'Tel_mobile'));
		else		
			dlgrapport:GetWindowName('Evt_Med_Name'):SetValue(LectRapport:GetCell('Evt_Med_Name', i));	
			-- dlgrapport:GetWindowName('Evt_Med_email'):SetValue(LectRapport:GetCell('Evt_Med_email', i));	
			dlgrapport:GetWindowName('Evt_Med_Tel'):SetValue(LectRapport:GetCell('Evt_Med_Tel', i));
		end
		Evt_Sec_descip = LectRapport:GetCell('Evt_Sec_descip', i);
		dlgrapport:GetWindowName('Evt_Sec_Name'):SetValue(LectRapport:GetCell('Evt_Sec_Name', i));	
		-- dlgrapport:GetWindowName('Evt_Sec_email'):SetValue(LectRapport:GetCell('Evt_Sec_email', i));	
		dlgrapport:GetWindowName('Evt_Sec_Tel'):SetValue(LectRapport:GetCell('Evt_Sec_Tel', i));	
		dlgrapport:GetWindowName('Evt_Tem1_Name'):SetValue(LectRapport:GetCell('Evt_Tem1_Name', i));	
		-- dlgrapport:GetWindowName('Evt_Tem1_email'):SetValue(LectRapport:GetCell('Evt_Tem1_email', i));
		dlgrapport:GetWindowName('Evt_Tem1_Tel'):SetValue(LectRapport:GetCell('Evt_Tem1_Tel', i));
		dlgrapport:GetWindowName('Evt_Tem2_Name'):SetValue(LectRapport:GetCell('Evt_Tem2_Name', i));	
		-- dlgrapport:GetWindowName('Evt_Tem2_email'):SetValue(LectRapport:GetCell('Evt_Tem2_email', i));	
		dlgrapport:GetWindowName('Evt_Tem2_Tel'):SetValue(LectRapport:GetCell('Evt_Tem2_Tel', i));	
		dlgrapport:GetWindowName('Evt_Tem3_Name'):SetValue(LectRapport:GetCell('Evt_Tem3_Name', i));	
		-- dlgrapport:GetWindowName('Evt_Tem3_email'):SetValue(LectRapport:GetCell('Evt_Tem3_email', i));	
		dlgrapport:GetWindowName('Evt_Tem3_Tel'):SetValue(LectRapport:GetCell('Evt_Tem3_Tel', i));
		dlgrapport:GetWindowName('Rap_commentaire'):SetValue(LectRapport:GetCell('Rap_commentaire', i));	
	end

	-- creation des combo
		-- combo temps
		dlgrapport:GetWindowName('Epr_temps'):Clear();
		dlgrapport:GetWindowName('Epr_temps'):Append('Beau');
		dlgrapport:GetWindowName('Epr_temps'):Append('Couvert');
		dlgrapport:GetWindowName('Epr_temps'):Append('Neigeux');
		dlgrapport:GetWindowName('Epr_temps'):Append('Brouillard');
		dlgrapport:GetWindowName('Epr_temps'):Append('Jour blanc');
		dlgrapport:GetWindowName('Epr_temps'):Append('Pluvieux');
		dlgrapport:GetWindowName('Epr_temps'):Append('Lumière artificielle');
		dlgrapport:GetWindowName('Epr_temps'):Append('Select un choix dans liste');
		dlgrapport:GetWindowName('Epr_temps'):SetValue(epr_temps);

	-- combo Epr_neige
		dlgrapport:GetWindowName('Epr_neige'):Clear();
		dlgrapport:GetWindowName('Epr_neige'):Append('Soupe');
		dlgrapport:GetWindowName('Epr_neige'):Append('Mole');
		dlgrapport:GetWindowName('Epr_neige'):Append('Poudreuse');
		dlgrapport:GetWindowName('Epr_neige'):Append('Dure');
		dlgrapport:GetWindowName('Epr_neige'):Append('Verglas');
		dlgrapport:GetWindowName('Epr_neige'):Append('Select un choix dans liste');
		dlgrapport:GetWindowName('Epr_neige'):SetValue(Epr_neige);		
		-- combo sexe
		dlgrapport:GetWindowName('Coureur_sexe'):Clear();
		dlgrapport:GetWindowName('Coureur_sexe'):Append('Dames');
		dlgrapport:GetWindowName('Coureur_sexe'):Append('Hommes');
		dlgrapport:GetWindowName('Coureur_sexe'):Append('Select');
		dlgrapport:GetWindowName('Coureur_sexe'):SetValue(coureur_sexe);
		
		-- combo sexe
		dlgrapport:GetWindowName('Epr_manche'):Clear();
		dlgrapport:GetWindowName('Epr_manche'):Append('1');
		dlgrapport:GetWindowName('Epr_manche'):Append('2');
		dlgrapport:GetWindowName('Epr_manche'):Append('3');
		dlgrapport:GetWindowName('Epr_manche'):Append('Entrainement');
		dlgrapport:GetWindowName('Epr_manche'):Append('Select');
		dlgrapport:GetWindowName('Epr_manche'):SetValue(epr_manche);
		
		-- combo Evt_Sec_descip
		dlgrapport:GetWindowName('Evt_Sec_descip'):Clear();
		dlgrapport:GetWindowName('Evt_Sec_descip'):Append('Services des pistes');
		dlgrapport:GetWindowName('Evt_Sec_descip'):Append('Pompiers');
		dlgrapport:GetWindowName('Evt_Sec_descip'):Append('Medecin de Station');
		dlgrapport:GetWindowName('Evt_Sec_descip'):Append('Select un choix dans liste');
		dlgrapport:GetWindowName('Evt_Sec_descip'):SetValue(Evt_Sec_descip);
		
		-- combo Evacuation
		dlgrapport:GetWindowName('Evacuation'):Clear();
		dlgrapport:GetWindowName('Evacuation'):Append('Barquettes');
		dlgrapport:GetWindowName('Evacuation'):Append('Ambulance');
		dlgrapport:GetWindowName('Evacuation'):Append('Hélicoptère');
		dlgrapport:GetWindowName('Evacuation'):Append('Pas évacuation');
		dlgrapport:GetWindowName('Evacuation'):Append('Sélectionner');
		dlgrapport:GetWindowName('Evacuation'):SetValue(Evacuation);
		
		-- combo Situation
		dlgrapport:GetWindowName('Situation'):Clear();
		dlgrapport:GetWindowName('Situation'):Append('Encourse');
		dlgrapport:GetWindowName('Situation'):Append('Entrainement');
		dlgrapport:GetWindowName('Situation'):Append('Remontée mécanique');
		dlgrapport:GetWindowName('Situation'):Append('Sélectionner');
		dlgrapport:GetWindowName('Situation'):SetValue(Situation);
		
		-- combo Bles_tete
		dlgrapport:GetWindowName('Bles_tete'):Clear();
		dlgrapport:GetWindowName('Bles_tete'):Append('Oui coté droit');
		dlgrapport:GetWindowName('Bles_tete'):Append('Oui coté Gauche');
		dlgrapport:GetWindowName('Bles_tete'):Append('Non');
		dlgrapport:GetWindowName('Bles_tete'):SetValue(Bles_tete);
		
		-- combo Bles_Fracture
		dlgrapport:GetWindowName('Bles_fracture'):Clear();
		dlgrapport:GetWindowName('Bles_fracture'):Append('Oui');
		dlgrapport:GetWindowName('Bles_fracture'):Append('Non');
		dlgrapport:GetWindowName('Bles_fracture'):SetValue(Bles_fracture);

	-- combo Bles_nuque
		dlgrapport:GetWindowName('Bles_nuque'):Clear();
		dlgrapport:GetWindowName('Bles_nuque'):Append('Oui');
		dlgrapport:GetWindowName('Bles_nuque'):Append('Non');
		dlgrapport:GetWindowName('Bles_nuque'):SetValue(Bles_nuque);

	-- combo Nuque - Bles_Entorse: 
		dlgrapport:GetWindowName('Bles_entorse'):Clear();
		dlgrapport:GetWindowName('Bles_entorse'):Append('Oui');
		dlgrapport:GetWindowName('Bles_entorse'):Append('Non');
		dlgrapport:GetWindowName('Bles_entorse'):SetValue(Bles_entorse);
	
	-- combo Bles_tete
		dlgrapport:GetWindowName('Bles_epaule'):Clear();
		dlgrapport:GetWindowName('Bles_epaule'):Append('Oui coté droit');
		dlgrapport:GetWindowName('Bles_epaule'):Append('Oui coté Gauche');
		dlgrapport:GetWindowName('Bles_epaule'):Append('Non');
		dlgrapport:GetWindowName('Bles_epaule'):SetValue(Bles_epaule);

	-- combo Nuque - Bles_Contusion: 
		dlgrapport:GetWindowName('Bles_contusion'):Clear();
		dlgrapport:GetWindowName('Bles_contusion'):Append('Oui');
		dlgrapport:GetWindowName('Bles_contusion'):Append('Non');
		dlgrapport:GetWindowName('Bles_contusion'):SetValue(Bles_contusion);
	
	-- combo Bles_membre_sup
		dlgrapport:GetWindowName('Bles_membre_sup'):Clear();
		dlgrapport:GetWindowName('Bles_membre_sup'):Append('Oui coté droit');
		dlgrapport:GetWindowName('Bles_membre_sup'):Append('Oui coté Gauche');
		dlgrapport:GetWindowName('Bles_membre_sup'):Append('Non');
		dlgrapport:GetWindowName('Bles_membre_sup'):SetValue(Bles_membre_sup);

	-- combo Nuque - Bles_Plaie: 
		dlgrapport:GetWindowName('Bles_plaie'):Clear();
		dlgrapport:GetWindowName('Bles_plaie'):Append('Oui');
		dlgrapport:GetWindowName('Bles_plaie'):Append('Non');
		dlgrapport:GetWindowName('Bles_plaie'):SetValue(Bles_plaie);

	-- combo Nuque - Bles_Contusion: 
		dlgrapport:GetWindowName('Bles_bassin'):Clear();
		dlgrapport:GetWindowName('Bles_bassin'):Append('Oui');
		dlgrapport:GetWindowName('Bles_bassin'):Append('Non');
		dlgrapport:GetWindowName('Bles_bassin'):SetValue(Bles_bassin);
	
	-- combo Nuque - Bles_Contusion: 
		dlgrapport:GetWindowName('Bles_ventre'):Clear();
		dlgrapport:GetWindowName('Bles_ventre'):Append('Oui');
		dlgrapport:GetWindowName('Bles_ventre'):Append('Non');
		dlgrapport:GetWindowName('Bles_ventre'):SetValue(Bles_ventre);

	-- combo Bles_membre_sup
		dlgrapport:GetWindowName('Bles_membre_inf'):Clear();
		dlgrapport:GetWindowName('Bles_membre_inf'):Append('Oui coté droit');
		dlgrapport:GetWindowName('Bles_membre_inf'):Append('Oui coté Gauche');
		dlgrapport:GetWindowName('Bles_membre_inf'):Append('Non');
		dlgrapport:GetWindowName('Bles_membre_inf'):SetValue(Bles_membre_inf);

	-- combo Nuque - Bles_Contusion: 
		dlgrapport:GetWindowName('Bles_musculaire'):Clear();
		dlgrapport:GetWindowName('Bles_musculaire'):Append('Oui');
		dlgrapport:GetWindowName('Bles_musculaire'):Append('Non');
		dlgrapport:GetWindowName('Bles_musculaire'):SetValue(Bles_musculaire);
		
	-- combo Bles_genou
		dlgrapport:GetWindowName('Bles_genou'):Clear();
		dlgrapport:GetWindowName('Bles_genou'):Append('Oui coté droit');
		dlgrapport:GetWindowName('Bles_genou'):Append('Oui coté Gauche');
		dlgrapport:GetWindowName('Bles_genou'):Append('Non');
		dlgrapport:GetWindowName('Bles_genou'):SetValue(Bles_genou);
		
	-- combo Bles_membre_sup
		dlgrapport:GetWindowName('Bles_autres'):Clear();
		dlgrapport:GetWindowName('Bles_autres'):Append('Je ne sais pas');
		dlgrapport:GetWindowName('Bles_autres'):Append('non');
		dlgrapport:GetWindowName('Bles_autres'):Append('Autres');
		dlgrapport:GetWindowName('Bles_autres'):SetValue(Bles_autres);	
		
	-- combo Bles_membre_sup
		dlgrapport:GetWindowName('Bles_cheville'):Clear();
		dlgrapport:GetWindowName('Bles_cheville'):Append('Oui coté droit');
		dlgrapport:GetWindowName('Bles_cheville'):Append('Oui coté Gauche');
		dlgrapport:GetWindowName('Bles_cheville'):Append('Non');
		dlgrapport:GetWindowName('Bles_cheville'):SetValue(Bles_cheville);

		-- combo Bles_membre_sup
		dlgrapport:GetWindowName('Bles_type_autre'):Clear();
		dlgrapport:GetWindowName('Bles_type_autre'):Append('Je ne sais pas');
		dlgrapport:GetWindowName('Bles_type_autre'):Append('non');
		dlgrapport:GetWindowName('Bles_type_autre'):Append('Autres');
		dlgrapport:GetWindowName('Bles_type_autre'):SetValue(Bles_type_autre);	
		
	-- Toolbar 
	local tbedit = dlgrapport:GetWindowName('tbedit');
	local btnOndelete = tbedit:AddTool("Effacer", "./res/32x32_clear.png");
	tbedit:AddSeparator();
	tbedit:AddStretchableSpace();
	tbedit:AddSeparator();
	local btnOnsave = tbedit:AddTool("Enregistrer", "./res/32x32_save.png");
	tbedit:AddSeparator();
	local btnOnImprim = tbedit:AddTool("Imprimer", "./res/vpe32x32_print.png");
	tbedit:AddSeparator();
	tbedit:AddStretchableSpace();
	local btnRetour = tbedit:AddTool("Sortie", "./res/32x32_exit.png");
	tbedit:Realize();
	
	tbedit:Bind(eventType.MENU, Ondelete, btnOndelete);
	tbedit:Bind(eventType.MENU, Onsave, btnOnsave);
	tbedit:Bind(eventType.MENU, OnImprim, btnOnImprim);
	tbedit:Bind(eventType.MENU, Onupdate, btnOnupdate);
	tbedit:Bind(eventType.MENU, function(evt) dlgrapport:EndModal(idButton.CANCEL); end, btnRetour);
	
	
	
	dlgrapport:Fit();
	dlgrapport:ShowModal();
	dlgrapport:Delete();

end

function LectureNumfichier(NumFichier)
	local widthMax = display:GetSize().width;
	local widthControl = math.floor((widthMax*3)/4);
	local x = math.floor((widthMax-widthControl)/2);

	local heightMax = display:GetSize().height;
	local heightControl = math.floor((heightMax *3) / 4);
	local y = math.floor((heightMax-heightControl)/2);

	dlg = wnd.CreateDialog({
		x = x,
		y = y,
		width=350, -- widthControl, 
		height=170, -- heightControl,hauteur 
		label='Choix du numero de rapport', 
		icon='./res/32x32_agil.png'
	});
	alert("NumFichier"..NumFichier)
	-- Creation des Controles et Placement des controles par le Template XML ...
	dlg:LoadTemplateXML({ 
		xml = './process/Rapport_accident.xml', 		-- Obligatoire
		node_name = 'root/panel', 			-- Obligatoire
		node_attr = 'name', 				-- Facultatif si le node_name est unique ...
		node_value = 'NumFichier',			-- Facultatif si le node_name est unique ...	
	});

	-- Initialisation des controles ...
	local comboNumFichier = dlg:GetWindowName('NumFichier');
	
	-- combo NumFichier
		-- dlg:GetWindowName('NumFichier'):Clear();
	for i=0, NumFichier do
		NumFichierAlire = Rapport:GetCellInt('Num_rapport', i);
		-- alert("NumFichier a lire = "..NumFichierAlire);
		dlg:GetWindowName('NumFichier'):Append(NumFichierAlire);
	end

		dlg:GetWindowName('NumFichier'):SetValue(0);
	
	local tb = dlg:GetWindowName('tb');
	
	
	if tb then
		local btn_edition = tb:AddTool('OK', './res/16x16_xml.png');
		tb:AddStretchableSpace();
		local btn_close = tb:AddTool('Annuler', './res/16x16_close.png');
		tb:Realize();
		tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.OK); end, btn_edition);
		tb:Bind(eventType.MENU, function(evt) dlg:EndModal(idButton.CANCEL); end, btn_close);
	end
	
	if dlg:ShowModal() == idButton.OK then
			return dlg:GetWindowName('NumFichier'):GetValue('NumFichier');	 
	else
		return 0 ;
	end

	dlg:Fit();
	dlg:ShowModal();
	
	dlg:EndModal();
	-- Liberation Memoire
	dlg:Delete();
end

-- insert d'une ligne dans la table TabletagID_Passings
function Onsave()		
	if dlgrapport:MessageBox("Confirmation l\' enregistrement ?\n\nCette opération vas enregistrer le rapport N° "..dlgrapport:GetWindowName('Num_rapport'):GetValue()..".", "Confirmation de l'enregistrement", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	local r = tRapport:AddRow();
				tRapport:SetCell('Code_saison', r, tonumber(dlgrapport:GetWindowName('Code_saison'):GetValue()));
				tRapport:SetCell('Evt_codex', r, dlgrapport:GetWindowName('Evt_codex'):GetValue());
				tRapport:SetCell('Num_rapport', r, tonumber(dlgrapport:GetWindowName('Num_rapport'):GetValue()));
				tRapport:SetCell('Code', r, tonumber(tEvenement:GetCell('Code', 0)));
				tRapport:SetCell('Evt_Name', r, dlgrapport:GetWindowName('Evt_Name'):GetValue());
				tRapport:SetCell('Evt_date', r, tEpreuve:GetCell('Date_epreuve', 0, '%4Y/%2M/%2D'));
				--alert("date epre"..Epreuve:GetCell('Date_epreuve', 0, '%4Y/%2M/%2D'));
				tRapport:SetCell('Evt_activite', r, dlgrapport:GetWindowName('Evt_activite'):GetValue());
				tRapport:SetCell('Epreuve_lieu', r, dlgrapport:GetWindowName('Epreuve_lieu'):GetValue());
				--tRapport:SetCell('Epreuve_lieu', r, string.EscapeQuote(dlgrapport:GetWindowName('Epreuve_lieu'):GetValue()));  fonction qui met le code asci pour inserer dans la base
				tRapport:SetCell('Epreuve_piste', r, dlgrapport:GetWindowName('Epreuve_piste'):GetValue());
				tRapport:SetCell('Code_discipline', r, dlgrapport:GetWindowName('Code_discipline'):GetValue());
				tRapport:SetCell('Epr_manche', r, dlgrapport:GetWindowName('Epr_manche'):GetValue());
				tRapport:SetCell('Acc_heure', r, dlgrapport:GetWindowName('Acc_heure'):GetValue());
				tRapport:SetCell('Coureur_identite', r, dlgrapport:GetWindowName('Coureur_identite'):GetValue());
				tRapport:SetCell('Code_coureur', r, dlgrapport:GetWindowName('Code_coureur'):GetValue());
				tRapport:SetCell('Coureur_sexe', r, dlgrapport:GetWindowName('Coureur_sexe'):GetValue());
				tRapport:SetCell('Coureur_annee', r, dlgrapport:GetWindowName('Coureur_annee'):GetValue());
				tRapport:SetCell('Coureur_tel', r, dlgrapport:GetWindowName('Coureur_tel'):GetValue());
				-- tRapport:SetCell('Coureur_Email', r, dlgrapport:GetWindowName('Coureur_Email'):GetValue());
				tRapport:SetCell('Evt_cond', r, dlgrapport:GetWindowName('Evt_cond'):GetValue());
				tRapport:SetCell('Epr_temps', r, dlgrapport:GetWindowName('Epr_temps'):GetValue());
				tRapport:SetCell('Bles_tete', r, dlgrapport:GetWindowName('Bles_tete'):GetValue());
				tRapport:SetCell('Bles_fracture', r, dlgrapport:GetWindowName('Bles_fracture'):GetValue());
				tRapport:SetCell('Bles_nuque', r, dlgrapport:GetWindowName('Bles_nuque'):GetValue());
				tRapport:SetCell('Bles_entorse', r, dlgrapport:GetWindowName('Bles_entorse'):GetValue());
				tRapport:SetCell('Bles_epaule', r, dlgrapport:GetWindowName('Bles_epaule'):GetValue());
				tRapport:SetCell('Bles_contusion', r, dlgrapport:GetWindowName('Bles_contusion'):GetValue());
				tRapport:SetCell('Bles_membre_sup', r, dlgrapport:GetWindowName('Bles_membre_sup'):GetValue());
				tRapport:SetCell('Epr_manche', r, dlgrapport:GetWindowName('Epr_manche'):GetValue());
				tRapport:SetCell('Bles_plaie', r, dlgrapport:GetWindowName('Bles_plaie'):GetValue());
				tRapport:SetCell('Bles_bassin', r, dlgrapport:GetWindowName('Bles_bassin'):GetValue());
				tRapport:SetCell('Bles_ventre', r, dlgrapport:GetWindowName('Bles_ventre'):GetValue());
				tRapport:SetCell('Bles_membre_inf', r, dlgrapport:GetWindowName('Bles_membre_inf'):GetValue());
				tRapport:SetCell('Bles_musculaire', r, dlgrapport:GetWindowName('Bles_musculaire'):GetValue());
				tRapport:SetCell('Bles_genou', r, dlgrapport:GetWindowName('Bles_genou'):GetValue());
				tRapport:SetCell('Bles_type_autre', r, dlgrapport:GetWindowName('Bles_type_autre'):GetValue());
				tRapport:SetCell('Bles_cheville', r, dlgrapport:GetWindowName('Bles_cheville'):GetValue());
				tRapport:SetCell('Bles_autres', r, dlgrapport:GetWindowName('Bles_autres'):GetValue());
				tRapport:SetCell('Situation', r, dlgrapport:GetWindowName('Situation'):GetValue());
				tRapport:SetCell('Evacuation', r, dlgrapport:GetWindowName('Evacuation'):GetValue());
				tRapport:SetCell('Epr_neige', r, dlgrapport:GetWindowName('Epr_neige'):GetValue());
				tRapport:SetCell('Evt_dt_name', r, dlgrapport:GetWindowName('Evt_dt_name'):GetValue());
				-- tRapport:SetCell('Evt_dt_email', r, dlgrapport:GetWindowName('Evt_dt_email'):GetValue());
				tRapport:SetCell('Evt_dt_tel', r, dlgrapport:GetWindowName('Evt_dt_tel'):GetValue());
				tRapport:SetCell('Evt_Med_Name', r, dlgrapport:GetWindowName('Evt_Med_Name'):GetValue());
				-- tRapport:SetCell('Evt_Med_email', r, dlgrapport:GetWindowName('Evt_Med_email'):GetValue());
				tRapport:SetCell('Evt_Med_Tel', r, dlgrapport:GetWindowName('Evt_Med_Tel'):GetValue());
				tRapport:SetCell('Evt_Sec_descip', r, dlgrapport:GetWindowName('Evt_Sec_descip'):GetValue());
				tRapport:SetCell('Evt_Sec_Name', r, dlgrapport:GetWindowName('Evt_Sec_Name'):GetValue());
				-- tRapport:SetCell('Evt_Sec_email', r, dlgrapport:GetWindowName('Evt_Sec_email'):GetValue());
				tRapport:SetCell('Evt_Sec_Tel', r, dlgrapport:GetWindowName('Evt_Sec_Tel'):GetValue());
				tRapport:SetCell('Evt_Tem1_Name', r, dlgrapport:GetWindowName('Evt_Tem1_Name'):GetValue());
				-- tRapport:SetCell('Evt_Tem1_email', r, dlgrapport:GetWindowName('Evt_Tem1_email'):GetValue());
				tRapport:SetCell('Evt_Tem1_Tel', r, dlgrapport:GetWindowName('Evt_Tem1_Tel'):GetValue());
				tRapport:SetCell('Evt_Tem2_Name', r, dlgrapport:GetWindowName('Evt_Tem2_Name'):GetValue());
				-- tRapport:SetCell('Evt_Tem2_email', r, dlgrapport:GetWindowName('Evt_Tem2_email'):GetValue());
				tRapport:SetCell('Evt_Tem2_Tel', r, dlgrapport:GetWindowName('Evt_Tem2_Tel'):GetValue());
				tRapport:SetCell('Evt_Tem3_Name', r, dlgrapport:GetWindowName('Evt_Tem3_Name'):GetValue());
				-- tRapport:SetCell('Evt_Tem3_email', r, dlgrapport:GetWindowName('Evt_Tem3_email'):GetValue());
				tRapport:SetCell('Evt_Tem3_Tel', r, dlgrapport:GetWindowName('Evt_Tem3_Tel'):GetValue());
				tRapport:SetCell('Rap_commentaire', r, dlgrapport:GetWindowName('Rap_commentaire'):GetValue());		
	base:TableFlush(tRapport, r);
end

function OnImprim(NumFichier)

	NumFichier = tonumber(dlgrapport:GetWindowName('Num_rapport'):GetValue());
	alert("NumFichier a imprimer = "..NumFichier);
	--alert("New_NumFichier a imprimer = "..NewNumFichier);
	tRap_accident = base:GetTable('Rap_accident');
	base:TableLoad(tRap_accident, "Select * From Rap_accident Where Code_saison = '"..saison.."' And Evt_codex = '"..codex.."' And Num_rapport = "..NumFichier);

	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/editionRapport_accident.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'rap_accident' ,
		
		-- parent = dlg,
			
		base = base,
		
		params = theParams
	});

end

function Ondelete()
alert("Spression du fichier: "..tonumber(tEvenement:GetCell('Code', 0)));

if dlgrapport:MessageBox("Confirmation de la supprésion ?\n\nCette opération effacera le rapport n°"..LectNumfichier.." de la base de donnée.", "Confirmation mise à jour du rapport", msgBoxStyle.YES_NO+msgBoxStyle.ICON_INFORMATION) ~= msgBoxStyle.YES then
		return;
	end
	cmd = "Delete From Rap_accident Where Code = '"..tonumber(tEvenement:GetCell('Code', 0)).."' and Num_rapport = "..tonumber(LectNumfichier);
	base:Query(cmd);
	dlgrapport:EndModal();
	cmd = "Select * From Rap_accident Where Code_saison = '"..saison.."' And Evt_codex = '"..codex.."' Order by Num_rapport";	
	Rapport = base:TableLoad(cmd);
	--LectureNumfichier(tonumber(Rapport:GetNbRows()));
	main(params);
end
