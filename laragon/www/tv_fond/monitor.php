<?php
	$id = 'aplus';
	if (isset($_GET['id']))
		$id = $_GET['id'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>Monitor TV</title>
	<link href="./js/bootstrap/css/bootstrap.min.css" rel="stylesheet">
	<link href="./css/animate.min.css" rel="stylesheet" />
	<link href="./css/monitor.css?v1" rel="stylesheet">
</head>
<body> 
	<div id='monitor_id'><?php echo $id;?></div>
	<div id='monitor_state' class='ok'>OK</div>

	<script type="text/javascript" src="./js/jquery-1.11.2.min.js"></script>
	<script type="text/javascript" src="./js/bootstrap.min.js"></script>
	<script type="text/javascript" src="./js/monitor.js?v1"></script>
	<script type="text/javascript"> $(document).ready(function(){ Init('<?php echo $id;?>'); }); </script>	
</body>
</html>
