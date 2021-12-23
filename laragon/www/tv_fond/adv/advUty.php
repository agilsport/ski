<?php

// utySize
function utySize($taille) 
{
    $taille = (int) $taille;
    if ($taille < 1024)
    {
        $taille .= 'o';
        return $taille;		
    }

    $taille /= 1024;
    $taille = (int) $taille;

    if ($taille < 1024)
        $taille .= 'Ko';
    else
    {
        $taille = (int) ($taille/1024);
        $taille .= 'Mo';
    }

    return $taille;		
}

// utyIsMailOk
function utyIsMailOk($email) 
{
    if (filter_var($email, FILTER_VALIDATE_EMAIL))
        return true;
    else
		return false;
}

// Transformation Date Us : YYYY-MM-DD en Date Fr Long : dddd DD mmmm YYYY
function utyDateUsToFrLong($dateUs, $separator = "-")
{
    $tab_dmy = explode($separator, $dateUs);
    $prefix = "";
    $tab_month = array(0, "janvier", "fevrier", "mars", "avril", "mai", "juin", "juillet", "aout", "septembre", "octobre", "novembre", "decembre");
    $tab_day = array("dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi");
    settype($tab_dmy[1], integer);
    $day = date("w", mktime(0, 0, 0, $tab_dmy[1], $tab_dmy[2], $tab_dmy[0]));
    $ladate .= $prefix . $tab_day[$day] . " " . $tab_dmy[2] . " ";
    $ladate .= $tab_month[$tab_dmy[1]] . " " . $tab_dmy[0] . " ";

    return $ladate; // Error ...
}

// Transformation Date Us : YYYY-MM-DD en Date Fr : DD/MM/YYYY
function utyDateUsToFr($dateUs, $separaror = '-', $bHour = false, $bMinute = false, $bSecond = false)
{
    $hms = '';
    if (strlen($dateUs) > 10) 
    {
		$time = substr($dateUs,10);
        $dateUs = substr($dateUs,0,10);
		
		if ($bHour)
			$hms .= ' '.substr($time,1, 2);
		
		if ($bMinute)
            $hms .= 'h'.substr($time,4, 2);

		if ($bSecond)
            $hms .= '.'.substr($time,7, 2);
    }

    $data = explode($separaror,$dateUs);
    if (count($data) == 3)
        return $data[2].'/'.$data[1].'/'.$data[0].$hms;

    return $dateUs; // Error ...
}

// Transformation Date Fr : DD/MM/YYYY en Date Us : YYYY-MM-DD
function utyDateFrToUs($dateFr, $separaror = '/')
{
    $data = explode($separaror,$dateFr);
    if (count($data) == 3)
        return $data[2].'-'.$data[1].'-'.$data[0];

    return $dateFr; // Error ...
}

// utyYearOfDate 
function utyYearOfDate($dateUs)
{
    $data = explode('-',$dateUs);
    if (count($data) == 3)
        return (int) $data[0];

    return 0;	// Error
}

// utyDateCmpFr 
function utyDateCmpFr($date1, $date2)
{
    $data1 = explode('/',$date1);
    $data2 = explode('/',$date2);

    // Comparaison Annee
    if ( (int) $data1[3] != (int) $data2[3] )
        return (int) $data1[3] - (int) $data2[3];

    // Comparaison Mois
    if ( (int) $data1[2] != (int) $data2[2] )
        return (int) $data1[2] - (int) $data2[2];

    // Comparaison Jour
    return (int) $data1[0] - (int) $data2[0];
}

function utyDateMonth3C($month)
{
	switch((int)$month)
	{
		case 1:
		return 'JAN';

		case 2:
		return 'FEV';

		case 3:
		return 'MAR';
		
		case 4:
		return 'AVR';

		case 5:
		return 'MAI';

		case 6:
		return 'JUN';

		case 7:
		return 'JUL';

		case 8:
		return 'AOU';

		case 9:
		return 'SEP';

		case 10:
		return 'OCT';

		case 11:
		return 'NOV';

		case 12:
		return 'DEC';
		
		default:
		break;
	}
	return $month;
}

// utyTimeInterval
function utyTimeInterval($time, $interval)
{
    $data = explode(':',$time);
    if (count($data) == 2)
    {
        $hour = (int) $data[0];
        $minute = (int) $data[1];

        $minute += (int) $interval;

        $hour += (int) ($minute/60);
        $minute %= 60;

        return sprintf("%02d:%02d", $hour, $minute);
    }

    return $time;
}

