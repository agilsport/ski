<?php
	$id = '';
	if (isset($_GET['id']))
		$id = $_GET['id'];
	
	$epreuve = -1;
	if (isset($_GET['epreuve']))
		$epreuve = intval($_GET['epreuve']);
	
	$categ = '';
	if (isset($_GET['categ']))
		$categ = $_GET['categ'];
	
	$sex = '';
	if (isset($_GET['sex']))
		$sex = $_GET['sex'];
	
	$distance = '';
	if (isset($_GET['distance']))
		$distance = $_GET['distance'];
	
	$finish = '';
	if (isset($_GET['finish']))
		$finish = $_GET['finish'];
	
	$title = '';
	if (isset($_GET['title']))
		$title = $_GET['title'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>TV</title>
	<link href="./js/bootstrap/css/bootstrap.min.css" rel="stylesheet">
	<link href="./css/head.css?v10" rel="stylesheet">
	<link href="./css/startlist.css?v9" rel="stylesheet">
	<link href="./css/ranking.css?v9" rel="stylesheet">
	<link href="./css/ranking2.css?v9" rel="stylesheet">
	<link href="./css/animate.min.css" rel="stylesheet" />
</head>
<body> 
	<script type="text/javascript" src="./js/jquery-1.11.2.min.js"></script>
	<script type="text/javascript" src="./js/bootstrap.min.js"></script>
	<script type="text/javascript" src="./js/screen.js?v7"></script>
	<script type="text/javascript" src="./js/head.js?v7"></script>
	<script type="text/javascript" src="./js/chrono.js?v7"></script>
	<script type="text/javascript" src="./js/tv.js?v15"></script>
	<script type="text/javascript"> $(document).ready(function(){ 
		Init(<?php echo "'$id', $epreuve,'$categ','$sex','$distance','$finish','$title'";?>); }); 
	</script>	
</body>
</html>
