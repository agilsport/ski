<?php
include_once('base.php');

$db = new MyBase();

$rNext = null;
$db->LoadRecord('Select * from Next Where ID = 1', $rNext); 
echo json_encode(array('next' => $rNext));
?>

