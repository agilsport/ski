dofile('./interface/uty.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { version = 2.0, code = 'phone_chrono', name = 'Phone Chrono', class = 'chrono' }
end	

function Error(txt)
	app.GetAuiMessage():AddLineError(txt);
end

function Alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function device.OnInit(params)
	-- Url Init ...
	device.url = 'http://37.187.252.152/club_esf';
--	device.url = 'http://localhost/club_esf';
	
	-- Ack Init ...
	device.stackAck = {};
	device.lastAck = -1;
	local doc = curl.GET_XML(device.url..'/ack.php');
	if doc ~= nil then
		device.ReadAckXML(doc);
		doc:Delete();
	end

	-- Timer Init ...
	local frame = app.GetAuiFrame();
	device.timer = timer.Create(frame);
	local timerID =  device.timer:GetId();
	device.timer:Start(1000);
	frame:Bind(eventType.TIMER, device.OnTimer, device.timer, device);
end

function device.OnTimer(evt, device)
	local doc = curl.GET_XML(device.url..'/passage.php?ack='..device.lastAck);
	if doc ~= nil then
		device.ReadPassageXML(doc);
		doc:Delete();
	end
end

function device.ReadAckXML(doc)
	local root = doc:GetRoot();
	if root ~= nil then
		if root:HasAttribute('ack') then
			local ack = tonumber(root:GetAttribute('ack'));
			if ack >= 0 and device.stackAck[ack] == nil then
				device.lastAck = ack;
			end
		end
	end
end

function device.ReadPassageXML(doc)
	local root = doc:GetRoot();
	if root ~= nil then
		if root:HasAttribute('ack') then
			local ack = tonumber(root:GetAttribute('ack'));
			if ack >= 0 and device.stackAck[ack] == nil then
				device.stackAck[ack] = true;
				device.lastAck = ack;
				
				local chrono = root:GetAttribute('chrono', '');
				local passage = root:GetAttribute('passage', '0');
				local bib = root:GetAttribute('bib');
				if tonumber(chrono) > 0 then
					AddTimePassage(chrono, passage, bib);
				end
				
--				Alert("Ack = "..device.lastAck);
			end
		end
	end
end

function device.OnClose()
	if device.timer ~= nil then
		device.timer:Delete();
		device.timer = nil;
	end
end

function AddTimePassage(chrono, passage, bib)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, bib = bib, device = 'phone_chrono' }
	);
end


