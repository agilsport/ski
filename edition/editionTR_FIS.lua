dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
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

function AddRowDeviceFIS(brand, device, model, homologationnumber, validuntil, comment)
	if string.find(device, 'Start') then
		device = 'Start';
	end
	if string.find(device, 'Photo') then
		device = 'Photocell';
	end
	local row = Device_FIS:AddRow();
	Device_FIS:SetCell('Brand', row, brand);
	Device_FIS:SetCell('Device', row, device);
	Device_FIS:SetCell('Model', row, model);
	Device_FIS:SetCell('HomologationNumber', row, homologationnumber);
	Device_FIS:SetCell('ValidUntil', row, validuntil);
	Device_FIS:SetCell('Commentaire', row, comment);
	Device.Brand = '';
	Device.Model = '';
	Device.HomologationNumber = '';
	Device.ValidUntil = '';
	Device.Commentaire = '';
end


function CreateDeviceFis()
	local csvfile = './res/tr/FIS-Timing-Devices.csv'
	if not app.FileExists(csvfile) then
		return;
	end
	-- if not app.FileExists('./res/tr/xmlHomologatedDevices.xml') then
		-- return;
	-- end

	-- OK au 12/11/2019
	Device_FIS = sqlTable.Create('Device_FIS');
	Device_FIS:AddColumn({ name = 'Brand', type = sqlType.TEXT, width = 20 });
	Device_FIS:AddColumn({ name = 'Device', type = sqlType.TEXT, width = 20 });
	Device_FIS:AddColumn({ name = 'Model', type = sqlType.TEXT, width = 20 });
	Device_FIS:AddColumn({ name = 'HomologationNumber', type = sqlType.TEXT, width = 20 });
	Device_FIS:AddColumn({ name = 'ValidUntil', type = sqlType.LONG, style = sqlStyle.NULL });
	Device_FIS:AddColumn({ name = 'Commentaire', type = sqlType.TEXT, width = 250 });
	Device_FIS:SetPrimary('Brand', 'Device', 'Model');
	ReplaceTableEnvironnement(Device_FIS, 'Device_FIS');
	AddRowDeviceFIS('-', 'Timer', '', '', '', '');
	AddRowDeviceFIS('-', 'Photocell', '', '', '', '');
	AddRowDeviceFIS('-', 'Start', '', '', '', '');
	local updatefile = './tmp/updatesPG.txt';
	local ligne = 0;
	-- Companyname;Codex;untilseason;Devicemodel;Comments;Description;valid	if app.FileExists(updatefile) then
	-- AddRowDeviceFIS(brand, device, model, homologationnumber, validuntil, comment)					
	-- AGIL;AGI.078T.09;2027;IMHP 870;With external printer;Timer;1
		local f = io.open(csvfile, 'r')
		for lines in f:lines() do
			ligne = ligne + 1;
			alire = lines;
			if ligne > 0 then
				tData = alire:Split(';');
				local brand = tData[1];
				local homologation = tData[2];
				local valid = tonumber(tData[3]) or 0;
				local model = tData[4];
				local comment = tData[5];
				local device = tData[6];
				local ok = tonumber(tData[7]) or 0;
				if ok == 1 then
					AddRowDeviceFIS(brand, device, model, homologation, valid, comment);
				end
			end
			
		end
		io.close(f);

	
	
--lecture du fichier XML des devices et transformation en table MySQL

	-- local xml_devices = './res/tr/xmlHomologatedDevices.xml';
	-- local doc = xmlDocument.Create(xml_devices);
	-- local xmlDevices = doc:SaveString();
	-- local root = doc:GetRoot();
	-- TR.Device_FIS = {};
	-- if root ~= nil then
		-- Device.Commentaire = nil;
		-- LectureDeviceFIS(root);	-- lecture des devices depuis le xml des devices FIS
	-- end
	-- doc:Delete();
	
	Device_FIS:OrderBy('Brand','Model');
	
	Brand_Timer = Device_FIS:Copy();
	ReplaceTableEnvironnement(Brand_Timer, 'Brand_Timer');
	Brand_Timer:Filter("$(Device):In('Timer')", true)
	
	Brand_Photocell = Device_FIS:Copy();
	ReplaceTableEnvironnement(Brand_Photocell, 'Brand_Photocell');
	Brand_Photocell:Filter("$(Device):In('Photocell')", true)

	Brand_Start = Device_FIS:Copy();
	ReplaceTableEnvironnement(Brand_Start, 'Brand_Start');
	Brand_Start:Filter("$(Device):In('Start')", true)

end

function FindRow(tcol, tTable)
	local col = tcol[1];
	local value = tcol[2];
	local r = tTable:GetIndexRow(col, value);
	return r
end

function FindHomologation(model)
	local homologationnumber = "";
	local r = Device_FIS:GetIndexRow("Model", model);
	if r and r >= 0 then
		homologationnumber = Device_FIS:GetCell("HomologationNumber", r);
	end
	return homologationnumber;
end

function OnChangeHeure(ctrl, lngmax, decimale)
	local lngmax = lngmax;
	-- lngmax = =8 Ex : 08:01.00 -> strnumber:len() = 6
	-- lngmax = =12 Ex : 08:01:01.000 -> strnumber:len() = 9
	local value = ctrl:GetValue();
	if value == nil then
		return
	end
	if lngmax == 8 then
		lngmax = 6;
	else
		lngmax = 9;
	end
	
	local strnumber = string.gsub(value, "%D", "");
	if strnumber:len() > lngmax then
		strnumber = string.sub(strnumber, 1, lngmax);
	end
	if strnumber:len() == lngmax then
		if lngmax == 6 then
			strnumber = string.sub(strnumber, 1, 2)..":"..string.sub(strnumber, 3, 4)..":"..string.sub(strnumber, 5, 6);
		elseif lngmax == 9 then
			strnumber = string.sub(strnumber, 1, 2)..":"..string.sub(strnumber, 3, 4)..":"..string.sub(strnumber, 5, 6).."."..string.sub(strnumber, 7);
		end
		ctrl:SetValue(strnumber);
	end
end

