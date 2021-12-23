var theArrayContext = [];

function _addContext(context)
{
	var i;
	for (i=0;i<theArrayContext.length;i++)
	{
		if (theArrayContext[i] == context)
			return false;
	}
	
	theArrayContext.push(context);
	$('#'+context).fadeIn(500);
}

function _removeContext(context)
{
	for (i=0;i<theArrayContext.length;i++)
	{
		if (theArrayContext[i] == context)
		{
			theArrayContext.splice(i, 1);
			$('#'+context).fadeOut(1000);
			return true;
		}
	}
	
	$('#'+context).fadeOut(1000);
	return false;
}

function _removeAllContext()
{
	theArrayContext = [];
	$('.template').hide();
}

function play() 
{
	log('play()');
}
    
function stop() 
{
	log('stop()');
}
  
function next() 
{
	log('next()');
}

function update(data) 
{
	log('update()');
}
  
function log(s) 
{
/*	
	console.log(s);
	const li = document.createElement('li');
	li.innerText = s;
	document.body.querySelector('ul').appendChild(li);
*/
}

function refresh()
{
	if (arguments.length == 2)
	{
		if (arguments[0] == 'time')
		{
			$('.time_running').html(arguments[1]);
			return;
		}
	}

	log('refresh() ' + JSON.stringify(arguments));
}

function SetRacer()
{
	if (arguments.length >= 4)
	{
		if (arguments[0] == 'bib')
		{
			$('.bib').html(arguments[1]);
		}

		if (arguments[2] == 'identity')
		{
			$('.identity').html(arguments[3]);
		}
		
		if (arguments[4] == 'nation')
		{
			var nation = arguments[5];
			$('.nation').html(nation);
			$('.img_nation').attr("src", './img/flags/'+nation+'.png');
		}
	}

//	log('SetRacer() ' + JSON.stringify(arguments));
}

function SetInter()
{
	_addContext('block_racer');
	_addContext('block_inter');
	_removeContext('block_best');
	
	if (arguments.length >= 6)
	{
		if (arguments[0] == 'time')
		{
			$('.running_time').html(arguments[1]);
		}
		
		if (arguments[4] == 'diff')
		{
			var diff = arguments[5];
			if (diff.length == 0)
			{
				$('.diff').hide();
			}
			else
			{
				$('.diff').html(diff);
				$('.diff').show();
				
				if (diff.substring(0,1) == '+')
				{
					$(".diff").removeClass('green');
					$(".diff").addClass('red');
				}
				else
				{
					$('.diff').removeClass("red");
					$('.diff').addClass("green");
				}
			}
		}
	}
}

function SetFinished()
{
	_addContext('block_racer');
	_addContext('block_finish');
	_removeContext('block_best');
	
	if (arguments.length >= 6)
	{
		if (arguments[0] == 'time')
		{
			$('.running_time').html(arguments[1]);
		}
		
		if (arguments[2] == 'rank')
		{
			var rank = arguments[3];
			$('.rank').html(rank);
		}
		
		if (arguments[4] == 'diff')
		{
			var diff = arguments[5];
			$('.diff').html(diff);

			if (diff.length == 0)
			{
				$(".diff").removeClass('green');
				$(".diff").addClass('red');
			}
			else
			{
				if (diff.substring(0,1) == '+')
				{
					$(".diff").removeClass('green');
					$(".diff").addClass('red');
				}
				else
				{
					$(".diff").removeClass('red');
					$(".diff").addClass('green');
				}
			}
			$('.diff').show();
		}
	}
}

function SetBestIdentity()
{
	if (arguments.length >= 2)
	{
		if (arguments[0] == 'identity')
		{
			$('.best_identity').html(arguments[1]);
			$('.best_identity').show();
			return;
		}
	}

	$('.best_identity').hide();
}

function SetBestTime()
{
	if (arguments.length >= 2)
	{
		if (arguments[0] == 'time')
		{
			$('.best_time').html(arguments[1]);
			$('.best_time').show();
			return;
		}
	}

	$('.best_time').hide();
}

function SetRunningTime()
{
	if (arguments.length >= 1)
	{
		$('.running_time').html(arguments[0]);
	}
}

function SetRunningPenalty()
{
	if (arguments.length >= 1)
	{
		$('.running_penalty').html(arguments[0]);
	}
}

function AddContext()
{
	var i;
	for (i=0;i<arguments.length;i++)
		_addContext(arguments[i]);
}

function RemoveContext()
{
	var i;
	for (i=0;i<arguments.length;i++)
		_removeContext(arguments[i]);
}

function RemoveAllContext()
{
	_removeAllContext();
}

function Init()
{
	// _addContext('bloc_racer');
	// _removeContext('bloc_racer');
}
