var theTv = {
	full_screen : false,
	delay_list : 12000,
	start : 1,
	// nombre de ligne a afficher 1er seul ds le fichier
	count : 20,
	timer_list : -1,

	tick_list : '',
	mode : ''
};

function RefreshContext()
{
	$.ajax({ type: "GET", url: "./ajax_context.php", dataType: "json", cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.context == 'object')
					{
						ShowContext(jsonData.context);
					}
                }
    });
	return false;
}

function ShowContext(context)
{
	if (typeof context.Mode == 'string')
	{
		theTv.mode = context.Mode;
		SetTitle(context.Title);
	}
}

function RefreshList()
{
	var param = 'start='+theTv.start+'&count='+theTv.count;
	$.ajax({ type: "GET", url: "./ajax_ranking.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.ranking == 'object')
					{
						ShowList(jsonData.ranking);
						theTv.start = jsonData.next;
					}
                }
    });

	theTv.timer_list = setTimeout("RefreshList()", theTv.delay_list);
    return false;
}

function HideRow(row)
{
	$('#block_ranking .row'+row).hide();
}

function ShowRow(row)
{
	$('#block_ranking .row'+row).show();
}

function HideRows()
{
	// nombre de ligne a afficher 2eme seul ds le fichier
	for (var i=1;i<=20;i++)
		HideRow(i);
}

function ShowList(list)
{
	HideRows();
	if (typeof list[0].Tick == 'string')
	{
		theTv.tick_list = list[0].Tick;
		for (var i=0;i<list.length;i++)
		{
			SetRow(i+1, list[i]);
		}
	}
}

function SetRow(row, rlist)
{
	if (typeof rlist.Bib == 'string')
		$('#block_ranking .row'+row+' .bib').html(rlist.Bib);

	if (typeof rlist.Identity == 'string')
		$('#block_ranking .row'+row+' .identity').html(rlist.Identity);

	if (typeof rlist.Team == 'string')
		$('#block_ranking .row'+row+' .team').html(rlist.Team);

	if (theTv.mode == 'ranking')
	{
		if (typeof rlist.Rank1 == 'string')
			$('#block_ranking .row'+row+' .rank').html(rlist.Rank1);
		else
			$('#block_ranking .row'+row+' .rank').html('');
		
		if (typeof rlist.Time1 == 'string')
			$('#block_ranking .row'+row+' .time').html(rlist.Time1);
		else
			$('#block_ranking .row'+row+' .time').html('');
		
		if (typeof rlist.Cltc1 == 'string')
			$('#block_ranking .row'+row+' .cltc').html(rlist.Cltc1);
		else
			$('#block_ranking .row'+row+' .cltc').html('');
	}
	else
	{
		if (typeof rlist.Rank == 'string')
			$('#block_ranking .row'+row+' .rank').html(rlist.Rank);
		else
			$('#block_ranking .row'+row+' .rank').html('');

		if (typeof rlist.Time == 'string')
			$('#block_ranking .row'+row+' .time').html(rlist.Time);
		else
			$('#block_ranking .row'+row+' .time').html('');
		
		if (typeof rlist.Cltc == 'string')
			$('#block_ranking .row'+row+' .cltc').html(rlist.Cltc);
		else
			$('#block_ranking .row'+row+' .cltc').html('');
	}

	ShowRow(row);
}

function Init()
{
	RefreshContext();
	RefreshList();
}