function OnSaveXML(filename, bolTout)
	
	if bolTout == false then
		GetDataPage1();
	end
	-- creation de l'arborescence

	doc = xmlDocument.Create();
	nodeFisresults = xmlNode.Create(nil, xmlNodeType.ELEMENT_NODE, "Fisresults");
	doc:SetRoot(nodeFisresults);
	
	xmlNode.Create(nodeFisresults, xmlNodeType.ELEMENT_NODE, "Timingreportversion", "");
	xmlNode.Create(nodeFisresults, xmlNodeType.ELEMENT_NODE, "OSversion", TR.OS);
	xmlNode.Create(nodeFisresults, xmlNodeType.ELEMENT_NODE, "XMLversion", "");
	xmlNode.Create(nodeFisresults, xmlNodeType.ELEMENT_NODE, "Draft", "1");
	
	-- race header
	
	if bolTout == true then
		nodeRaceheader = xmlNode.Create(nodeFisresults, xmlNodeType.ELEMENT_NODE, "Raceheader");
		nodeRaceheader:AddAttribute("Sector", TR.Sector);
		nodeRaceheader:AddAttribute("Gender", TR.Gender);

		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Season", TR.saison);
		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Category", TR.category);
		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Discipline", TR.discipline);
		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Codex", TR.Codex);
		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "NAT_code", TR.NAT_code);
		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Type", "TR");
		nodeRaceDate = xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Racedate");
		xmlNode.Create(nodeRaceDate, xmlNodeType.ELEMENT_NODE, "Day", TR.Day);
		xmlNode.Create(nodeRaceDate, xmlNodeType.ELEMENT_NODE, "Month", TR.Month);
		xmlNode.Create(nodeRaceDate, xmlNodeType.ELEMENT_NODE, "Year", TR.Year);

		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Place", TR.Station);
		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Nation", TR.Nation);
		xmlNode.Create(nodeRaceheader, xmlNodeType.ELEMENT_NODE, "Eventname", TR.Evenement);
	end
	
	nodeAL_race = xmlNode.Create(nodeFisresults, xmlNodeType.ELEMENT_NODE, TR.Sector.."_race");
	-- DT
	nodeJuryDT = xmlNode.Create(nodeAL_race, xmlNodeType.ELEMENT_NODE, "Jury");
	nodeJuryDT:AddAttribute("Function", "Technicaldelegate");
	xmlNode.Create(nodeJuryDT, xmlNodeType.ELEMENT_NODE, "Number", TR.technicaldelegate_Number);
	xmlNode.Create(nodeJuryDT, xmlNodeType.ELEMENT_NODE, "Lastname", TR.technicaldelegate_Lastname);
	xmlNode.Create(nodeJuryDT, xmlNodeType.ELEMENT_NODE, "Firstname", TR.technicaldelegate_Firstname);
	xmlNode.Create(nodeJuryDT, xmlNodeType.ELEMENT_NODE, "Nation", TR.technicaldelegate_Nation);
	xmlNode.Create(nodeJuryDT, xmlNodeType.ELEMENT_NODE, "Email", TR.technicaldelegate_Email);
	xmlNode.Create(nodeJuryDT, xmlNodeType.ELEMENT_NODE, "Phonenbr", TR.technicaldelegate_Phonenbr);
	-- CHIEFOFTIMING
	nodeJuryCHIEFOFTIMING = xmlNode.Create(nodeAL_race, xmlNodeType.ELEMENT_NODE, "Jury");
	nodeJuryCHIEFOFTIMING:AddAttribute("Function", "Chiefoftiming");
	xmlNode.Create(nodeJuryCHIEFOFTIMING, xmlNodeType.ELEMENT_NODE, "Lastname", TR.chiefoftiming_Lastname);
	xmlNode.Create(nodeJuryCHIEFOFTIMING, xmlNodeType.ELEMENT_NODE, "Firstname", TR.chiefoftiming_Firstname);
	xmlNode.Create(nodeJuryCHIEFOFTIMING, xmlNodeType.ELEMENT_NODE, "Nation", TR.chiefoftiming_Nation);
	xmlNode.Create(nodeJuryCHIEFOFTIMING, xmlNodeType.ELEMENT_NODE, "Email", TR.chiefoftiming_Email);
	xmlNode.Create(nodeJuryCHIEFOFTIMING, xmlNodeType.ELEMENT_NODE, "Phonenbr", TR.chiefoftiming_Phonenbr);

	-- AL_Timingreport
	nodeAL_timingreport = xmlNode.Create(nodeFisresults, xmlNodeType.ELEMENT_NODE, TR.Sector.."_timingreport");
	nodeTimekeeper = xmlNode.Create(nodeAL_timingreport, xmlNodeType.ELEMENT_NODE, "Timekeeper");
	xmlNode.Create(nodeTimekeeper, xmlNodeType.ELEMENT_NODE, "Company", TR.timekeeper_Company);
	xmlNode.Create(nodeTimekeeper, xmlNodeType.ELEMENT_NODE, "Lastname", TR.timekeeper_Lastname);
	xmlNode.Create(nodeTimekeeper, xmlNodeType.ELEMENT_NODE, "Firstname", TR.timekeeper_Firstname);
	xmlNode.Create(nodeTimekeeper, xmlNodeType.ELEMENT_NODE, "Nation", TR.timekeeper_Nation);
	xmlNode.Create(nodeTimekeeper, xmlNodeType.ELEMENT_NODE, "Email", TR.timekeeper_Email);
	xmlNode.Create(nodeTimekeeper, xmlNodeType.ELEMENT_NODE, "Phonenbr", TR.timekeeper_Phonenbr);
	
	-- Devices
	nodeDevices = xmlNode.Create(nodeAL_timingreport, xmlNodeType.ELEMENT_NODE, "Devices");
	if timersystemA_Brand ~= "" and timersystemA_Model ~= "" then
		nodeTimer = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Timer");
		nodeTimer:AddAttribute("System", "A");
		nodeTimer:AddAttribute("used", "yes");
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Brand", TR.timersystemA_Brand);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Model", TR.timersystemA_Model);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Serial", TR.timersystemA_Serial);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Homologation", TR.timersystemA_Homologation);
	end
	if timersystemB_Brand ~= "" and timersystemB_Model ~= "" then
		nodeTimer = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Timer");
		nodeTimer:AddAttribute("System", "B");
		nodeTimer:AddAttribute("used", "yes");
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Brand", TR.timersystemB_Brand);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Model", TR.timersystemB_Model);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Serial", TR.timersystemB_Serial);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Homologation", TR.timersystemB_Homologation);
	end
	if timer_startsystemA_Brand ~= "" and timer_startsystemA_Model ~= "" then
		nodeTimer = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Timer_start");
		nodeTimer:AddAttribute("System", "A");
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Brand", TR.timer_startsystemA_Brand);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Model", TR.timer_startsystemA_Model);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Serial", TR.timer_startsystemA_Serial);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Homologation", TR.timer_startsystemA_Homologation);
	end
	if timer_startsystemB_Brand ~= "" and timer_startsystemB_Model ~= "" then
		nodeTimer = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Timer_start");
		nodeTimer:AddAttribute("System", "B");
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Brand", TR.timer_startsystemB_Brand);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Model", TR.timer_startsystemB_Model);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Serial", TR.timer_startsystemB_Serial);
		xmlNode.Create(nodeTimer, xmlNodeType.ELEMENT_NODE, "Homologation", TR.timer_startsystemB_Homologation);
	end
	
	-- portillon
	nodeStartdevice = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Startdevice");
	nodeStartdevice:AddAttribute("Type", "10");
	xmlNode.Create(nodeStartdevice, xmlNodeType.ELEMENT_NODE, "Brand", TR.startdevice_Brand);
	xmlNode.Create(nodeStartdevice, xmlNodeType.ELEMENT_NODE, "Model", TR.startdevice_Model);
	xmlNode.Create(nodeStartdevice, xmlNodeType.ELEMENT_NODE, "Serial", TR.startdevice_Serial);
	xmlNode.Create(nodeStartdevice, xmlNodeType.ELEMENT_NODE, "Homologation", TR.startdevice_Homologation);

	-- cellules
	nodeFinishcells = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Finishcells");
	nodeFinishcells:AddAttribute("System", "A");
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Brand", TR.finishcellssystemA_Brand);
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Model", TR.finishcellssystemA_Model);
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Serial", TR.finishcellssystemA_Serial);
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Homologation", TR.finishcellssystemA_Homologation);

	nodeFinishcells = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Finishcells");
	nodeFinishcells:AddAttribute("System", "B");
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Brand", TR.finishcellssystemB_Brand);
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Model", TR.finishcellssystemB_Model);
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Serial", TR.finishcellssystemB_Serial);
	xmlNode.Create(nodeFinishcells, xmlNodeType.ELEMENT_NODE, "Homologation", TR.finishcellssystemB_Homologation);

	-- software
	nodeSoftware = xmlNode.Create(nodeDevices, xmlNodeType.ELEMENT_NODE, "Software");
	xmlNode.Create(nodeSoftware, xmlNodeType.ELEMENT_NODE, "Brand", TR.software_Brand);
	xmlNode.Create(nodeSoftware, xmlNodeType.ELEMENT_NODE, "Version", TR.software_Version);
	
	-- connexions
	nodeConnection = xmlNode.Create(nodeAL_timingreport, xmlNodeType.ELEMENT_NODE, "Connections");
	nodeModeA = xmlNode.Create(nodeConnection, xmlNodeType.ELEMENT_NODE, "Mode", TR.modesystemA_Mode);
	nodeModeA:AddAttribute("System", "A");
	nodeModeB = xmlNode.Create(nodeConnection, xmlNodeType.ELEMENT_NODE, "Mode", TR.modesystemB_Mode);
	nodeModeB:AddAttribute("System", "B");
	xmlNode.Create(nodeConnection, xmlNodeType.ELEMENT_NODE, "Voice", TR.modevoice_Voice);
	
	if bolTout == false then
		doc:SaveFile(filename);	-- ecriture du fichier
		doc:Delete();
		return;
	end
	GetDataPage2();
	-- nodes de la page 2
	nodeTiming = xmlNode.Create(nodeAL_timingreport, xmlNodeType.ELEMENT_NODE, "Timing");
	nodeSynchronisation = xmlNode.Create(nodeTiming, xmlNodeType.ELEMENT_NODE, "Synchronisation");
	xmlNode.Create(nodeSynchronisation, xmlNodeType.ELEMENT_NODE, "Sync", TR.Synchronisation_Sync);
	xmlNode.Create(nodeSynchronisation, xmlNodeType.ELEMENT_NODE, "Handsync", TR.Synchronisation_Handsync);
	nodeSyncCheckA = xmlNode.Create(nodeSynchronisation, xmlNodeType.ELEMENT_NODE, "Synccheck", TR.syncchecksystemA_Synccheck);
	nodeSyncCheckA:AddAttribute("System", "A");
	nodeSyncCheckB = xmlNode.Create(nodeSynchronisation, xmlNodeType.ELEMENT_NODE, "Synccheck", TR.syncchecksystemB_Synccheck);
	nodeSyncCheckB:AddAttribute("System", "B");

	nodeSyncCheckStartA = xmlNode.Create(nodeSynchronisation, xmlNodeType.ELEMENT_NODE, "Synccheck", TR.syncchecksystemAStart_Synccheck);
	nodeSyncCheckStartA:AddAttribute("System", "AStart");
	nodeSyncCheckStartB = xmlNode.Create(nodeSynchronisation, xmlNodeType.ELEMENT_NODE, "Synccheck", TR.syncchecksystemBStart_Synccheck);
	nodeSyncCheckStartB:AddAttribute("System", "BStart");

	for i = 1, TR.nombre_de_manche do
		nodeTimes = xmlNode.Create(nodeTiming, xmlNodeType.ELEMENT_NODE, "Times");
		nodeTimes:AddAttribute("Run", i);

		nodeBibFirst = xmlNode.Create(nodeTimes, xmlNodeType.ELEMENT_NODE, "Bibfirst");
		nodeBibFirst:AddAttribute("no", TR[i].Bibfirst.Bib);
		nodeStartBibFirst = xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Start", TR[i].BibfirstsystemA_Start);
		nodeStartBibFirst:AddAttribute("System", "A");
		nodeStartBibFirst = xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Start", TR[i].BibfirstsystemB_Start);
		nodeStartBibFirst:AddAttribute("System", "B");
		nodeStartBibFirst = xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Start", TR[i].BibfirstsystemHand_Start);
		nodeStartBibFirst:AddAttribute("System", "Hand");
		nodeFinishBibFirst = xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Finish", TR[i].BibfirstsystemA_Finish);
		nodeFinishBibFirst:AddAttribute("System", "A");
		nodeFinishBibFirst = xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Finish", TR[i].BibfirstsystemB_Finish);
		nodeFinishBibFirst:AddAttribute("System", "B");
		nodeFinishBibFirst = xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Finish", TR[i].BibfirstsystemHand_Finish);
		nodeFinishBibFirst:AddAttribute("System", "Hand");
		xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Net", TR[i].Bibfirst.Net);
		xmlNode.Create(nodeBibFirst, xmlNodeType.ELEMENT_NODE, "Hand", TR[i].Bibfirst_Hand);

		nodeBibLast = xmlNode.Create(nodeTimes, xmlNodeType.ELEMENT_NODE, "Biblast");
		nodeBibLast:AddAttribute("no", TR[i].Biblast.Bib);
		nodeStartBibLast = xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Start", TR[i].BiblastsystemA_Start);
		nodeStartBibLast:AddAttribute("System", "A");
		nodeStartBibLast = xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Start", TR[i].BiblastsystemB_Start);
		nodeStartBibLast:AddAttribute("System", "B");
		nodeStartBibLast = xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Start", TR[i].BiblastsystemHand_Start);
		nodeStartBibLast:AddAttribute("System", "Hand");
		nodeFinishBibLast = xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Finish", TR[i].BiblastsystemA_Finish);
		nodeFinishBibLast:AddAttribute("System", "A");
		nodeFinishBibLast = xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Finish", TR[i].BiblastsystemB_Finish);
		nodeFinishBibLast:AddAttribute("System", "B");
		nodeFinishBibLast = xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Finish", TR[i].BiblastsystemHand_Finish);
		nodeFinishBibLast:AddAttribute("System", "Hand");

		xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Net", TR[i].Biblast.Net);
		xmlNode.Create(nodeBibLast, xmlNodeType.ELEMENT_NODE, "Hand", TR[i].Biblast_Hand);
		
		nodeBestA = xmlNode.Create(nodeTimes, xmlNodeType.ELEMENT_NODE, "BestA");
		xmlNode.Create(nodeBestA, xmlNodeType.ELEMENT_NODE, "Bib", TR[i].BestA_Bib);
		xmlNode.Create(nodeBestA, xmlNodeType.ELEMENT_NODE, "Time", TR[i].BestA_Time);

	end
	doc:SaveFile(filename);	-- ecriture du fichier
	doc:Delete();
end