// utyGetSession
function utyGetSession($param, $default = '')
{
	return utyGetString($_SESSION, $param, $default);
}

function utyGetSessionInt($key, $default = -1)
{
	return utyGetInt($_SESSION, $key, $default);
}

function utyGetSessionArray($key)
{
	if (isset($_SESSION[$key]))
		return $_SESSION[$key];
	else
		return array();
}

// utyGetArraySession
function utyGetArraySession($array, $field, $default = '')
{
    if (isset($_SESSION[$array]))
        if (isset($_SESSION[$array][$field]))
            return $_SESSION[$array][$field];

    return $default;
}

// utySetSession
function utySetSession($param, $value)
{
    $_SESSION[$param] = $value;
}

// utyRemoveSession
function utyRemoveSession($param)
{
    if (isset($_SESSION[$param]))
        unset($_SESSION[$param]);
} 

function utyGetString(&$arrayParams, $key, $default = '')
{
    if (isset($arrayParams[$key]))
        return $arrayParams[$key];
    return $default;
}

function utyGetArray(&$arrayParams, $key)
{
    if (isset($arrayParams[$key]))
        return $arrayParams[$key];
    return array();
}

function utyGetBool(&$arrayParams, $key, $default = false)
{
    if (isset($arrayParams[$key]))
    {
        if ((int) $arrayParams[$key] == 0) 
			return false;
        else 
			return true;
    }

    return $default;
}

function utyGetInt(&$arrayParams, $key, $default = -1)
{
    if (isset($arrayParams[$key]))
        return intval($arrayParams[$key]);
	else
		return $default;
}	
	
function utyGetDouble(&$arrayParams, $key, $default = 0.0)
{
    if (isset($arrayParams[$key]))
        return (double) $arrayParams[$key];
	else
		return $default;
}

function utyGetPoint(&$arrayParams, $key, $default='')
{
	if (isset($arrayParams[$key]))
		return sprintf('%-.2lf', (double) $arrayParams[$key]);
	else
		return $default;
}

// utyGetCookie
function utyGetCookie($param, $default = '')
{
    if (isset($_COOKIE[$param]))
        return $_COOKIE[$param];
	
    return $default;
}

// utySetCookie
function utySetCookie($param, $value, $time = '')
{
    if ($time == '')
        setcookie($param, $value, time()+30*24*3600);
    else
        setcookie($param, $value, $time);
}

// utyRemoveCookie
function utyRemoveCookie($param)
{
    setcookie($param);
} 

// utyPostToSession
function utyPostToSession($param)
{
    $_SESSION[$param] = $_POST;
}

// utyGetToSession
function utyGetToSession($param)
{
    $_SESSION[$param] = $_GET;
}

// utyStringQuote
function utyStringQuote($string)
{
/*
	if (get_magic_quotes_gpc())
		$string = stripslashes($string);
*/
//	return mysql_real_escape_string($string);

/*	
    $newstring = "";
    for ($i=0;$i<strlen($string);$i++)
    {
        $newstring .= $string[$i];
        if ($string[$i] == '\'')
			$newstring .= '\'';
    }
	
//	return $newstring;
*/
	return str_replace("\''", "''", $newstring);	// A AMELIORER ...
}

// utyDateFrLong
function utyDateFrLong($time, $fmt='Y')
{
    $NomDuJour = array ("Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi");
    $NomDuMois = array ("Janvier", "F&eacute;vrier", "Mars", "Avril", "Mai", "Juin", "Juillet", "Ao&ucirc;t", "Septembre", "Octobre", "Novembre", "D&eacute;cembre");

    $lejour = date("d",$time);
    $lemois = date("m",$time);

    $ladatefr = $NomDuJour[ date('w',$time) ]." ";

    if ($lejour == '01') {$ladatefr.=" 1er "; }
    else if($lejour<10) { $ladatefr.=" $lejour[1] "; }
    else { $ladatefr.= date (" d ",$time); }

    $ladatefr .= $NomDuMois[$lemois-1]." ".date($fmt,$time);

    return $ladatefr;
}

// utyDateFrShort
function utyDateFrShort($time)
{
    $NomDuJour = array ("Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam");
    $NomDuMois = array ("Jan", "F&eacute;v", "Mar", "Avr", "Mai", "Juin", "Juil", "Ao&ucirc;t", "Sept", "Oct", "Nov", "D&eacute;c");

    return $NomDuJour[ date('w',$time) ]." ".date('d',$time)." ".$NomDuMois[date("m",$time)-1];
}

