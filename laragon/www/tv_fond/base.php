<?php
// Configuration générale et Connexion à la base de données ...
include_once('./adv/advBase.php');	
include_once('./adv/advUty.php');	

class MyBase extends advBase
{
	// Constructeur 
	function __construct($connect=true)
	{
		// wampserver 
		$this->m_login = "root";
		$this->m_password = "";	
		$this->m_database = "tv";
		$this->m_server = "localhost";
	
		if ($connect)
			$this->Connect();
	}
	
	static function chronoHHMMSS($chrono)
	{
		$chrono = intval($chrono);
		if ($chrono < 0)
			return "-";

		$h = intval($chrono/3600000);
		$m = intval(($chrono - $h*3600000)/60000);
		$s = intval(($chrono - $h*3600000 - $m*60000)/1000);
		
		return sprintf('%02dh%02d:%02d', $h, $m, $s);
	}
	
	static function chronoHMMSS($chrono)
	{
		$chrono = intval($chrono);
		if ($chrono < 0)
			return "-";

		$h = intval($chrono/3600000);
		$m = intval(($chrono - $h*3600000)/60000);
		$s = intval(($chrono - $h*3600000 - $m*60000)/1000);
		
		if ($h > 0)
			return sprintf('%02dh%02d:%02d', $h, $m, $s);
		else
			return sprintf('%d:%02d', $m, $s);
	}

	static function chronoHHMMSSMMM($chrono)
	{
		$chrono = intval($chrono);
		if ($chrono < 0)
			return "-";

		$h = intval($chrono/3600000);
		$m = intval(($chrono - $h*3600000)/60000);
		$s = intval(($chrono - $h*3600000 - $m*60000)/1000);
		$f = $chrono - $h*3600000 - $m*60000 - $s*1000;
		
		return sprintf('%02dh%02d:%02d.%03d', $h, $m, $s, $f);
	}
}
?>
