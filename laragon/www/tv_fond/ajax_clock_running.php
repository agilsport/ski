<?php
include_once('base.php');

$arrayParams = &$_GET;
$epreuve = utyGetInt($arrayParams, 'epreuve', -1);

$db = new MyBase();

$rEpreuve = null;

$cmd = "Select * from Epreuve ";
if ($epreuve >= 1)
	$cmd .= "Where Code = $epreuve";

$db->LoadRecord($cmd, $rEpreuve); 
	
if (utyGetInt($rEpreuve, 'Code', 0) >= 1)
{
	$clock_start = utyGetInt($rEpreuve, 'Start', 0);
	$clock_now = (round(microtime(true) * 1000 + 3600 * 2000) % 86400000)-3600000;
		
	if ($clock_now >= $clock_start)
		$clock_time = $clock_now - $clock_start;
	else
		$clock_time = 0;
	
	$start = Mybase::chronoHHMMSS($clock_start);
	$now = 'Heure : '.Mybase::chronoHHMMSS($clock_now);
	$time = 'Tps Epreuve : '.Mybase::chronoHMMSS($clock_time);

	echo json_encode(array('clock' => array(
		'istart' => $clock_start, 
		'inow' => $clock_now, 
		'itime' => $clock_time,
		'start' => $start,
		'now' => $now,
		'time' => $time
	)));
	return;
}

echo json_encode(array('error' => 'Epreuve Null'));
?>

