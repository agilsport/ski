dofile('./interface/adv.lua');
dofile('./interface/interface.lua');
dofile('./interface/device.lua');
-- version 1.0

function alert(txt)
	app.GetAuiMessage():AddLine(txt);
end

function main(params)
	
	theParams = params;
	base = sqlBase.Clone();
	body = base.CreateTableRanking({ 
		code_evenement = theParams.code_evenement, 
		code_epreuve = theParams.code_epreuve, 
		code_manche = theParams.code_manche,
		Organisateur = theParams.Organisateur,
		Club = theParams.Club,
	Comite = theParams.Code_comite,
	codeActivite = theParams.Code_activite

		
	});
	-- Creation du Report
	report = wnd.LoadTemplateReportXML({
		xml = './edition/TicketsCourse.xml',
		node_name = 'root/report',
		node_attr = 'id',
		node_value = 'Edt_TicketCourse' ,
		
		base = base,
		body = body,
		
		params = theParams
	});

end