function ControlData();
	local bolOK = true;

	-- contrôle des data
	TR.OS = TR.OS or '';
	TR.technicaldelegate_Number = TR.technicaldelegate_Number or '';	
	TR.technicaldelegate_Lastname = TR.technicaldelegate_Lastname or '';	
	TR.technicaldelegate_Firstname = TR.technicaldelegate_Firstname or '';	
	TR.technicaldelegate_Nation = TR.technicaldelegate_Nation or '';	
	TR.technicaldelegate_Email = TR.technicaldelegate_Email or '';	
	TR.chiefoftiming_Lastname = TR.chiefoftiming_Lastname or '';	
	TR.chiefoftiming_Firstname = TR.chiefoftiming_Firstname or '';	
	TR.chiefoftiming_Nation = TR.chiefoftiming_Nation or '';	
	TR.chiefoftiming_Email = TR.chiefoftiming_Email or '';	
	TR.chiefoftiming_Phonenbr = TR.chiefoftiming_Phonenbr or '';	
	TR.timekeeper_Company = TR.timekeeper_Company or '-';	
	TR.timekeeper_Lastname = TR.timekeeper_Lastname or '';	
	TR.timekeeper_Firstname = TR.timekeeper_Firstname or '';	
	TR.timekeeper_Nation = TR.timekeeper_Nation or '';	
	TR.timekeeper_Email = TR.timekeeper_Email or '';	
	TR.timekeeper_Phonenbr = TR.timekeeper_Phonenbr or '';	
	TR.timersystemA_Brand = TR.timersystemA_Brand or '';	
	TR.timersystemA_Model = TR.timersystemA_Model or '';	
	TR.timersystemA_Serial = TR.timersystemA_Serial or '';	
	TR.timersystemA_Homologation = TR.timersystemA_Homologation or '';	
	TR.timersystemB_Brand = TR.timersystemB_Brand or '';	
	TR.timersystemB_Model = TR.timersystemB_Model or '';	
	TR.timersystemB_Serial = TR.timersystemB_Serial or '';	
	TR.timersystemB_Homologation = TR.timersystemB_Homologation or '';	
	TR.timer_startsystemA_Brand = TR.timer_startsystemA_Brand or '';	
	TR.timer_startsystemA_Model = TR.timer_startsystemA_Model or '';	
	TR.timer_startsystemA_Serial = TR.timer_startsystemA_Serial or '';	
	TR.timer_startsystemA_Homologation = TR.timer_startsystemA_Homologation or '';	
	TR.timer_startsystemB_Brand = TR.timer_startsystemB_Brand or '';	
	TR.timer_startsystemB_Model = TR.timer_startsystemB_Model or '';	
	TR.timer_startsystemB_Serial = TR.timer_startsystemB_Serial or '';	
	TR.timer_startsystemB_Homologation = TR.timer_startsystemB_Homologation or '';	
	TR.startdevice_Brand = TR.startdevice_Brand or '';	
	TR.startdevice_Model = TR.startdevice_Model or '';	
	TR.startdevice_Serial = TR.startdevice_Serial or '';	
	TR.startdevice_Homologation = TR.startdevice_Homologation or '';	
	TR.finishcellssystemA_Brand = TR.finishcellssystemA_Brand or '';	
	TR.finishcellssystemA_Model = TR.finishcellssystemA_Model or '';	
	TR.finishcellssystemA_Serial = TR.finishcellssystemA_Serial or '';	
	TR.finishcellssystemA_Homologation = TR.finishcellssystemA_Homologation or '';	
	TR.finishcellssystemB_Brand = TR.finishcellssystemB_Brand or '';	
	TR.finishcellssystemB_Model = TR.finishcellssystemB_Model or '';	
	TR.finishcellssystemB_Serial = TR.finishcellssystemB_Serial or '';	
	TR.finishcellssystemB_Homologation = TR.finishcellssystemB_Homologation or '';	


	TR.startclock_Brand = TR.startclock_Brand or '';	
	TR.startclock_Model = TR.startclock_Model or '';	
	TR.startclock_Serial = TR.startclock_Serial or '';	
	TR.startclock_Homologation = '';	
	TR.photofinishsystemA_Brand = TR.photofinishsystemA or '';	
	TR.photofinishsystemA_Model = TR.photofinishsystemA_Model or '';	
	TR.photofinishsystemA_Serial = TR.photofinishsystemA_Serial or '';	
	TR.photofinishsystemB_Brand = TR.photofinishsystemB or '';	
	TR.photofinishsystemB_Model = TR.photofinishsystemB_Model or '';	
	TR.photofinishsystemB_Serial = TR.photofinishsystemB_Serial or '';	
	TR.photofinishsystemB_Homologation = '';	

	TR.software_Brand = "skiFFS";	
	TR.software_Version = TR.software_Version or '';	
	TR.modesystemA_Mode = TR.modesystemA_Mode or '';	
	TR.modesystemB_Mode = TR.modesystemB_Mode or '';	
	TR.modevoice_Voice = TR.modevoice_Voice or '';	
	
	TR.Synchronisation_Sync = TR.Synchronisation_Sync or '00:00:00';	
	TR.Synchronisation_Handsync = TR.Synchronisation_Handsync or '00:00:000';	
	TR.syncchecksystemA_Synccheck = TR.syncchecksystemA_Synccheck or '00:00:00.000';	
	TR.syncchecksystemB_Synccheck = TR.syncchecksystemB_Synccheck or '00:00:00.000';

	TR.syncchecksystemAStart_Synccheck = TR.syncchecksystemAStart_Synccheck or '00:00:00.000';	
	TR.syncchecksystemBStart_Synccheck = TR.syncchecksystemBStart_Synccheck or '00:00:00.000';

	if TR.timersystemA_Brand:len() <= 3 then
		TR.timersystemA_Model = '';
		TR.timersystemA_Serial = '';
		TR.timersystemA_Homologation = '';
	end
	if TR.timersystemB_Brand:len() <= 3 then
		TR.timersystemB_Model = '';
		TR.timersystemB_Serial = '';
		TR.timersystemB_Homologation = '';
	end
	if TR.timer_startsystemA_Brand:len() <= 3 then
		TR.timer_startsystemA_Model = '';
		TR.timer_startsystemA_Serial = '';
		TR.timer_startsystemA_Homologation = '';
	end
	if TR.timer_startsystemB_Brand:len() <= 3 then
		TR.timer_startsystemB_Model = '';
		TR.timer_startsystemB_Serial = '';
		TR.timer_startsystemB_Homologation = '';
	end
	for i = 1, TR.nombre_de_manche do
		TR[i] = TR[i] or {};
		TR[i].Bibfirst = TR[i].Bibfirst or {};
		TR[i].Bibfirst.Bib = TR[i].Bibfirst.Bib or '';
		TR[i].Bibfirst.Net = TR[i].Bibfirst.Net or '00:00.00';
		TR[i].Biblast = TR[i].Biblast or {};
		TR[i].Biblast.Net = TR[i].Biblast.Net or '00:00.00';
		TR[i].Biblast.Bib = TR[i].Biblast.Bib or '';
		-- TR[i].Bibfirst.Time = TR[i].Bibfirst.Time or '00:00.00';
		TR[i].BibfirstsystemA_Start = TR[i].BibfirstsystemA_Start or '00:00:00.000';	
		TR[i].BibfirstsystemB_Start = TR[i].BibfirstsystemB_Start or '00:00:00.000';	
		TR[i].BibfirstsystemHand_Start = TR[i].BibfirstsystemHand_Start or '00:00:00.000';
		TR[i].BibfirstsystemA_Finish = TR[i].BibfirstsystemA_Finish or '00:00:00.000';	
		TR[i].BibfirstsystemB_Finish = TR[i].BibfirstsystemB_Finish or '00:00:00.000';	
		TR[i].BibfirstsystemHand_Finish = TR[i].BibfirstsystemHand_Finish or '00:00:00.000';
		TR[i].BiblastsystemA_Start = TR[i].BiblastsystemA_Start or '00:00:00.000';	
		TR[i].BiblastsystemB_Start = TR[i].BiblastsystemB_Start or '00:00:00.000';	
		TR[i].BiblastsystemHand_Start = TR[i].BiblastsystemHand_Start or '00:00:00.000';	
		TR[i].BiblastsystemA_Finish = TR[i].BiblastsystemA_Finish or '00:00:00.000';	
		TR[i].BiblastsystemB_Finish = TR[i].BiblastsystemB_Finish or '00:00:00.000';	
		TR[i].BiblastsystemHand_Finish = TR[i].BiblastsystemHand_Finish or '00:00:00.000';	
		TR[i].BestA_Bib = TR[i].BestA_Bib or '';	
		TR[i].BestA_Time = TR[i].BestA_Time or '00:00.00';	
	end

	if bolOK == false then 
		local msg = "L'environnement ne permet pas la création du Rapport Technique de Chronométrage FIS :\n\n"..TR.errormessage;
		app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
	end
	return bolOK;
end

function PopulateCombo(lectureXML)
	OnChangeComboBrand('timersystemA_Brand', 'Timer')
	OnChangeComboBrand('timersystemB_Brand', 'Timer')
	OnChangeComboBrand('timer_startsystemA_Brand', 'Timer')
	OnChangeComboBrand('timer_startsystemB_Brand', 'Timer')
	OnChangeComboBrand('finishcellssystemA_Brand', 'Photocell')
	OnChangeComboBrand('finishcellssystemB_Brand', 'Photocell')
	OnChangeComboBrand('startdevice_Brand', 'Start')
	if lectureXML then
		SetValuesPage1();
	end
end


function LectureDeviceFIS(node)
	if node == nil then
		if Device.ValidUntil and Device.ValidUntil:len() > 0 then
			AddRowDeviceFIS(Device.Brand, Device.type, Device.Model, Device.HomologationNumber, Device.ValidUntil, Device.Commentaire);
		end
		return
	end
	if node:GetName() == 'Device' then
		Device.type = node:GetAttribute("type");
		if Device.ValidUntil and Device.ValidUntil:len() > 0 then
			AddRowDeviceFIS(Device.Brand, Device.type, Device.Model, Device.HomologationNumber, Device.ValidUntil, Device.Commentaire);
		end
	end
	if node:GetContent():len() > 0 then
		Device[node:GetParent():GetName()] = node:GetContent();
	end
	child = xmlNode.GetChildren(node); 
	while child ~= nil do
		LectureDeviceFIS(child);
	end
	LectureDeviceFIS(node:GetNext());
end

function LectureDevicesFisXML()
end

