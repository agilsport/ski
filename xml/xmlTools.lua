case_sensitive = case_sensitive or false; -- Flag distinction majuscule-minuscule pour le nom des attributs et des balises  
tags_ffs = tags_ffs or false; -- Flag pour la génération des Balises FFS

function SetAttributes(t, name, value)
	t.attributes = t.attributes or {};
	t.attributes[name] = value;
end

-- Fonctions pour les Messages
function isRunning()
	local msg = base:GetMessage();
	if msg ~= nil then
		return msg:IsRunning();
	else
		return true;
	end
end

function MessageError(txt)
	local msg = base:GetMessage();
	if msg ~= nil then
		msg:AddLineError(txt);
	else
		wnd.MessageBox(nil, txt, "Erreur");
	end
end

function MessageSuccess(txt)
	local msg = base:GetMessage();
	if msg ~= nil then
		msg:AddLineSuccess(txt);
	end
end

function MessageWarning(txt)
	local msg = base:GetMessage();
	if msg ~= nil then
		msg:AddLineWarning(txt);
	end
end

function Message(txt)
	local msg = base:GetMessage();
	if msg ~= nil then
		msg:AddLine(txt);
	end
end