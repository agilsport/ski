var theTv = {
	id : '',
	delay : 2000,
};

function Refresh()
{
	var param = 'id='+theTv.id;
	$.ajax({ type: "GET", url: "./ajax_monitor.php", dataType: "json", data: param, cache: false,
				success: function(jsonData) 
                { 
					if (typeof jsonData == 'object')
					{
						var tick = parseInt(jsonData.tick);
						$('#monitor_state').html(tick);
						if ((tick >= 0) && (tick < 4000))
						{
							$("#monitor_state").removeClass('ko');
							$("#monitor_state").addClass('ok');
						}
						else
						{
							$("#monitor_state").removeClass('ok');
							$("#monitor_state").addClass('ko');
						}
					}
                }
    });

	setTimeout("Refresh()", theTv.delay);
	return false;
}

function Init(id)
{
	theTv.id = id;
	Refresh();
}