function LectureXML(node)
	if node == nil then
		return
	end
	racine = racine or "";
	if node:GetName() == "Jury" then
		if string.lower(node:GetAttribute("Function")) == "technicaldelegate" then
			racine = "technicaldelegate_";
		elseif string.lower(node:GetAttribute("Function")) == "chiefoftiming" then
			racine = "chiefoftiming_";
		end
		-- adv.Alert('racine jury = '..racine);
	elseif node:GetName() == "Timekeeper" then
		racine = "timekeeper_";
	elseif node:GetName() == "Software" then
		racine = "software_";
	elseif node:GetName() == "Voice" then
		racine = "modevoice_";
	elseif node:GetName() == "Startdevice" then
		racine = "startdevice_";
	elseif node:GetName() == "Photofinish" then
		racine = "photofinish";
	elseif node:GetName() == "Synchronisation" then
		racine = "Synchronisation_";
	elseif node:GetName() == "BestA" then
		racine = "BestA_";
	elseif node:GetName() == "CertifyFIS" then
		racine = "";
		run = nil;
	elseif node:GetName() == "Comment" then
		racine = "";
	elseif node:HasAttribute("System") then
		if run == nil then
			racine = string.lower(node:GetName()).."system"..node:GetAttribute("System").."_";
		else
			if node:GetName() == "Net" then
				racine = node:GetParent():GetName().."_";
			else
				racine = node:GetParent():GetName().."system"..node:GetAttribute("System").."_";
			end
		end
	elseif node:HasAttribute("Run") then   -- node = "Times"
		run = tonumber(node:GetAttribute("Run"));
		TR[run] = TR[run] or {};
	elseif node:HasAttribute("no") then  -- Bibfirst ou Biblast
		bib = tonumber(node:GetAttribute("no"));
		TR[run][node:GetName()] = TR[run][node:GetName()] or {};
		TR[run][node:GetName()].Bib = bib;
		racine = node:GetName().."_";
	end
	if node:GetName() == "Net" or node:GetName() == "Hand" then
		-- adv.Alert("node:GetParent():GetName() = "..node:GetParent():GetName()..", node:GetName = "..node:GetName());
		racine = "";
	end
	child = xmlNode.GetChildren(node); -- 1 niveau en plus level = 2
	while child ~= nil do
		attribute = node:GetAttributes();
		while attribute ~= nil do
			local name = attribute:GetName();
			local value = attribute:GetValue();
			attribute = attribute:GetNext();
		end
		if child:GetType() == 3 then 
			if run == nil then
				col = racine..child:GetParent():GetName();
				-- adv.Alert("TR."..col.." = TR."..col.." or '';");
				TR[col] = child:GetContent();
				-- adv.Alert('racine = '..racine..", child:GetType() == 3, TR["..col.."] = "..TR[col]);
			else
				if node:GetName() ~= "Net" and node:GetName() ~= "Hand"  then
					col = racine..child:GetParent():GetName();
					TR[run][col] = child:GetContent();
				else
					col = racine..node:GetParent():GetName().."_"..node:GetName();
					TR[run][col] = child:GetContent();
				end
				-- adv.Alert('racine = '..racine..", on est dans un run, child:GetType() == 3, TR["..run.."]["..col.."]");
				-- adv.Alert("TR["..run.."]."..col.." = TR["..run.."]."..col.." or '';");
			end
		end
		LectureXML(child);
	end
	LectureXML(node:GetNext());
end

function OpenTables(code_evenement)
	Evenement = base:GetTable('Evenement');
	Epreuve_Alpine = base:GetTable('Epreuve_Alpine');
	Epreuve = base:GetTable('Epreuve');
	Resultat_Chrono = base:GetTable('Resultat_Chrono');
	Regroupement = base:GetTable('Regroupement');
	Resultat = base:GetTable('Resultat');
	Resultat_Manche = base:GetTable('Resultat_Manche');
	Evenement_Officiel = base:GetTable('Evenement_Officiel');

	base:TableLoad(Evenement, 'Select * From Evenement Where Code = '..code_evenement);
	base:TableLoad(Epreuve, 'Select * From Epreuve Where Code_evenement = '..code_evenement);
	base:TableLoad(Epreuve_Alpine, 'Select * From Epreuve_Alpine Where Code_evenement = '..code_evenement);
	local cmd = "Select * From Regroupement Where Code_activite = '"..Epreuve:GetCell("Code_activite", 0).."' And Code_entite = 'FIS' And Code_saison = '"..Epreuve:GetCell("Code_saison", 0).."' And Code = '"..Epreuve:GetCell("Code_regroupement", 0).."'";
	base:TableLoad(Regroupement, cmd);
	base:TableLoad(Resultat, 'Select * From Resultat Where Code_evenement = '..code_evenement);

	TR.Evenement = Evenement:GetCell("Nom", 0);
	TR.Station = Evenement:GetCell("Station", 0);
	TR.Nation = Evenement:GetCell("Code_nation", 0);
	TR.Year = Epreuve:GetCell("Date_epreuve", 0, '%4Y');
	TR.Month = Epreuve:GetCell("Date_epreuve", 0, '%2M');
	TR.Day = Epreuve:GetCell("Date_epreuve", 0, '%2D');
	TR.code_activite = Epreuve:GetCell("Code_activite", 0);
	TR.Gender = Epreuve:GetCell("Sexe", 0);
	if TR.Gender == "F" then
		TR.Gender = "W";
	end
	if TR.code_activite == "ALP" then 
		TR.Sector = "AL"; 
	end
	local grilleCategorie = Epreuve:GetCell("Code_grille_categorie", 0);
	if grilleCategorie == "FIS-MAST" then
		TR.Sector = "MA";
	end
	-- local filter = "Code_activite = '"..Epreuve:GetCell("Code_activite", 0).."' And Code_entite = 'FIS' And Code_saison = '"..Epreuve:GetCell("Code_saison", 0).."' And Code = '"..Epreuve:GetCell("Code_regroupement", 0).."'";
	TR.category = Regroupement:GetCell("Code_international", 0);
	TR.Codex = Evenement:GetCell('Codex', 0):sub(4,7);
	

end

function GetTD()
	base:TableLoad(Evenement_Officiel, 'Select * From Evenement_Officiel Where Code_evenement = '..TR.code_evenement..' And Fonction = "TechnicalDelegate"');
	TR.technicaldelegate_Lastname = Evenement_Officiel:GetCell("Nom", 0);
	TR.technicaldelegate_Firstname = Evenement_Officiel:GetCell("Prenom", 0);
	TR.technicaldelegate_Nation = Evenement_Officiel:GetCell("Nation", 0);
	TR.technicaldelegate_Phonenbr = Evenement_Officiel:GetCell("Tel_mobile", 0);
	TR.technicaldelegate_Email = Evenement_Officiel:GetCell('Email', 0);
	TR.technicaldelegate_Number = Evenement:GetCell('Codex', 0):sub(9);
end

function GetCartouche();
	if Epreuve:GetCell("Code_entite", 0) ~= "FIS" or TR.code_activite ~= "ALP" then
		TR.errormessage = TR.errormessage or '';
		TR.errormessage = TR.errormessage.."La course n'a pas une entité FIS ou n'est pas Alpine !!\n";
		TR.OK = false
		return;
	end
	TR.discipline = Epreuve:GetCell("Code_discipline", 0)
	TR.NAT_code = Epreuve:GetCell("Fichier_transfert", 0)
	local filter = "Code_activite = '"..Epreuve:GetCell("Code_activite", 0).."' And Code_entite = 'FIS' And Code_saison = '"..Epreuve:GetCell("Code_saison", 0).."' And Code = '"..Epreuve:GetCell("Code_regroupement", 0).."'";
	TR.category = Regroupement:GetCell("Code_international", 0);
end

function GetSetData();
	local fmt = "%2h:%2m:%2s.%3f"
	local fmt2 = "%-1h%-1m%2s.%2f"
	local fmt3 = "%1m:%2s.%2f"
	
	for i = 1, TR.nombre_de_manche  do
		TR[i] = {};
		TR[i].Bibfirst = {};
		TR[i].Bibfirst.Net = '00:00.000';
		TR[i].Bibfirst.Bib = '';
		TR[i].Biblast = {};
		TR[i].Biblast.Net = '00:00.000';
		TR[i].Biblast.Bib = '';
		-- on récupère le meilleur de la manche
		filter_manche = "Select * From Resultat_Manche Where Code_evenement = "..TR.code_evenement.." And Code_manche = "..i.." And Tps_chrono > 0 Order By Tps_chrono"; 
		base:TableLoad(Resultat_Manche, filter_manche);
		TR[i].bestcodecoureur = Resultat_Manche:GetCell("Code_coureur",0);
		TR[i].BestA_Time = app.TimeToString(Resultat_Manche:GetCellInt("Tps_chrono",0), fmt3);
		filter_result = "Select * FRom Resultat Where Code_evenement = "..TR.code_evenement.." And Code_coureur = '"..TR[i].bestcodecoureur.."'"; 
		base:TableLoad(Resultat,  filter_result);
		TR[i].BestA_Bib = Resultat:GetCell("Dossard", 0);
		TR[i].BestA_Name = Resultat:GetCell("Nom", 0).." "..Resultat:GetCell("Prenom", 0);
		
		-- on prend ceux qui sont arrivés 
		filter_arrivee = "Select * From Resultat_Chrono Where Code_evenement = "..TR.code_evenement.." And Code_manche = "..i.." And ABS(Dossard) > 0 And Heure > 0 And Id = -1 Order By Heure"; 
		base:TableLoad(Resultat_Chrono, filter_arrivee);
		Arrives = Resultat_Chrono:Copy();
		ReplaceTableEnvironnement(Arrives, 'Arrives');
		
		TR[i].Bibfirst.Bib = Arrives:GetCell("Dossard",0);
		TR[i].BibfirstsystemA_Finish = app.TimeToString(Arrives:GetCellInt("Heure",0), fmt);
		filter_result = "Select * From Resultat Where Code_evenement = "..TR.code_evenement.." And Dossard = '"..TR[i].Bibfirst.Bib.."'"; 
		base:TableLoad(Resultat,  filter_result);
		TR[i].firstcodecoureur = Resultat:GetCell("Code_coureur", 0);
		filter_manche = "Select * From Resultat_Manche Where Code_evenement = "..TR.code_evenement.." And Code_manche = "..i.." And Code_coureur ='"..TR[i].firstcodecoureur.."'";; 
		base:TableLoad(Resultat_Manche, filter_manche);
		if Resultat_Manche:GetCellInt("Tps_chrono", 0) > 0 then
			TR[i].Bibfirst.Net = app.TimeToString(Resultat_Manche:GetCellInt('Tps_chrono', 0), fmt3);
		elseif Resultat_Manche:GetCellInt("Tps_chrono", 0) == -800 then
			TR[i].Bibfirst.Net = app.TimeToString(Resultat_Manche:GetCellInt('Reserve', 0), fmt3);
		end

		TR[i].Biblast.Bib = Arrives:GetCell("Dossard",Arrives:GetNbRows() -1);
		TR[i].BiblastsystemA_Finish = app.TimeToString(Arrives:GetCellInt("Heure", Arrives:GetNbRows() -1), fmt);
		filter_result = "Select * From Resultat Where Code_evenement = "..TR.code_evenement.." And Dossard = '"..TR[i].Biblast.Bib.."'"; 
		base:TableLoad(Resultat, filter_result);
		TR[i].lastcodecoureur = Resultat:GetCell("Code_coureur", 0);
		filter_manche = "Select * From Resultat_Manche Where Code_evenement = "..TR.code_evenement.." And Code_manche = "..i.." And Code_coureur ='"..TR[i].lastcodecoureur.."'";; 
		base:TableLoad(Resultat_Manche, filter_manche);
		if Resultat_Manche:GetCellInt("Tps_chrono", 0) > 0 then
			TR[i].Biblast.Net = app.TimeToString(Resultat_Manche:GetCellInt('Tps_chrono', 0), fmt3);
		elseif Resultat_Manche:GetCellInt("Tps_chrono", 0) == -800 then
			TR[i].Biblast.Net = app.TimeToString(Resultat_Manche:GetCellInt('Reserve', 0), fmt3);
		end

		-- données du départ 
		-- first
		filter_start = "Select * From Resultat_Chrono Where Code_evenement = "..TR.code_evenement.." And Heure > 0 And Code_manche = "..i.." And Dossard In(Select Dossard From Resultat_Chrono Where Code_evenement = "..TR.code_evenement.." And Code_manche = "..i.." And ABS(Dossard) > 0 And Heure > 0 And Id = -1 Order By Heure) And Heure > 0 And Id = 0 Order By Heure"; 
		base:TableLoad(Resultat_Chrono, filter_start);
		Departs = Resultat_Chrono:Copy();
		ReplaceTableEnvironnement(Departs, 'Departs');
		TR[i].BibfirstsystemA_Start = app.TimeToString(Departs:GetCellInt("Heure",0), fmt);
		-- last 
		TR[i].BiblastsystemA_Start = app.TimeToString(Resultat_Chrono:GetCellInt("Heure",Departs:GetNbRows() -1), fmt);
	end
