<?php
include_once('base.php');

$arrayParams = &$_GET;
$start = utyGetInt($arrayParams, 'start', 1);
// nombre de ligne a afficher 1 seule a modif ds le fichier
$count = utyGetInt($arrayParams, 'count', 20);

$epreuve = utyGetInt($arrayParams, 'epreuve', -1);

$categ = utyGetString($arrayParams, 'categ');
$sex = utyGetString($arrayParams, 'sex');
$distance = utyGetString($arrayParams, 'distance');

$finish = utyGetString($arrayParams, 'finish');

$db = new MyBase();

$cmd = "Select count(*) nb from Ranking Where ID Is Not null";

if ($epreuve != -1 )
	$cmd .= " And Epreuve = $epreuve ";

if ($categ != '' )
	$cmd .= " And Categ = '$categ'";
if ($sex != '' )
	$cmd .= " And Sex = '$sex'";
if ($distance != '' )
	$cmd .= " And Distance = '$distance'";

$rCount = null;
$db->LoadRecord($cmd, $rCount); 
$max = utyGetInt($rCount, 'nb', 0);

if ($start > $max)
	$start = 1;

$end = $start + $count;
$start = $start-1;

$cmd  = "Select * from Ranking Where ID Is Not null";

if ($epreuve != -1 )
	$cmd .= " And Epreuve = $epreuve ";

if ($categ != '' )
	$cmd .= " And Categ = '$categ'";
if ($sex != '' )
	$cmd .= " And Sex = '$sex'";
if ($distance != '' )
	$cmd .= " And Distance = '$distance'";

if ($finish == '1')
	$cmd .= " Order By Finish Desc LIMIT $start, $count";
else
	$cmd .= " Order By ID LIMIT $start, $count";
	
$tRanking = null;
$db->LoadTable($cmd, $tRanking); 

if ($end >= $max)
	$end = 1;

echo json_encode(array('ranking' => $tRanking, 'next' => $end));
?>

