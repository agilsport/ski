var theTv = {
	full_screen : false,
	mode : '',

	tick_running : '',

	resfreshContext : false
};

function RefreshNext()
{
	$.ajax({ type: "GET", url: "./ajax_next.php", dataType: "json", cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object' && typeof jsonData.next == 'object')
					{
						ShowNext(jsonData.next);
					}
                }
    });

	setTimeout("RefreshNext()", 4000);
    return false;
}

function ShowNext(next)
{
	if (typeof next.State == 'string')
	{
		if (next.State == 'C')
		{
			$('#block_running').hide();
		}
		else
		{
			$('#block_running').show();

			$('#block_running .bib').html(next.Bib);
			$('#block_running .identity').html(next.Identity);
			$('#block_running .team').html(next.Team);
		}
	}
}

function Init()
{
	RefreshNext();
}
