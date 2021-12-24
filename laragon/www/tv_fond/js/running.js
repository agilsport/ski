var theTv = {
	tick_running : '',
	resfreshContext : false
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
		if (context.Best_identity.length > 0)
		{
			$('#block_running .best_identity').html(context.Best_identity);
			$('#block_running .best_time').html(context.Best_time);
		}
		else
		{
			$('#block_running .best_identity').html('');
			$('#block_running .best_time').html('');
		}
	}
}

function ShowBest()
{
	$('#block_running .best_identity').show();
	$('#block_running .best_time').show();
}

function HideBest()
{
	$('#block_running .best_identity').hide();
	$('#block_running .best_time').hide();
}

function RefreshRunning()
{
	$.ajax({ type: "GET", url: "./ajax_running.php", dataType: "json", cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.running == 'object')
					{
						ShowRunning(jsonData.running);
					}
                }
    });

	setTimeout("RefreshRunning()", 99);
    return false;
}

function ShowRunning(running)
{
	if (typeof running.State == 'string')
	{
		if (running.State == 'C')
		{
			$('#block_running').hide();
		}
		else
		{
			$('#block_running').show();

			$('#block_running .bib').html(running.Bib);
			$('#block_running .identity').html(running.Identity);
			$('#block_running .team').html(running.Team);
			$('#block_running .time').html(running.Time);

			if (running.State == 'F')
			{
				if (theTv.tick_running != running.Tick)
				{
					theTv.tick_running = running.Tick;

					// Rank
					if (typeof running.Rank == 'string' && running.Rank.length > 0 && running.Rank != '0')
					{
						$('#block_running .rank').html(running.Rank);
						$('#block_running .rank').show();
					}
					else
					{
						$('#block_running .rank').html('');
						$('#block_running .rank').hide();
					}

					// Diff
					if (typeof running.Diff == 'string' && running.Diff.length > 0)
					{
						var diff = '';
						if (typeof running.Diff == 'string')
							diff = running.Diff;

						if (diff.substring(0,1) == '+')
						{
							$("#block_running .diff").removeClass('green');
							$("#block_running .diff").addClass('red');
						}
						else
						{
							$("#block_running .diff").removeClass('red');
							$("#block_running .diff").addClass('green');
						}
						
						$('#block_running .diff').html(diff);
						$('#block_running .diff').show();
					}
					else
					{
						$('#block_running .diff').html('');
						$('#block_running .diff').hide();
					}

					$('#block_running .best_identity').hide();
					$('#block_running .best_time').hide();

					HideBest();
					theTv.resfreshContext = true;
				}
			}
			else
			{
				$('#block_running .diff').hide();
				$('#block_running .rank').hide();

				if (theTv.resfreshContext)
				{
					RefreshContext();
					theTv.resfreshContext = false;
				}
				ShowBest();
			}
		}
	}
}

function Refresh()
{
	RefreshContext();
	RefreshRunning();
}

function Init()
{
	Refresh();
}