// utySaturdayTime
function utySaturdayTime($time)
{
    $day = date('w',$time);
    if ($day < 6)
        $time = mktime(0, 0, 0, date("m",$time), date("d",$time)-$day-1, date("Y",$time));

    return $time;
}

// utyAddDays
function utyAddDays($time, $nbdays)
{
    return mktime(0, 0, 0, date("m",$time), date("d",$time)+$nbdays, date("Y",$time));
}

// utyCreatePassword
function utyCreatePassword($length) 
{
    $chars = "234567890abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    $max = strlen($chars)-1;

    $i = 0;
    $password = "";
    while ($i <= $length) 
    {
        $password .= $chars[mt_rand(0,$max)];
        $i++;
    }
    return $password;
}

function utyUpperStd($string, $bUtf8=true)
{
	if ($bUtf8)
		$txt = utf8_decode($string);
	else
		$txt = $string;
	
	$separator = array(' ', '-', '_', ',', '.', ':', '\'', '"', '&', '=');
	$txt = str_replace($separator, '', $txt);
	
	$letterA = array('à', 'â', 'ä', 'Ä', 'Â');
	$txt = str_replace($letterA, 'A', $txt);

	$letterC = array('ç', 'Ç');
	$txt = str_replace($letterC, 'C', $txt);

	$letterE = array('é', 'è', 'ê', 'ë', 'Ê', 'Ë');
	$txt = str_replace($letterE, 'E', $txt);

	$letterI = array('ï','î', 'Î', 'Ï');
	$txt = str_replace($letterI, 'I', $txt);
	
	$letterO = array('ô', 'ö', 'Ô', 'Ö');
	$txt = str_replace($letterO, 'O', $txt);

	$letterU = array('ù', 'ü', 'û', 'Ü', 'Û');
	$txt = str_replace($letterU, 'U', $txt);
	
	return strtoupper($txt);
}

function utyFilterUnique(&$table, $colname, &$arraycolumns, $bSort=true)
{
	$arraycolumns = array();

	$nb = count($table);
	for ($i=0;$i<$nb;$i++)
	{
		if (isset($table[$i][$colname]))
		{
			$value = trim($table[$i][$colname]);
			if ($value == '') continue;
			
			$bNew = true;
			for ($j=0;$j<count($arraycolumns);$j++)
			{
				if ($arraycolumns[$j] == $value)
				{
					$bNew = false;
					break;
				}
			}
			if ($bNew)
				array_push($arraycolumns, $value);
		}
	}
		
	if ($bSort)
		sort($arraycolumns);
}

function utyListToInSql($lst)
{
	return "'".str_replace(",", "','", $lst)."'";
}

function utyArrayToInSql(&$array)
{
	$count = count($array);
	$lst = '';
	for ($i=0;$i<$count;$i++)
	{
		if ($i > 0) $lst .= ',';
		$lst .= "'".$array[$i]."'";
	}
	return $lst;
}

function utyEchoSelected(&$arrayParams, $key, $value)
{
	if ($value == utyGetString($arrayParams, $key)) 
		echo ' selected ';
}

function utyEchoMultiSelected(&$arrayParams, $key, $value)
{
	if (!isset($arrayParams[$key]))
		return;

	$count = count($arrayParams[$key]);
	for ($i=0;$i<$count;$i++)
	{
		if ($value == $arrayParams[$key][$i]) 
		{
			echo ' selected ';
			return;
		}
	}
}

function utyEchoChecked(&$arrayParams, $key)
{
	if (utyGetString($arrayParams, $key, '(null)') != '(null)')
		echo ' checked ';
}

function utyGetStringArray(&$arrayParams, $key, $default = '')
{
	if (isset($arrayParams[$key]))
	{
		$count = count($arrayParams[$key]);
		$lst = '';
		for ($i=0;$i<$count;$i++)
		{
			if ($i > 0) $lst .= ',';
			$lst .= "'".$arrayParams[$key][$i]."'";
		}
		return $lst;
	}
	return $default;
}

function utyArrayRemoveRow(&$array, $row)
{
	for ($i = $row; $i < count($array)-1; $i++)  
	{ 
		$array[$i] = $array[$i + 1]; 
	} 
	
	unset($array[count($array) - 1]);
}

?>
