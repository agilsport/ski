var theTv = {
	full_screen : false,
	id : '',
	mode : '',
	title : '',

	epreuve : -1,
	categ : '',
	sex : '',
	distance : '',
	finish : '',

	delay_startlist : 12000,
	start_starlist : 1,
	count_starlist : 14,

	delay_ranking : 12000,
	start_ranking : 1,
	start_ranking_current : 1,
	// nombre de concurents dans le tableau ranking 1ere ligne a modif  il y en a une autre plus bas
	count_ranking : 20,

	tick_ranking : '',
	tick_running : '',

	timer_startlist : -1,
	timer_ranking : -1,

	delay_context : 2000,
};

function ModeStarlist()
{
	theTv.start_starlist = 1;
	
    $.ajax({ type: "GET", url: "./ajax_mode_startlist.php", dataType: "html", data: '', cache: false, 
             success: function(htmlData) { 
				$('body').html(htmlData); 
				SetMode('Liste de Départ '+theTv.title);
				SetClickFullScreen(); 
				RefreshStartlist();
			}
	});
}

function ModeRanking()
{
	theTv.start_ranking = 1;

    $.ajax({ type: "GET", url: "./ajax_mode_ranking.php", dataType: "html", data: '', cache: false, 
             success: function(htmlData) { 
				$('body').html(htmlData); 
				SetMode('Classement '+theTv.title);
				SetClickFullScreen(); 
				RefreshRanking();
				RefreshClockRunning();
			}
	});
}

function ModeRanking2()
{
	theTv.start_ranking = 1;

    $.ajax({ type: "GET", url: "./ajax_mode_ranking2.php", dataType: "html", data: '', cache: false, 
             success: function(htmlData) { 
				$('body').html(htmlData); 
				SetMode('Classement');
				SetClickFullScreen(); 
				RefreshRanking();
				RefreshClockRunning();
			}
	});
}

function ModeClear()
{
    $.ajax({ type: "GET", url: "./ajax_mode_clear.php", dataType: "html", data: '', cache: false, 
             success: function(htmlData) { $('body').html(htmlData); SetClickFullScreen(); }
	});
}

function RefreshContext()
{
	var param = 'id='+theTv.id;
	$.ajax({ type: "GET", url: "./ajax_context.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.context == 'object')
					{
						ShowContext(jsonData.context);
					}
                }
    });

	setTimeout("RefreshContext()", theTv.delay_context);
	return false;
}

function ShowContext(context)
{
	if (typeof context.Mode == 'string')
	{
		if (context.Mode != theTv.mode)
		{
//			alert('changeContext '+context.Mode);

			clearTimeout(theTv.timer_startlist);
			clearTimeout(theTv.timer_ranking);
			clearTimeout(theTv.timer_running);

			theTv.mode = context.Mode;
			if (context.Mode == 'startlist')
			{
				ModeStarlist();
				return false;
			}
			else if (context.Mode == 'ranking')
			{
				ModeRanking();
				return false;
			}
			else if (context.Mode == 'ranking2')
			{
				ModeRanking2();
				return false;
			}
			else if (context.Mode == 'clear')
			{
				ModeClear();
				return false;
			}
		}
	}
}

function RefreshStartlist()
{
	var param;
	param  = 'start='+theTv.start_starlist+'&count='+theTv.count_starlist;
	param += '&epreuve='+theTv.epreuve+'&categ='+theTv.categ+'&sex='+theTv.sex+'&distance='+theTv.distance;
	
//	alert('./ajax_startlist.php?'+param);
	$.ajax({ type: "GET", url: "./ajax_startlist.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.startlist == 'object')
					{
						ShowStartlist(jsonData.startlist);
						theTv.start_starlist = jsonData.next;
					}
                }
    });

	theTv.timer_startlist = setTimeout("RefreshStartlist()", theTv.delay_startlist);
    return false;
}

function ShowStartlist(list)
{
	HideStartlistRows();

	if (typeof list[0].Tick == 'string')
	{
		theTv.tick_list = list[0].Tick;
		for (var i=0;i<list.length;i++)
		{
			SetStartlistRow(i+1, list[i]);
		}
	}
}

