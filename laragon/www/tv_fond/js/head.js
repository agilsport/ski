function animateCSS(element, animationName, callback) 
{
    const node = document.querySelector(element)
    node.classList.add('animated', animationName)

    function handleAnimationEnd() {
        node.classList.remove('animated', animationName)
        node.removeEventListener('animationend', handleAnimationEnd)

        if (typeof callback === 'function') callback()
    }

    node.addEventListener('animationend', handleAnimationEnd)
}

function animateHead()
{
/*	
	animateCSS('#head_logo_left', 'bounceInRight');
	animateCSS('#head_logo_right', 'bounceInLeft');
	animateCSS('#head_title_top', 'bounceInLeft');
	animateCSS('#head_title_bottom', 'bounceInRight');
*/	
}

function SetTitle(info)
{
	$('#title').html(info);
}

function SetMode(info)
{
	$('#mode').html(info);
}
