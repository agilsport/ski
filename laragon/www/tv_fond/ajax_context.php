<?php
include_once('base.php');

$db = new MyBase();

$id = utyGetString($_GET, 'id');

$rContext = null;
$db->LoadRecord('Select * from Context Where ID = 1', $rContext); 

if ($id != '')
{
	$milliseconds = round(microtime(true) * 1000) % 86400000;
	$cmd = "Replace Ping Values ('$id', $milliseconds)";
	$db->Query($cmd);
}

echo json_encode(array('context' => $rContext));
?>