end

function InstalleTimingReport(path)
	os.execute(path);
	--app.Execute(path);
end
		
function GetDataPage1()
	TR.chiefoftiming_Lastname = dlgPage1:GetWindowName('chiefoftiming_Lastname'):GetValue();
	TR.chiefoftiming_Firstname = dlgPage1:GetWindowName('chiefoftiming_Firstname'):GetValue();
	TR.chiefoftiming_Nation = dlgPage1:GetWindowName('chiefoftiming_Nation'):GetValue();
	TR.chiefoftiming_Email = dlgPage1:GetWindowName('chiefoftiming_Email'):GetValue();
	TR.chiefoftiming_Phonenbr = dlgPage1:GetWindowName('chiefoftiming_Phonenbr'):GetValue();
	
	TR.timekeeper_Lastname = dlgPage1:GetWindowName('timekeeper_Lastname'):GetValue();
	TR.timekeeper_Firstname = dlgPage1:GetWindowName('timekeeper_Firstname'):GetValue();
	TR.timekeeper_Nation = dlgPage1:GetWindowName('timekeeper_Nation'):GetValue();
	TR.timekeeper_Phonenbr = dlgPage1:GetWindowName('timekeeper_Phonenbr'):GetValue();
	TR.timekeeper_Email = dlgPage1:GetWindowName('timekeeper_Email'):GetValue();
	TR.timekeeper_Company = dlgPage1:GetWindowName('timekeeper_Company'):GetValue();

	TR.technicaldelegate_Lastname = dlgPage1:GetWindowName('technicaldelegate_Lastname'):GetValue();
	TR.technicaldelegate_Firstname = dlgPage1:GetWindowName('technicaldelegate_Firstname'):GetValue();
	TR.technicaldelegate_Nation = dlgPage1:GetWindowName('technicaldelegate_Nation'):GetValue();
	TR.technicaldelegate_Number = dlgPage1:GetWindowName('technicaldelegate_Number'):GetValue();

	TR.timersystemA_Brand = dlgPage1:GetWindowName('timersystemA_Brand'):GetValue();
	TR.timersystemA_Model = dlgPage1:GetWindowName('timersystemA_Model'):GetValue();
	TR.timersystemA_Serial = dlgPage1:GetWindowName('timersystemA_Serial'):GetValue();
	TR.timersystemA_Homologation = dlgPage1:GetWindowName('timersystemA_Homologation'):GetValue();
	TR.timer_startsystemA_Brand = dlgPage1:GetWindowName('timer_startsystemA_Brand'):GetValue();
	TR.timer_startsystemA_Model = dlgPage1:GetWindowName('timer_startsystemA_Model'):GetValue();
	TR.timer_startsystemA_Serial = dlgPage1:GetWindowName('timer_startsystemA_Serial'):GetValue();
	TR.timer_startsystemA_Homologation = dlgPage1:GetWindowName('timer_startsystemA_Homologation'):GetValue();

	TR.finishcellssystemA_Brand = dlgPage1:GetWindowName('finishcellssystemA_Brand'):GetValue();
	TR.finishcellssystemA_Model = dlgPage1:GetWindowName('finishcellssystemA_Model'):GetValue();
	TR.finishcellssystemA_Serial = dlgPage1:GetWindowName('finishcellssystemA_Serial'):GetValue();
	TR.finishcellssystemA_Homologation = dlgPage1:GetWindowName('finishcellssystemA_Homologation'):GetValue();

	TR.startdevice_Brand = dlgPage1:GetWindowName('startdevice_Brand'):GetValue();
	TR.startdevice_Model = dlgPage1:GetWindowName('startdevice_Model'):GetValue();
	TR.startdevice_Serial = dlgPage1:GetWindowName('startdevice_Serial'):GetValue();
	TR.startdevice_Homologation = dlgPage1:GetWindowName('startdevice_Homologation'):GetValue();

	TR.timersystemB_Brand = dlgPage1:GetWindowName('timersystemB_Brand'):GetValue();
	TR.timersystemB_Model = dlgPage1:GetWindowName('timersystemB_Model'):GetValue();
	TR.timersystemB_Serial = dlgPage1:GetWindowName('timersystemB_Serial'):GetValue();
	TR.timersystemB_Homologation = dlgPage1:GetWindowName('timersystemB_Homologation'):GetValue();

	TR.timer_startsystemB_Brand = dlgPage1:GetWindowName('timer_startsystemB_Brand'):GetValue();
	TR.timer_startsystemB_Model = dlgPage1:GetWindowName('timer_startsystemB_Model'):GetValue();
	TR.timer_startsystemB_Serial = dlgPage1:GetWindowName('timer_startsystemB_Serial'):GetValue();
	TR.timer_startsystemB_Homologation = dlgPage1:GetWindowName('timer_startsystemB_Homologation'):GetValue();

	TR.finishcellssystemB_Brand = dlgPage1:GetWindowName('finishcellssystemB_Brand'):GetValue();
	TR.finishcellssystemB_Model = dlgPage1:GetWindowName('finishcellssystemB_Model'):GetValue();
	TR.finishcellssystemB_Serial = dlgPage1:GetWindowName('finishcellssystemB_Serial'):GetValue();
	TR.finishcellssystemB_Homologation = dlgPage1:GetWindowName('finishcellssystemB_Homologation'):GetValue();

	TR.modesystemA_Mode = dlgPage1:GetWindowName('modesystemA_Mode'):GetValue();
	TR.modesystemB_Mode = dlgPage1:GetWindowName('modesystemB_Mode'):GetValue();
	TR.modevoice_Voice = dlgPage1:GetWindowName('modevoice_Voice'):GetValue();
end


function GetDataPage2()
	TR.Synchronisation_Sync = dlgPage2:GetWindowName('Synchronisation_Sync'):GetValue();
	TR.Synchronisation_Handsync = dlgPage2:GetWindowName('Synchronisation_Handsync'):GetValue();
	TR.syncchecksystemA_Synccheck = dlgPage2:GetWindowName('syncchecksystemA_Synccheck'):GetValue();
	TR.syncchecksystemB_Synccheck = dlgPage2:GetWindowName('syncchecksystemB_Synccheck'):GetValue();

	TR.syncchecksystemAStart_Synccheck = dlgPage2:GetWindowName('syncchecksystemA_Start_Synccheck'):GetValue();
	TR.syncchecksystemBStart_Synccheck = dlgPage2:GetWindowName('syncchecksystemB_Start_Synccheck'):GetValue();

	for i = 1, TR.nombre_de_manche  do
		TR[i].BibfirstsystemB_Start = dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Start'):GetValue();
		TR[i].BiblastsystemB_Start = dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Start'):GetValue();
		TR[i].BibfirstsystemHand_Start = dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Start'):GetValue();
		TR[i].BiblastsystemHand_Start = dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Start'):GetValue();
		TR[i].BibfirstsystemB_Finish = dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Finish'):GetValue();
		TR[i].BiblastsystemB_Finish = dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Finish'):GetValue();
		TR[i].BibfirstsystemHand_Finish = dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Finish'):GetValue();
		TR[i].BiblastsystemHand_Finish = dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Finish'):GetValue();
	end
		
end

function OnChangeComboBrand(ctrlComboBrand, device)
	-- timersystemA_Brand  
	-- timersystemA_Homologation
	local brand = dlgPage1:GetWindowName(ctrlComboBrand):GetValue();
	if brand:len() == 0 then
		return;
	end
	Device_FIS:Snapshot('Device_FIS.db3');
	local filter = "$(Brand):In('"..brand.."') and $(Device):In('"..device.."')";
	local Device_FIS_Filtre = Device_FIS:Copy();
	Device_FIS_Filtre:Filter(filter, true);
	local cmodel = string.gsub(ctrlComboBrand,'Brand', 'Model');
	local chomologation = string.gsub(ctrlComboBrand,'Brand', 'Homologation');
	dlgPage1:GetWindowName(cmodel):Clear();
	for i = 0, Device_FIS_Filtre:GetNbRows() -1 do
		dlgPage1:GetWindowName(cmodel):Append(Device_FIS_Filtre:GetCell("Model", i));
	end
	dlgPage1:GetWindowName(cmodel):SetValue(Device_FIS_Filtre:GetCell("Model", 0));
	dlgPage1:GetWindowName(chomologation):SetValue(Device_FIS_Filtre:GetCell("HomologationNumber", 0));
	Device_FIS_Filtre:Delete();
	local ab = 'a';
	local model = dlgPage1:GetWindowName(cmodel):GetValue();
	if string.find(cmodel, 'SystemB') then
		ab = 'b';
	end
	AfficheDevice(ab, model);
end

function OnChangeComboModel(combomodel)
	-- timersystemA_Brand  
	-- timersystemA_Homologation
	local model = dlgPage1:GetWindowName(combomodel):GetValue();
	if model:len() == 0 then
		return;
	end
	local chomologation = string.gsub(combomodel,'Model', 'Homologation');
	local filter = "$(Model):In('"..model.."')";
	local Device_FIS_Filtre = Device_FIS:Copy();
	Device_FIS_Filtre:Filter(filter, true);
	dlgPage1:GetWindowName(chomologation):SetValue(Device_FIS_Filtre:GetCell("HomologationNumber", 0));
	Device_FIS_Filtre:Delete();
	if string.find(combomodel, 'systemB') then
		AfficheDevice("b", model);
	else
		AfficheDevice("a", model);
	end
end

function AfficheDevice(ab, model)
	local path = './logo/logo_fis.jpg';
	if app.FileExists('./res/tr/'..model..'.jpg') then
		path ='./res/tr/'..model..'.jpg';
	end
	dlgPage1:GetWindowName('image'..ab):GetObject(0):SetText(path, true);
--	objImage:SetText(path, true);
	-- adv.Alert('image'..ab..', model = '..tostring(model)..', path = '..path);
		
end