function HideStartlistRow(row)
{
	$('#block_start_list .row'+row).hide();
}

function HideStartlistRows()
{
	for (var i=1;i<=14;i++)
		HideStartlistRow(i);
}

function ShowStartlistRow(row)
{
	$('#block_start_list .row'+row).show();
/*	
	animateCSS('#block_start_list .row'+row+' .bib', 'bounceInLeft');
	animateCSS('#block_start_list .row'+row+' .identity', 'bounceInRight');
	animateCSS('#block_start_list .row'+row+' .team', 'bounceInLeft');
*/
}

function SetStartlistRow(row, rlist)
{
	if (typeof rlist.Bib == 'string')
		$('#block_start_list .row'+row+' .bib').html(rlist.Bib);

	if (typeof rlist.Identity == 'string')
		$('#block_start_list .row'+row+' .identity').html(rlist.Identity);

	if (typeof rlist.Team == 'string')
		$('#block_start_list .row'+row+' .team').html(rlist.Team);

	if (typeof rlist.Categ == 'string')
		$('#block_start_list .row'+row+' .categ').html(rlist.Categ);

	if (typeof rlist.Sex == 'string')
		$('#block_start_list .row'+row+' .sex').html(rlist.Sex);

	if (typeof rlist.Distance == 'string')
		$('#block_start_list .row'+row+' .distance').html(rlist.Distance);

	ShowStartlistRow(row);
}

function RefreshClockRunning()
{
	var param;
	param = 'epreuve='+theTv.epreuve;

	$.ajax({ type: "GET", url: "./ajax_clock_running.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.clock == 'object')
					{
						ShowClockRunning(jsonData.clock);
					}
                }
    });

	theTv.timer_running = setTimeout("RefreshClockRunning()", 999);
    return false;
}

function ShowClockRunning(clock)
{
	if (typeof clock.now == 'string')
		$('#block_clock_running .hour').html(clock.now);
	
	if (typeof clock.time == 'string')
		$('#block_clock_running .time').html(clock.time);
}

function RefreshRanking()
{
	var param;
	param  = 'start='+theTv.start_ranking+'&count='+theTv.count_ranking;
	param += '&epreuve='+theTv.epreuve+'&categ='+theTv.categ+'&sex='+theTv.sex+'&distance='+theTv.distance;
	param += '&finish='+theTv.finish;
	
//	alert('./ajax_ranking.php?'+param);
	
	$.ajax({ type: "GET", url: "./ajax_ranking.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.ranking == 'object')
					{
						ShowRanking(jsonData.ranking);
						theTv.start_ranking_current = theTv.start_ranking;
						theTv.start_ranking = jsonData.next;
					}
                }
    });

	theTv.timer_ranking = setTimeout("RefreshRanking()", theTv.delay_ranking);
	return false;
}

function RefreshRankingAfterFinish()
{
	var param;
	param  = 'start='+theTv.start_ranking_current+'&count='+theTv.count_ranking;
	param += '&epreuve='+theTv.epreuve+'&categ='+theTv.categ+'&sex='+theTv.sex+'&distance='+theTv.distance;

	$.ajax({ type: "GET", url: "./ajax_ranking.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.ranking == 'object')
					{
						ShowRanking(jsonData.ranking);
					}
                }
    });
	return false;
}

function HideRow(row)
{
	if (theTv.mode == 'ranking')
		$('#block_ranking .row'+row).hide();
	else
		$('#block_ranking2 .row'+row).hide();
}

function ShowRow(row)
{
	if (theTv.mode == 'ranking')
		$('#block_ranking .row'+row).show();
	else
		$('#block_ranking2 .row'+row).show();
/*
	animateCSS('#block_ranking .row'+row+' .bib', 'bounceInLeft');
	animateCSS('#block_ranking .row'+row+' .identity', 'bounceInRight');
	animateCSS('#block_ranking .row'+row+' .team', 'bounceInLeft');
*/
}

function HideRows()
{
	/* nb de ligne pour le retour 2eme ligne a modifier*/
	for (var i=1;i<=20;i++)
		HideRow(i);
}

