/*!
 * chrono version 1.0
 */
const CHRONO_OK = 1;
const CHRONO_KO = -1;
const CHRONO_DNS = -600;
const CHRONO_DNF = -500;
const CHRONO_DSQ = -800;

var chronoConfig = {
	column_chrono : 'Tps'
};

function chronoHandicap(handicap)
{
	if (handicap == null)
		return '';

	if (handicap.length == 0)
		return '';
	else
		return parseFloat(Math.round(parseFloat(handicap) * 100) / 100).toFixed(2);
}

function chronoHHMMSSCC(chrono)
{
	if (chrono == null)
		return '';
	
	chrono = parseInt(chrono, 10);
	if (chrono < CHRONO_OK)
	{
		if (chrono == CHRONO_DNS) return "Abs";
		else if (chrono == CHRONO_DNF) return "Abd";
		else if (chrono == CHRONO_DSQ) return "Dsq";
		else return "-";
	}
	
	var h = Math.floor(chrono/3600000);
	var m = Math.floor((chrono - h*3600000)/60000);
	var s = Math.floor((chrono - h*3600000 - m*60000)/1000);
	var c = Math.floor((chrono - h*3600000 - m*60000 - s*1000)/10);

	if (h > 0)
		return h.toString() + 'h' + ("0" + m).slice(-2) + ':' + ("0" + s).slice(-2) + '.' + ("0" + c).slice(-2);
	else if (m > 0)
		return m.toString() + ':' + ("0" + s).slice(-2) + '.' + ("0" + c).slice(-2);
	else 
		return s.toString() + '.' + ("0" + c).slice(-2);
}

function chronoHHMMSSMMM(chrono)
{
	chrono = parseInt(chrono, 10);
	if (chrono < CHRONO_OK)
	{
		if (chrono == CHRONO_DNS) return "Abs";
		else if (chrono == CHRONO_DNF) return "Abd";
		else if (chrono == CHRONO_DSQ) return "Dsq";
		else return "-";
	}
	
	var h = Math.floor(chrono/3600000);
	var m = Math.floor((chrono - h*3600000)/60000);
	var s = Math.floor((chrono - h*3600000 - m*60000)/1000);
	var f = chrono - h*3600000 - m*60000 - s*1000;

	if (h > 0)
		return h.toString() + 'h' + ("0" + m).slice(-2) + ':' + ("0" + s).slice(-2) + '.' + ("00" + f).slice(-3);
	else if (m > 0)
		return m.toString() + ':' + ("0" + s).slice(-2) + '.' + ("00" + f).slice(-3);
	else 
		return s.toString() + '.' + ("00" + f).slice(-3);
}

function chronoDiffMMSSCC(diff)
{
	if (typeof(diff) == 'string')
	{
		if ((diff.length == 0) || (isNaN(diff))) return diff;
		if (diff.substring(0, 1) == '+' || diff.substring(0, 1) == '-')
			return diff;
	}
	
	diff = parseInt(diff, 10);
	if (diff == 0)
		return '';
		
	var signDiff = '';
	if (diff > 0)
	{
		signDiff = '+';
	}
	else
	{
		signDiff = '-';
		diff = Math.abs(diff);
	}

	var m = Math.floor(diff/60000);
	var s = Math.floor((diff - m*60000)/1000);
	var c = Math.floor((diff - m*60000 - s*1000)/10);
	
	if (m > 0)
		return signDiff + m.toString() + ':' + ("0" + s).slice(-2)+ '.' + ("0" + c).slice(-2);
	else
		return signDiff + s.toString() + '.' + ("0" + c).slice(-2);
}

function chronoDiffMMSSD(diff)
{
	if (typeof(diff) == 'string')
	{
		if ((diff.length == 0) || (isNaN(diff))) return diff;
		if (diff.substring(0, 1) == '+' || diff.substring(0, 1) == '-')
			return diff;
	}

	diff = parseInt(diff, 10);
	if (diff == 0)
		return '';
		
	var signDiff = '';
	if (diff > 0)
	{
		signDiff = '+';
	}
	else
	{
		signDiff = '-';
		diff = Math.abs(diff);
	}

	var m = Math.floor(diff/60000);
	var s = Math.floor((diff - m*60000)/1000);
	var d = Math.floor((diff - m*60000 - s*1000)/100);
	
	if (m > 0)
		return signDiff + m.toString() + ':' + ("0" + s).slice(-2)+ '.' + (d).slice(-1);
	else
		return signDiff + s.toString() + '.' + (d).slice(-1);
}

function chronoCmp(a, b)
{
	var chronoA = parseInt(a[chronoConfig.column_chrono], 10);
	var chronoB = parseInt(b[chronoConfig.column_chrono], 10);
	
	if ((chronoA > 0) && (chronoB > 0))
	{
		if (chronoA != chronoB)
			return chronoA - chronoB;
		else
			return parseInt(a['Dossard'], 10) - parseInt(b['Dossard'], 10);
	}
	else
	{
		var orderA = chronoOrder(chronoA);
		var orderB = chronoOrder(chronoB);
		if (orderA != orderB)
			return orderA - orderB;
		else
			return parseInt(a['Dossard'], 10) - parseInt(b['Dossard'], 10);
	}
}

function chronoOrder(chrono)
{
	if (chrono > 0)
		return 1;
	else if (chrono == CHRONO_DSQ)
		return 2;
	else if (chrono == CHRONO_DNF)
		return 3;
	else if (chrono == CHRONO_DNS)
		return 4;
	else 
		return 5;
}

function chronoRanking(tRanking, colChrono, colRank, colDiff)
{
	if (tRanking.length == 0) return;
	
	chronoConfig.column_chrono = colChrono;
	tRanking.sort(chronoCmp);

	var chronoPrev = -1, chronoBest = -1, chrono;
	var rk = 0;
	for (var i=0;i<tRanking.length;i++)
	{
		chrono = parseInt(tRanking[i][colChrono], 10);
		if (chrono > 0) 
		{
			if (chronoPrev != chrono)
			{
				rk = i+1;
				chronoPrev = chrono;
			}
			tRanking[i][colRank] = rk.toString();
			
			if (i == 0)
			{
				chronoBest = chrono;
				tRanking[i][colDiff] = '';
			}
			else
			{
				tRanking[i][colDiff] = (chrono - chronoBest).toString();
			}	
		}
		else
		{
			tRanking[i][colRank] = '';
			tRanking[i][colDiff] = '';
		}
	}
}

function chronoTotal(tClassement, nbManche)
{
	var tps, tpsTotal;
	for (var i=0;i<tClassement.length;i++)
	{
		tpsTotal = 0;
		for (var m=1;m<=nbManche;m++)
		{
			tps = parseInt(tClassement[i]['Tps'+r.toString()], 10);
			if (tps <= 0)
			{
				tpsTotal = tps;
				break;
			}
			else
			{
				tpsTotal += tps;
			}
		}
		tClassement[i]['Tps'] = tpsTotal;
	}
}


