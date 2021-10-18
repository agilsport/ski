-- AGIL TIMEBOX - CONTACTOR-BOX
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 1.6, 
		code = 'agil_timebox',
		name = 'Agil TimeBox', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '19200' } } 
	};
end	

function device.OnSerial(evt)
	if evt:GetInt() == serialNotify.CONNECTION then
		app.GetAuiMessage():AddLineSuccess(evt:GetString());

		local parentFrame = wnd.GetParentFrame();
		parentFrame:Bind(eventType.SERIAL_PULSE, device.OnSerialPulse, mt_device.obj);
		mt_device.obj:StartModePulse();
	else
		app.GetAuiMessage():AddLineError(evt:GetString());
	end
end

function device.OnSerialPulse(evt)
	local passage = evt:GetInt();
	if (passage & 1) ~= 0 then AddTimePassage(evt:GetExtraLong(), 0) end -- Depart
	if (passage & 2) ~= 0 then AddTimePassage(evt:GetExtraLong(), 1) end -- Inter 1
	if (passage & 4) ~= 0 then AddTimePassage(evt:GetExtraLong(), 2) end -- Inter 2
	if (passage & 8) ~= 0 then AddTimePassage(evt:GetExtraLong(), -1) end -- Arrivée
end

function AddTimePassage(chrono, passage)
	app.SendNotify("<passage_add>", 
		{ time = chrono,  passage = passage, device = 'agil_timebox' }
	);
end

function device.OnClose()
	if mt_device.obj ~= nil then 
		mt_device.obj:StopModePulse();
	end
	
	-- Appel OnClose Metatable
	mt_device.OnClose();
end
