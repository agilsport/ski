<?php
include_once('base.php');

$arrayParams = &$_GET;
$start = utyGetInt($arrayParams, 'start', 1);
$count = utyGetInt($arrayParams, 'count', 14);

$epreuve = utyGetInt($arrayParams, 'epreuve', -1);

$categ = utyGetString($arrayParams, 'categ');
$sex = utyGetString($arrayParams, 'sex');
$distance = utyGetString($arrayParams, 'distance');

$db = new MyBase();

$rCount = null;

$cmd = "Select count(*) nb from Startlist Where ID Is Not null";

if ($epreuve != -1 )
	$cmd .= " And Epreuve = $epreuve ";

if ($categ != '' )
	$cmd .= " And Categ = '$categ'";
if ($sex != '' )
	$cmd .= " And Sex = '$sex'";
if ($distance != '' )
	$cmd .= " And Distance = '$distance'";

$db->LoadRecord($cmd, $rCount); 
$max = utyGetInt($rCount, 'nb', 0);

if ($start > $max)
	$start = 1;

$end = $start + $count;
$start = $start-1;

$cmd  = "Select * from Startlist Where ID Is Not null";

if ($epreuve != -1 )
	$cmd .= " And Epreuve = $epreuve ";

if ($categ != '' )
	$cmd .= " And Categ = '$categ'";
if ($sex != '' )
	$cmd .= " And Sex = '$sex'";
if ($distance != '' )
	$cmd .= " And Distance = '$distance'";

$cmd .= " Order By ID LIMIT $start, $count";
$tStartlist = null;
$db->LoadTable($cmd, $tStartlist); 

if ($end >= $max)
	$end = 1;

echo json_encode(array('startlist' => $tStartlist, 'next' => $end));
?>