function AfficheDialog0()
	dlgConfig = wnd.CreateDialog(
		{
		width = TR.width,
		height = TR.height,
		x = TR.x,
		y = TR.y,
		label='Informations', 
		icon='./res/32x32_fis.png'
		});
	
	dlgConfig:LoadTemplateXML({ 
		xml = './edition/editionTR_FIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		node_value = 'page0' 
	});

	-- Toolbar Principale ...
	local tbpage0 = dlgConfig:GetWindowName('tbpage0');
	tbpage0:AddStretchableSpace();
	local btnNext = tbpage0:AddTool("Suite", "./res/vpe32x32_page_next.png");
	tbpage0:AddSeparator();
	if string.find(TR.OS, "Windows") then
		local btnVersionWindows = tbpage0:AddTool("Installer la version Windows", "./res/32x32_download.png");
		tbpage0:AddSeparator();
	else
		local btnVersionMac = tbpage0:AddTool("Installer la version Mac", "./res/32x32_download.png");
		tbpage0:AddSeparator();
	end
	local btnClose = tbpage0:AddTool("Quitter", "./res/32x32_exit.png");
	tbpage0:AddStretchableSpace();
	tbpage0:Realize();
	local message = app.GetAuiMessage();
	
	if string.find(TR.OS, "Windows") then
		dlgConfig:Bind(eventType.MENU, 
			function(evt) 
				local urlFile = "https://member.fis-ski.com/software/timingreport/TimingReport_Install.exe";
				local localFile = string.format("%s/tmp/TimingReport_Install.exe", app:GetPath());
				message:AddLineSuccess("Téléchargement en cours")
				localFile = string.gsub(localFile, app.GetPathSeparator(), "/");
				if curl.DownloadFile(urlFile, localFile) ~= true then
					message.AddLineError("Erreur : Téléchargement du programme impossible");
					return;
				end
				InstalleTimingReport(localFile);
			end, btnVersionWindows); 
	else
		dlgConfig:Bind(eventType.MENU, 
			function(evt) 
				local urlFile = "https://member.fis-ski.com/software/timingreport/TimingReport_Install.dmg";
				local localFile = string.format("%s/tmp/TimingReport_Install.dmg", app:GetPath());
				message:SetValue("Téléchargement en cours")
				localFile = string.gsub(localFile, app.GetPathSeparator(), "/");
				if curl.DownloadFile(urlFile, localFile) ~= true then
					message.AddLineError("Erreur : Téléchargement du programme impossible");
					return;
				end
				InstalleTimingReport(localFile);
			end, btnVersionMac); 
	end
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			AfficheDialog1() 
		end, btnNext); 
	dlgConfig:Bind(eventType.MENU, 
		function(evt) 
			dlgConfig:EndModal(idButton.CANCEL) 
		 end,  btnClose);
	wnd.GetParentFrame():Bind(eventType.CURL, OnCurlReturn);
				
	local txt = "Vous aller créer le brouillon du Timing Report FIS pour l'événement :\n\n"..
		TR.Evenement..".\n\n"..
		"Le fichier XML sera créé avec toutes les données récupérables depuis le chronométrage de la course\n"..
		"et devra être repris avec le programme de la FIS disponible en téléchargement gratuit.\n"..
		"Celui-ci peut être installé automatiquement en cliquant sur bouton ci-dessous.\n"..
		"Vous n'aurez plus qu'à compléter les données manquantes non issues de la base de données.\n\n"..
		"Les données affichées sur la page 1 sont automatiquement sauvegardées\n"..
		"pour une utilisation ultérieure dans un autre Timing Report.\n\n";
		txt = txt.."(votre système d'exploitation est "..TR.OS..")";

	dlgConfig:GetWindowName('page0Text'):SetValue(txt);

	dlgConfig:Fit(); -- (true) pour afficher le wndDialog en pleine page ou pas
	dlgConfig:ShowModal();
end

function TelechargementImages(url)
	local localFile = string.format("%s/tmp/TimingReportImages.exe", app:GetPath());
	localFile = string.gsub(localFile, app.GetPathSeparator(), "/");
	if curl.DownloadFile(url, localFile) ~= true then
		return;
	end
	-- lancement  
	dlgConfig:EndModal(idButton.CANCEL);
	os.execute(localFile);
end

-- Point Entree Principal
function main(params)
	-- vérification de l'existence d'une version plus récente du script.
	base = base or sqlBase.Clone();
	Device = {};
	TR = {};
	TR.OS = app.GetOsDescription();
	TR.width = display:GetSize().width;
	TR.height = display:GetSize().height;
	TR.x = 0;
	TR.y = 0;

			
	scrip_version = "4.7"; 
	-- vérification de l'existence d'une version plus récente du script.
	-- Ex de retour : LiveDraw=5.94,Matrices=5.92,TimingReport=4.3,DoubleTirage=3.2,TirageOptions=3.3,TirageER=1.7,ListeMinisterielle=2.3,KandaHarJunior=2.0
	if app.GetVersion() >= '4.4c' then 
		indice_return = 3;
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
	
	local device_file = './res/tr/FIS-Timing-Devices.csv';
	if not app.FileExists(device_file) then
		app.GetAuiFrame():MessageBox(
			"Vous devez télécharger le fichier des appareils homologués.\nLe script va se fermer automatiquement.", 
			"Téléchargement du fichier supplémentaire",
			msgBoxStyle.OK + msgBoxStyle.ICON_INFORMATION); 
			local reponse = app.AutoUpdateResource('https://agilsport.fr/bta_alpin/UpdateScript.zip');
			return true;
	end

	TR.OK = true;
	TR.errormessage = "";
	TR.code_evenement = params.code_evenement or -1;
	if TR.code_evenement < 0 then
		TR.OK = false;
		TR.errormessage = TR.errormessage.."Le n° de course est incorrest !!\n";
	end
	-- en FIS, il n'y a qu'une seule épreuve
	OpenTables(TR.code_evenement);
	TR.nombre_de_manche = Epreuve:GetCellInt("Nombre_de_manche", 0);
	-- adv.Alert('TR.nombre_de_manche  = '..TR.nombre_de_manche);
	TR.saison = tonumber(Epreuve:GetCell("Code_saison", 0)) or 0;
	
	base:TableLoad(Resultat_Chrono, "Select * From Resultat_Chrono Where Code_evenement = "..TR.code_evenement);
	if TR.OK == true then
		for i = 1, TR.nombre_de_manche do
			local cmd = "Select * From Resultat_Chrono Where Code_evenement = "..TR.code_evenement.." and Code_manche = "..i.." and ABS(Dossard) > 0 And Heure > 0 And (Id = 0 Or Origine = 'D')";
			base:TableLoad(Resultat_Chrono, cmd);
			if Resultat_Chrono:GetNbRows() == 0 then
				TR.errormessage = TR.errormessage.."Il n'y a pas de départ dans cette course pour la manche "..i.." !! \n";
				-- TR.OK = false;
			end
			local cmd = "Select * From Resultat_Chrono Where Code_evenement = "..TR.code_evenement.." and Code_manche = "..i.." and ABS(Dossard) > 0 And Heure > 0 And (Id = -1 Or Origine = 'A')";
			base:TableLoad(Resultat_Chrono, cmd);
			if Resultat_Chrono:GetNbRows() == 0 then
				TR.errormessage = TR.errormessage.."Il n'y a pas d'arrivée dans cette course pour la manche "..i.." !! \n";
				-- TR.OK = false;
			end
		end
	end
	if TR.OK == false then 
		local msg = "L'environnement ne permet pas la création du Rapport Technique de Chronométrage FIS :\n\n"..TR.errormessage;
		app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
		return false;
	end
	-- on récupère toutes les données chrono de la course
	-- on crée la sqlTable complète de Device_fis et on la met dans l'environnement
	-- on crée aussi les tables des marques pour les Timer, Photocell et Start (Startgates et startdoors)
	CreateDeviceFis();
	GetSetData();
	AfficheDialog0();
end
function OnCheckBoxManche2(evt)
	if TR.nombre_de_manche > 1 then
		TR.Manche2 = true;
	else
		TR.Manche2 = false;
	end
	dlgPage2:GetWindowName('Run2BibfirstsystemB_Start'):Enable(TR.Manche2);
	dlgPage2:GetWindowName('Run2BibfirstsystemB_Finish'):Enable(TR.Manche2);
	dlgPage2:GetWindowName('Run2BibfirstsystemHand_Start'):Enable(TR.Manche2);
	dlgPage2:GetWindowName('Run2BibfirstsystemHand_Finish'):Enable(TR.Manche2);
	dlgPage2:GetWindowName('Run2BiblastsystemB_Start'):Enable(TR.Manche2);
	dlgPage2:GetWindowName('Run2BiblastsystemB_Finish'):Enable(TR.Manche2);
	dlgPage2:GetWindowName('Run2BiblastsystemHand_Start'):Enable(TR.Manche2);
	dlgPage2:GetWindowName('Run2BiblastsystemHand_Finish'):Enable(TR.Manche2);
end

