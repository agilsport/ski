var theTv = {
	full_screen : false,
	delay_list : 12000,
	start : 1,
	count : 14,
	timer_list : -1,

	tick_list : '',
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
		SetTitle(context.Title);
	}
}

function RefreshList()
{
	var param = 'start='+theTv.start+'&count='+theTv.count;
	$.ajax({ type: "GET", url: "./ajax_startlist.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.startlist == 'object')
					{
						ShowList(jsonData.startlist);
						theTv.start = jsonData.next;
					}
                }
    });

	theTv.timer_list = setTimeout("RefreshList()", theTv.delay_list);
    return false;
}

function HideRow(row)
{
	$('#block_start_list .row'+row).hide();
}

function ShowRow(row)
{
	$('#block_start_list .row'+row).show();

/*
	animateCSS('#block_start_list .row'+row+' .bib', 'bounceInLeft');
	animateCSS('#block_start_list .row'+row+' .identity', 'bounceInRight');
	animateCSS('#block_start_list .row'+row+' .team', 'bounceInLeft');
*/
}

function HideRows()
{
	for (var i=1;i<=14;i++)
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
		$('#block_start_list .row'+row+' .bib').html(rlist.Bib);

	if (typeof rlist.Identity == 'string')
		$('#block_start_list .row'+row+' .identity').html(rlist.Identity);

	if (typeof rlist.Team == 'string')
		$('#block_start_list .row'+row+' .team').html(rlist.Team);

	ShowRow(row);
}

function Init()
{
	RefreshContext();
	RefreshList();
}

