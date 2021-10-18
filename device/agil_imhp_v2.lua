-- AGIL IMHP Version 2
dofile('./interface/interface.lua');
dofile('./interface/adv.lua');
dofile('./interface/device.lua');

-- Information : Numéro de Version, Nom, Interface
function device.GetInformation()
	return { 
		version = 1.2, 
		name = 'AGIL IMHP Version 2', 
		class = 'chrono', 
		interface = { { type='serial', baudrate = '19200' } } 
	};
end	

-- Ouverture
function device.OnInit(params, node)
	-- Appel OnInit Metatable
	mt_device.OnInit(params);
	
	dllChrono = app.LoadDllChrono('IMHP870V2.dll');
end

-- Fermeture
function device.OnClose()
	if dllChrono ~= nil then
		app.UnloadDllChrono(dllChrono);
	end
	
	-- Appel OnClose Metatable
	mt_device.OnClose();
end

-- Lecture du Buffer Circulaire ...
function device.OnRead(cb)
	if cb ~= nil and dllChrono ~= nil then
		local txt = cb:ReadString();
		app.ReadBufferDllChrono(dllChrono, txt);
		app.GetAuiMessage():AddLine(txt);
	end
end

function SendData(data)
	if mt_device.obj ~= nil and data ~= nil then
		mt_device.obj:WriteString(data);
	end
end

