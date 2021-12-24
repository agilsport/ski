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

function SetTitle()
{
	if (arguments.length >= 1)
		$('#discipline').html(arguments[0]);
}
  
function SetRow()
{
	if (arguments.length >= 5)
	{
		var row = arguments[0];
		var rank = arguments[1];
		var bib = arguments[2];
		var identity = arguments[3];
		var nation = arguments[4];
		
		if (bib.length == 0)
			$('.row'+row).hide();
		else
			$('.row'+row).show();
		
		$('.row'+row+' .rank').html(rank); 
		$('.row'+row+' .bib').html(bib); 
		$('.row'+row+' .identity').html(identity); 
		$('.row'+row+' .nation').html(nation); 

		if (nation.length > 0)
			$('.row'+row+' .img_nation').attr("src", './img/flags/'+nation+'.png');
		else
			$('.row'+row+' .img_nation').attr("src", './img/flags/empty.png');
		
		animateRow(row);
	}
}	

function animateRow(row)
{
	animateCSS('.row'+row+' .identity', 'bounceInRight');
	animateCSS('.row'+row+' .bib', 'bounceInLeft');
}

function log(s) 
{
/*	
	console.log(s)
	const li = document.createElement('li');
	li.innerText = s;
	document.body.querySelector('ul').appendChild(li);
*/
}

function refresh()
{
	log('refresh() ' + JSON.stringify(arguments));
}

function Init()
{
}