function ShowRanking(list)
{
	HideRows();
	if (list.length > 0)
	{
		if (typeof list[0].Tick == 'string')
		{
			theTv.tick_ranking = list[0].Tick;
			for (var i=0;i<list.length;i++)
			{
				SetRow(i+1, list[i]);
			}
		}
	}
}

function SetRow(row, rlist)
{
	if (theTv.mode == 'ranking')
	{
		if (typeof rlist.Bib == 'string')
			$('#block_ranking .row'+row+' .bib').html(rlist.Bib);
		else
			$('#block_ranking .row'+row+' .bib').html('');

		if (typeof rlist.Identity == 'string')
			$('#block_ranking .row'+row+' .identity').html(rlist.Identity);
		else
			$('#block_ranking .row'+row+' .identity').html('');

		if (typeof rlist.Team == 'string')
			$('#block_ranking .row'+row+' .team').html(rlist.Team);
		else
			$('#block_ranking .row'+row+' .team').html('');

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
		
		if (typeof rlist.Categ == 'string')
			$('#block_ranking .row'+row+' .categ').html(rlist.Categ);
		else
			$('#block_ranking .row'+row+' .categ').html('');

		if (typeof rlist.Sex == 'string')
			$('#block_ranking .row'+row+' .sex').html(rlist.Sex);
		else
			$('#block_ranking .row'+row+' .sex').html('');

		if (typeof rlist.Distance == 'string')
			$('#block_ranking .row'+row+' .distance').html(rlist.Distance);
		else
			$('#block_ranking .row'+row+' .distance').html('');
	}
	else
	{
		if (typeof rlist.Bib == 'string')
			$('#block_ranking2 .row'+row+' .bib').html(rlist.Bib);
		else
			$('#block_ranking2 .row'+row+' .bib').html('');

		if (typeof rlist.Identity == 'string')
			$('#block_ranking2 .row'+row+' .identity').html(rlist.Identity);
		else
			$('#block_ranking2 .row'+row+' .identity').html('');

		if (typeof rlist.Team == 'string')
			$('#block_ranking2 .row'+row+' .team').html(rlist.Team);
		else
			$('#block_ranking2 .row'+row+' .team').html('');

		if (typeof rlist.Rank1 == 'string')
			$('#block_ranking2 .row'+row+' .rank1').html(rlist.Rank1);
		else
			$('#block_ranking2 .row'+row+' .rank1').html('');

		if (typeof rlist.Time1 == 'string')
			$('#block_ranking2 .row'+row+' .time1').html(rlist.Time1);
		else
			$('#block_ranking2 .row'+row+' .time1').html('');

		if (typeof rlist.Rank2 == 'string')
			$('#block_ranking2 .row'+row+' .rank2').html(rlist.Rank2);
		else
			$('#block_ranking2 .row'+row+' .rank2').html('');

		if (typeof rlist.Time2 == 'string')
			$('#block_ranking2 .row'+row+' .time2').html(rlist.Time2);
		else
			$('#block_ranking2 .row'+row+' .time2').html('');

		if (typeof rlist.Rank == 'string')
			$('#block_ranking2 .row'+row+' .rank').html(rlist.Rank);
		else
			$('#block_ranking2 .row'+row+' .rank').html('');

		if (typeof rlist.Time2 == 'string')
			$('#block_ranking2 .row'+row+' .time').html(rlist.Time);
		else
			$('#block_ranking2 .row'+row+' .time').html('');
	}

	ShowRow(row);
}

function SetClickFullScreen()
{
	$("#head").click(function() {
		if (theTv.full_screen)
		{
			closeFullscreen();
			theTv.full_screen = false;
		}
		else
		{
			openFullscreen();
			theTv.full_screen = true;
		}
		return false;
	});
}

function Init(id, epreuve, categ, sex, distance, finish, title)
{
	theTv.id = id;
	theTv.title = title;

	theTv.epreuve = epreuve;
	
	theTv.categ = categ;
	theTv.sex = sex;
	theTv.distance = distance;
	theTv.finish = finish;
	
	RefreshContext();
}