function AfficheDialog2()
	dlgPage1:EndModal(idButton.OK) 

	dlgPage2 = wnd.CreateDialog(
		{
		width = TR.width,
		height = TR.height,
		x = TR.x,
		y = TR.y,
		label='Page 2 : données de chronométrage  - Timing Report version '..scrip_version; 
		icon='./res/32x32_fis.png'
		});
	dlgPage2:LoadTemplateXML({ 
		xml = './edition/editionTR_FIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		node_value = 'page2' 
	});

	-- Initialisation des Variables 
	ControlData();

	dlgPage2:GetWindowName('syncchecksystemA_Start_Synccheck'):Enable(TR.timer_startsystemA_Brand:len() > 0);
	dlgPage2:GetWindowName('syncchecksystemB_Start_Synccheck'):Enable(TR.timer_startsystemB_Brand:len() > 0);

	dlgPage2:GetWindowName('Synchronisation_Sync'):SetValue(TR.Synchronisation_Sync);
	dlgPage2:GetWindowName('Synchronisation_Handsync'):SetValue(TR.Synchronisation_Handsync);
	dlgPage2:GetWindowName('syncchecksystemA_Synccheck'):SetValue(TR.syncchecksystemA_Synccheck);
	dlgPage2:GetWindowName('syncchecksystemB_Synccheck'):SetValue(TR.syncchecksystemB_Synccheck);
	

	if TR.timer_startsystemA_Brand:len() > 0 then
		dlgPage2:GetWindowName('syncchecksystemA_Start_Synccheck'):SetValue(TR.syncchecksystemAStart_Synccheck);
	end
	
	if TR.timer_startsystemB_Brand:len() > 0 then
		dlgPage2:GetWindowName('syncchecksystemB_Start_Synccheck'):SetValue(TR.syncchecksystemBStart_Synccheck);
	end

	for i = 1, TR.nombre_de_manche do
		dlgPage2:GetWindowName('Run'..i..'BibfirstsystemA_Start'):SetValue(TR[i].BibfirstsystemA_Start);
		dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Start'):SetValue(TR[i].BibfirstsystemB_Start);
		dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Start'):SetValue(TR[i].BibfirstsystemHand_Start);
		dlgPage2:GetWindowName('Run'..i..'BibfirstsystemA_Finish'):SetValue(TR[i].BibfirstsystemA_Finish);
		dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Finish'):SetValue(TR[i].BibfirstsystemB_Finish);
		dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Finish'):SetValue(TR[i].BibfirstsystemHand_Finish);
		dlgPage2:GetWindowName('Run'..i..'BiblastsystemA_Start'):SetValue(TR[i].BiblastsystemA_Start);
		dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Start'):SetValue(TR[i].BiblastsystemB_Start);
		dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Start'):SetValue(TR[i].BiblastsystemHand_Start);
		dlgPage2:GetWindowName('Run'..i..'BiblastsystemA_Finish'):SetValue(TR[i].BiblastsystemA_Finish);
		dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Finish'):SetValue(TR[i].BiblastsystemB_Finish);
		dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Finish'):SetValue(TR[i].BiblastsystemHand_Finish);
		dlgPage2:GetWindowName('Run'..i..'Bibfirst_Net'):SetValue(TR[i].Bibfirst.Net..' - ( '..TR[i].Bibfirst.Bib..' )');
		dlgPage2:GetWindowName('Run'..i..'Biblast_Net'):SetValue(TR[i].Biblast.Net..' - ( '..TR[i].Biblast.Bib..' )');
		dlgPage2:GetWindowName('Run'..i..'BestA_Time'):SetValue(TR[i].BestA_Time..' - ( '..TR[i].BestA_Bib..' )');
		dlgPage2:GetWindowName('Run'..i..'BestAName'):SetValue(TR[i].BestA_Name);
	end

	-- Toolbar Principale ...
	local tbpage2 = dlgPage2:GetWindowName('tbpage2');
	tbpage2:AddStretchableSpace();
	local btnSave = tbpage2:AddTool("Enregistrer", "./res/32x32_save.png");
	tbpage2:AddSeparator();
	local btnClose = tbpage2:AddTool("Fermer", "./res/32x32_exit.png");
	tbpage2:AddStretchableSpace();
	tbpage2:Realize();

	tbpage2:Bind(eventType.MENU, 
			function(evt) 
				TR.XML = app.GetPath().."/tmp/"..TR.saison..TR.Sector..TR.Codex.."TR.xml";
				TR.XML = string.gsub(TR.XML, "\\", "/");
				OnSaveXML(TR.XML, true)
				dlgPage2:MessageBox("Le fichier "..TR.XML.." a été enregistré avec succès.\nVous devez finaliser le rapport en l'ouvrant avec le programme de la FIS.", "Création du fichier "..TR.XML, msgBoxStyle.OK+msgBoxStyle.ICON_INFORMATION);
				dlgPage2:EndModal(idButton.CANCEL) 
			end, btnSave);
	tbpage2:Bind(eventType.MENU, 
			function(evt) 
				dlgPage2:EndModal(idButton.CANCEL) 
			end, btnClose);
	dlgPage2:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeHeure(dlgPage2:GetWindowName('Synchronisation_Sync'), 8)
			end,  dlgPage2:GetWindowName('Synchronisation_Sync'));
	dlgPage2:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeHeure(dlgPage2:GetWindowName('Synchronisation_Handsync'), 8)
			end,  dlgPage2:GetWindowName('Synchronisation_Handsync'));
	dlgPage2:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeHeure(dlgPage2:GetWindowName('syncchecksystemA_Synccheck'), 12)
			end,  dlgPage2:GetWindowName('syncchecksystemA_Synccheck'));
	dlgPage2:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeHeure(dlgPage2:GetWindowName('syncchecksystemB_Synccheck'), 12)
			end,  dlgPage2:GetWindowName('syncchecksystemB_Synccheck'));
	dlgPage2:Bind(eventType.TEXT,
			function(evt) 
				OnChangeHeure(dlgPage2:GetWindowName('syncchecksystemAStart_Synccheck'), 12)
			end,  dlgPage2:GetWindowName('syncchecksystemAStart_Synccheck'));
	dlgPage2:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeHeure(dlgPage2:GetWindowName('syncchecksystemB_Synccheck'), 12)
			end,  dlgPage2:GetWindowName('syncchecksystemB_Synccheck'));
	dlgPage2:Bind(eventType.TEXT, 
			function(evt) 
				OnChangeHeure(dlgPage2:GetWindowName('syncchecksystemBStart_Synccheck'), 12)
			end,  dlgPage2:GetWindowName('syncchecksystemBStart_Synccheck'));
	
	for i = 1, 2 do
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Start'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Start'));
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Start'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Start'));
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Start'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Start'));
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Start'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Start'));
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Finish'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BibfirstsystemB_Finish'));
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Finish'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BiblastsystemB_Finish'));
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Finish'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BibfirstsystemHand_Finish'));
		dlgPage2:Bind(eventType.TEXT, 
				function(evt) 
					OnChangeHeure(dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Finish'), 12) 
				end,  dlgPage2:GetWindowName('Run'..i..'BiblastsystemHand_Finish'));
	end
	OnCheckBoxManche2();
	
	-- dlgPage2:Fit(true); -- pour afficher le wndDialog en pleine page ou pas
	dlgPage2:Fit();
	dlgPage2:ShowModal();
end


function SetValuesPage1()
	
	TR.software_Version = app.GetVersion().."_TR_"..scrip_version;
	dlgPage1:GetWindowName('software'):SetValue(app.GetName());
	dlgPage1:GetWindowName('software_version'):SetValue(TR.software_Version);
	
	dlgPage1:GetWindowName('chiefoftiming_Lastname'):SetValue(TR.chiefoftiming_Lastname);
	dlgPage1:GetWindowName('chiefoftiming_Firstname'):SetValue(TR.chiefoftiming_Firstname);
	dlgPage1:GetWindowName('chiefoftiming_Nation'):SetValue(TR.chiefoftiming_Nation);
	dlgPage1:GetWindowName('chiefoftiming_Email'):SetValue(TR.chiefoftiming_Email);
	dlgPage1:GetWindowName('chiefoftiming_Phonenbr'):SetValue(TR.chiefoftiming_Phonenbr);
	
	dlgPage1:GetWindowName('timekeeper_Lastname'):SetValue(TR.timekeeper_Lastname);
	dlgPage1:GetWindowName('timekeeper_Firstname'):SetValue(TR.timekeeper_Firstname);
	dlgPage1:GetWindowName('timekeeper_Nation'):SetValue(TR.timekeeper_Nation);
	dlgPage1:GetWindowName('timekeeper_Phonenbr'):SetValue(TR.timekeeper_Phonenbr);
	dlgPage1:GetWindowName('timekeeper_Email'):SetValue(TR.timekeeper_Email);
	dlgPage1:GetWindowName('timekeeper_Company'):SetValue(TR.timekeeper_Company);

	GetTD();
	
	dlgPage1:GetWindowName('technicaldelegate_Lastname'):SetValue(TR.technicaldelegate_Lastname);
	dlgPage1:GetWindowName('technicaldelegate_Firstname'):SetValue(TR.technicaldelegate_Firstname);
	dlgPage1:GetWindowName('technicaldelegate_Nation'):SetValue(TR.technicaldelegate_Nation);
	dlgPage1:GetWindowName('technicaldelegate_Number'):SetValue(TR.technicaldelegate_Number);
	dlgPage1:GetWindowName('technicaldelegate_Email'):SetValue(TR.technicaldelegate_Email);
	dlgPage1:GetWindowName('timersystemA_Brand'):SetValue(TR.timersystemA_Brand);
	dlgPage1:GetWindowName('timersystemA_Model'):SetValue(TR.timersystemA_Model);
	dlgPage1:GetWindowName('timersystemA_Serial'):SetValue(TR.timersystemA_Serial);
	dlgPage1:GetWindowName('timersystemA_Homologation'):SetValue(TR.timersystemA_Homologation);
	dlgPage1:GetWindowName('timer_startsystemA_Brand'):SetValue(TR.timer_startsystemA_Brand);
	dlgPage1:GetWindowName('timer_startsystemA_Model'):SetValue(TR.timer_startsystemA_Model);
	dlgPage1:GetWindowName('timer_startsystemA_Serial'):SetValue(TR.timer_startsystemA_Serial);
	dlgPage1:GetWindowName('timer_startsystemA_Homologation'):SetValue(TR.timer_startsystemA_Homologation);

	dlgPage1:GetWindowName('finishcellssystemA_Brand'):SetValue(TR.finishcellssystemA_Brand);
	dlgPage1:GetWindowName('finishcellssystemA_Model'):SetValue(TR.finishcellssystemA_Model);
	dlgPage1:GetWindowName('finishcellssystemA_Serial'):SetValue(TR.finishcellssystemA_Serial);
	dlgPage1:GetWindowName('finishcellssystemA_Homologation'):SetValue(TR.finishcellssystemA_Homologation);

	dlgPage1:GetWindowName('startdevice_Brand'):SetValue(TR.startdevice_Brand);
	dlgPage1:GetWindowName('startdevice_Model'):SetValue(TR.startdevice_Model);
	dlgPage1:GetWindowName('startdevice_Serial'):SetValue(TR.startdevice_Serial);
	dlgPage1:GetWindowName('startdevice_Homologation'):SetValue(TR.startdevice_Homologation);

	dlgPage1:GetWindowName('timersystemB_Brand'):SetValue(TR.timersystemB_Brand);
	dlgPage1:GetWindowName('timersystemB_Model'):SetValue(TR.timersystemB_Model);
	dlgPage1:GetWindowName('timersystemB_Serial'):SetValue(TR.timersystemB_Serial);
	dlgPage1:GetWindowName('timersystemB_Homologation'):SetValue(TR.timersystemB_Homologation);

	dlgPage1:GetWindowName('timer_startsystemB_Brand'):SetValue(TR.timer_startsystemB_Brand);
	dlgPage1:GetWindowName('timer_startsystemB_Model'):SetValue(TR.timer_startsystemB_Model);
	dlgPage1:GetWindowName('timer_startsystemB_Serial'):SetValue(TR.timer_startsystemB_Serial);
	dlgPage1:GetWindowName('timer_startsystemB_Homologation'):SetValue(TR.timer_startsystemB_Homologation);

	dlgPage1:GetWindowName('finishcellssystemB_Brand'):SetValue(TR.finishcellssystemB_Brand);
	dlgPage1:GetWindowName('finishcellssystemB_Model'):SetValue(TR.finishcellssystemB_Model);
	dlgPage1:GetWindowName('finishcellssystemB_Serial'):SetValue(TR.finishcellssystemB_Serial);
	dlgPage1:GetWindowName('finishcellssystemB_Homologation'):SetValue(TR.finishcellssystemB_Homologation);

	dlgPage1:GetWindowName('modesystemA_Mode'):SetValue(TR.modesystemA_Mode);
	dlgPage1:GetWindowName('modesystemB_Mode'):SetValue(TR.modesystemB_Mode);
	dlgPage1:GetWindowName('modevoice_Voice'):SetValue(TR.modevoice_Voice);

	dlgPage1:GetWindowName('Racedate'):SetValue(TR.Day..'-'..TR.Month.."-"..TR.Year);
	dlgPage1:GetWindowName('Codex'):SetValue(TR.Codex);
	dlgPage1:GetWindowName('Categorie'):SetValue(TR.category);
	AfficheDevice('a', TR.timersystemA_Model);
	AfficheDevice('b', TR.timersystemB_Model);
end

function AfficheDialog1()
	if Resultat_Chrono:GetNbRows() == 0 then
		msg = "La course n'a pas (encore) été chronométrée en base de temps sur cet ordinateur.\nVous ne pourrez enregistrer que les données de la page 1.";
		app.GetAuiFrame():MessageBox(msg, "Attention", msgBoxStyle.OK+msgBoxStyle.ICON_WARNING)
	end
	dlgConfig:EndModal(idButton.CANCEL) 
	dlgPage1 = wnd.CreateDialog(
		{
		width = TR.width,
		height = TR.height,
		x = TR.x,
		y = TR.y,
		label='Page 1 des données à saisir - Timing Report version '..scrip_version;
		icon='./res/32x32_fis.png'
		});
	dlgPage1:LoadTemplateXML({ 
		xml = './edition/editionTR_FIS.xml',
		node_name = 'root/panel', 
		node_attr = 'name', 	
		node_value = 'page1' 
	});
	
	-- Initialisation des Variables 
	
	Brand_Timer:SetCounter('Brand');
	local tBrand_Timer = Brand_Timer:GetCounter('Brand');
	-- for j=0, tMarque:GetNbRows()-1 do
		-- adv.Alert(tMarque:GetCell(0,j)..'='..tMarque:GetCell(1,j));
		-- adv.Alert(tMarque:GetCell('Brand',j)..'='..tMarque:GetCell('_count_',j));
	-- end

	Brand_Photocell:SetCounter('Brand');
	local tBrand_Photocell = Brand_Photocell:GetCounter('Brand');

	Brand_Start:SetCounter('Brand');
	local tBrand_Start = Brand_Start:GetCounter('Brand');

	dlgPage1:GetWindowName('timersystemA_Brand'):SetTable(tBrand_Timer, 'Brand', 'Brand');
	dlgPage1:GetWindowName('timersystemB_Brand'):SetTable(tBrand_Timer, 'Brand', 'Brand');
	dlgPage1:GetWindowName('timer_startsystemA_Brand'):SetTable(tBrand_Timer, 'Brand', 'Brand');
	dlgPage1:GetWindowName('timer_startsystemB_Brand'):SetTable(tBrand_Timer, 'Brand', 'Brand');
	dlgPage1:GetWindowName('finishcellssystemA_Brand'):SetTable(tBrand_Photocell, 'Brand', 'Brand');
	dlgPage1:GetWindowName('finishcellssystemB_Brand'):SetTable(tBrand_Photocell, 'Brand', 'Brand');
	dlgPage1:GetWindowName('startdevice_Brand'):SetTable(tBrand_Start, 'Brand', 'Brand');
	
	dlgPage1:GetWindowName('modesystemA_Mode'):Append("Cable");
	dlgPage1:GetWindowName('modesystemB_Mode'):Append("Cable");
	dlgPage1:GetWindowName('modevoice_Voice'):Append("Cable");
	dlgPage1:GetWindowName('modesystemA_Mode'):Append("LAN");
	dlgPage1:GetWindowName('modesystemB_Mode'):Append("LAN");
	dlgPage1:GetWindowName('modevoice_Voice'):Append("LAN");
	dlgPage1:GetWindowName('modesystemA_Mode'):Append("WLAN");
	dlgPage1:GetWindowName('modesystemB_Mode'):Append("WLAN");
	dlgPage1:GetWindowName('modevoice_Voice'):Append("WLAN");
	dlgPage1:GetWindowName('modesystemA_Mode'):Append("Radio");
	dlgPage1:GetWindowName('modesystemB_Mode'):Append("Radio");
	dlgPage1:GetWindowName('modevoice_Voice'):Append("Radio");
	dlgPage1:GetWindowName('modesystemA_Mode'):Append("Mobile");
	dlgPage1:GetWindowName('modesystemB_Mode'):Append("Mobile");
	dlgPage1:GetWindowName('modevoice_Voice'):Append("Mobile");
	dlgPage1:GetWindowName('modesystemA_Mode'):Append("USB");
	dlgPage1:GetWindowName('modesystemB_Mode'):Append("USB");
	dlgPage1:GetWindowName('modevoice_Voice'):Append("USB");
	dlgPage1:GetWindowName('modesystemA_Mode'):Append("Other");
	dlgPage1:GetWindowName('modesystemB_Mode'):Append("Other");
	dlgPage1:GetWindowName('modevoice_Voice'):Append("Other");
		
	-- local TR.doc = xmlDocument.Create("./edition/2019AL1245TR.xml");
	if app.FileExists('./edition/TRini.xml') then
		-- adv.Alert('----------------- lecture de TRini.xml\n')
		TR.XML = app.GetPath().."/edition/TRini.xml";
		TR.doc = xmlDocument.Create(TR.XML);
		if TR.doc ~= nil then
			local root = TR.doc:GetRoot();
			if root ~= nil then
				racine = '';
				LectureXML(root);	-- lecture du TRini.xml
				GetCartouche();
				ControlData();				
			end
			TR.doc.Delete();
		end
		-- adv.Alert('\n----------------- fin de lecture de TRini.xml\n')
	end
	if not app.FileExists('./res/tr/WIRC.jpg') then
		local url = 'http://188.165.236.85/maj_pg/tr/TimingReportImages2.exe';
		adv.Alert('./res/tr/WIRC.jpg existe pas')
		local msg = "Voulez-vous télécharger les images manquantes pour les appareils homologués ? ";
		if app.GetAuiFrame():MessageBox(msg, "Télécharger les images manquantes", msgBoxStyle.YES_NO+msgBoxStyle.ICON_WARNING) == msgBoxStyle.YES then
			if not app.FileExists('./res/tr/RLS1.jpg') then
				adv.Alert('./res/tr/RLS1.jpg existe pas')
				url = 'http://188.165.236.85/maj_pg/tr/TimingReportImages.exe';
			end
			TelechargementImages(url);
		end
	end

	GetCartouche();
	ControlData();  
	SetValuesPage1();
	PopulateCombo(false);
	
	-- Toolbar Principale ...
	local tbpage1 = dlgPage1:GetWindowName('tbpage1');
	tbpage1:AddStretchableSpace();
	local btnNext = tbpage1:AddTool("Page 2", "./res/vpe32x32_page_next.png");
	tbpage1:AddSeparator();
	local btnOpenXML = tbpage1:AddTool("Ouvrir un Timing Report XML", "./res/32x32_import.png");
	tbpage1:AddSeparator();
	local btnSave = tbpage1:AddTool("Enregistrer les données", "./res/32x32_save.png");
	tbpage1:AddSeparator();
	local btnClose = tbpage1:AddTool("Quitter", "./res/32x32_exit.png");
	tbpage1:AddStretchableSpace();
	tbpage1:Realize();
	tbpage1:EnableTool(btnNext:GetId(), not Eval(Resultat_Chrono:GetNbRows(), 0)); 

	dlgPage1:Bind(eventType.MENU, 
		function(evt) 
			TR.XML = app.GetPath().."/edition/TRini.xml";
			TR.XML = string.gsub(TR.XML, "\\", "/");
			OnSaveXML(TR.XML, false);
			if not TR.XML_lu then
				local msg = "Attention, Si vous avez déjà enregistré les données de la manche 1,\n"..
							"vous devez Ouvrir le Timing Report déjà enregistré.\n"..
							"Sinon les données de la manche 1 du Système B seront effacées.\n"..
							"Voulez-vous poursuivre ?";
				if app.GetAuiFrame():MessageBox(msg,
						"Passer sur la page 2", 
						msgBoxStyle.YES+msgBoxStyle.NO+msgBoxStyle.NO_DEFAULT+msgBoxStyle.ICON_WARNING
						) == msgBoxStyle.NO then
					return;
				end
			end
			AfficheDialog2();
		end, btnNext); 
	dlgPage1:Bind(eventType.MENU, 
		function(evt) 
			TR.XML = app.GetPath().."/edition/TRini.xml";
			TR.XML = string.gsub(TR.XML, "\\", "/");
			OnSaveXML(TR.XML, false)
		end, btnSave); 
	dlgPage1:Bind(eventType.MENU, 
		function(evt) 
			local fileDialog = wnd.CreateFileDialog(dlgPage2,
				"Sélection du fichier de Timing Report",
				'./tmp', 
				"",
				"*.xml|*.xml",
				fileDialogStyle.OPEN+fileDialogStyle.FD_FILE_MUST_EXIST
			);
			if fileDialog:ShowModal() == idButton.OK then
				TR.XML = string.gsub(fileDialog:GetPath(), app.GetPathSeparator(), "/");
				TR.doc = xmlDocument.Create(TR.XML);
				if TR.doc ~= nil then
					local root = TR.doc:GetRoot();
					if root ~= nil then
						-- adv.Alert('\n-------------- lecture de '..TR.XML..'\n');
						racine = '';
						LectureXML(root);	-- lecture du TRini.xml
						GetCartouche();
						ControlData();  
						SetValuesPage1();
						PopulateCombo(true);
					end
					TR.doc.Delete();
				end
				TR.XML_lu = true;
			end
		end, btnOpenXML); 
	dlgPage1:Bind(eventType.MENU, 
		function(evt) 
			dlgPage1:EndModal(idButton.CANCEL) 
		 end,  btnClose);
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboBrand('timersystemA_Brand', 'Timer')
		end, dlgPage1:GetWindowName('timersystemA_Brand'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboBrand('timersystemB_Brand', 'Timer')
		end, dlgPage1:GetWindowName('timersystemB_Brand'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboBrand('timer_startsystemA_Brand', 'Timer')
		end, dlgPage1:GetWindowName('timer_startsystemA_Brand'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboBrand('timer_startsystemB_Brand', 'Timer')
		end, dlgPage1:GetWindowName('timer_startsystemB_Brand'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboBrand('finishcellssystemA_Brand', 'Photocell')
		end, dlgPage1:GetWindowName('finishcellssystemA_Brand'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboBrand('finishcellssystemB_Brand', 'Photocell')
		end, dlgPage1:GetWindowName('finishcellssystemB_Brand'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboBrand('startdevice_Brand', 'Start')
		end, dlgPage1:GetWindowName('startdevice_Brand'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboModel("timersystemA_Model")
		end, dlgPage1:GetWindowName('timersystemA_Model'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboModel("timer_startsystemA_Model")
		end, dlgPage1:GetWindowName('timer_startsystemA_Model'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboModel("finishcellssystemA_Model")
		end, dlgPage1:GetWindowName('finishcellssystemA_Model'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboModel("startdevice_Model")
		end, dlgPage1:GetWindowName('startdevice_Model'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboModel("timersystemB_Model")
		end, dlgPage1:GetWindowName('timersystemB_Model'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboModel("timer_startsystemB_Model")
		end, dlgPage1:GetWindowName('timer_startsystemB_Model'));
	dlgPage1:Bind(eventType.COMBOBOX, 
		function(evt) 
			OnChangeComboModel("finishcellssystemB_Model")
		end, dlgPage1:GetWindowName('finishcellssystemB_Model'));
	
	SetValuesPage1()
	dlgPage1:Fit(); 
	dlgPage1:ShowModal();
end
