<?php
include_once('base.php');

$arrayParams = &$_GET;
$id = utyGetString($arrayParams, 'id');

$db = new MyBase();

$rTick = null;
$db->LoadRecord("Select Tick from Ping Where ID ='$id'", $rTick); 
$tick = utyGetInt($rTick, 'Tick', 0);

$tickNow = round(microtime(true) * 1000) % 86400000;

if ($tickNow > $tick)
	echo json_encode(array('tick' => $tickNow-$tick));
else
	echo json_encode(array('tick' => -1));
?>

