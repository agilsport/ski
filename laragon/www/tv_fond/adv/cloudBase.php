<?php
include_once('advBase.php');	
include_once('cloudUty.php');	

// cloudBase : Class de Base pour interface sqlCloud C++
// Version 1.0

define("JSON_RETURN_SUCCESS", 0);
define("JSON_RETURN_INVALID_SESSION", 1);
define("JSON_RETURN_ERROR", 99);

define("sqlCLOUD_UNDEFINED", 0);
define("sqlCLOUD_EXECUTE", 1);
define("sqlCLOUD_SELECT", 2);
define("sqlCLOUD_LOAD", 3);
define("sqlCLOUD_LOAD_FIELDS", 4);
define("sqlCLOUD_SHOW_TABLES", 5);
define("sqlCLOUD_SESSION", 6);
define("sqlCLOUD_LOGIN", 7);
define("sqlCLOUD_NEW_LOGIN", 8);
define("sqlCLOUD_FORGET_LOGIN", 9);

define("sqlCLOUND_AUTOINCREMENT", -2147483600);

class cloudBase extends advBase
{
	var $m_login;			// Variables pour la Connexion MySQL ...
	var $m_password;
	var $m_database;
	var $m_server;
	var $m_link;
	
	function cloud_Execute(&$cmd, &$arrayReturn)
	{
//		$cmd = str_replace(sqlCLOUND_AUTOINCREMENT, ???, $cmd);
		
		if ($this->Query($cmd))
			array_push($arrayReturn, array('return' => JSON_RETURN_SUCCESS, 'cmd' => sqlCLOUD_EXECUTE, 'autoincrement' => $this->GetLastAutoIncrement())); 
		else
			array_push($arrayReturn, array('return' => JSON_RETURN_ERROR, 'cmd' => sqlCLOUD_EXECUTE));
	}
	
	function cloud_Select(&$cmd, &$arrayReturn)
	{
		$record = null;
		$this->LoadRecord($cmd, $record, MYSQLI_NUM);
		if ($record == null)
			array_push($arrayReturn, array('return' => JSON_RETURN_SUCCESS, 'cmd' => sqlCLOUD_SELECT));
		else
			array_push($arrayReturn, array('return' => JSON_RETURN_SUCCESS, 'cmd' => sqlCLOUD_SELECT, 'record' => $record));
	}
	
	function cloud_Load(&$cmd, &$arrayReturn)
	{
		$table = null;
		$this->LoadTable($cmd, $table, MYSQLI_NUM);
		array_push($arrayReturn, array('return' => JSON_RETURN_SUCCESS, 'cmd' => sqlCLOUD_LOAD, 'table' => $table));
	}
	
	function cloud_LoadFields(&$cmd, &$arrayReturn)
	{
		$table = null;
		$fields = null;
		$this->LoadTableFields($cmd, $table, $fields);
		array_push($arrayReturn, array('return' => JSON_RETURN_SUCCESS, 'cmd' => sqlCLOUD_LOAD_FIELDS, 'table' => $table, 'fields' => $fields));
	}

	function cloud_ShowTables(&$tableName, &$arrayReturn)
	{
		$cmd = "Show Tables ";
		if ($tableName != '')
			$cmd .= "LIKE '$tableName'";

		$arrayTables = null;
		$this->LoadTable($cmd, $arrayTables, MYSQLI_NUM);

		$arrayBase = array();
		for ($i=0;$i<count($arrayTables);$i++)
		{
			$cmd = "Show Columns From ".$arrayTables[$i][0];
			$arrayColumns = null;
			$this->LoadTable($cmd, $arrayColumns, MYSQLI_NUM);
			
			array_push($arrayBase, array('table' => $arrayTables[$i][0], 'columns' => $arrayColumns));
		}
		
		array_push($arrayReturn, array('return' => JSON_RETURN_SUCCESS, 'cmd' => sqlCLOUD_SHOW_TABLES, 'base' =>$arrayBase ));
	}
	
	function cloud_Session($ref, &$arrayReturn)
	{
		$this->Query("Insert Into cloud_Session (Ref) values ('$ref')");
		array_push($arrayReturn, array('return' => JSON_RETURN_SUCCESS, 'cmd' => sqlCLOUD_SESSION, 'session' => $this->GetLastAutoIncrement()));
	}
	
	// Fonction à Surcharger
	function cloud_Login($key, &$arrayReturn)
	{
		array_push($arrayReturn, array('return' => JSON_RETURN_ERROR, 'cmd' => sqlCLOUD_LOGIN, 'msg' => "cloud_login"));
	}

	// Fonction à Surcharger
	function cloud_NewLogin(&$value, &$arrayReturn)
	{
		array_push($arrayReturn, array('return' => JSON_RETURN_ERROR, 'cmd' => sqlCLOUD_NEW_LOGIN, 'msg' => "cloud_new_login"));
	}

	// Fonction à Surcharger
	function cloud_ForgetLogin(&$value, &$arrayReturn)
	{
		array_push($arrayReturn, array('return' => JSON_RETURN_ERROR, 'cmd' => sqlCLOUD_FORGET_LOGIN, 'msg' => "cloud_forget_login"));
	}
	
	// Parse URL post ou get de la forme : ?get&session=1&cmd1=x1&cm2=x2|y2...
	function cloud_Main()
	{
		$uty = new cloudUty();
		$session = $uty->GetInt('session');
		
		if ($session < 0)
		{
			echo json_encode(array('return' => JSON_RETURN_INVALID_SESSION, 'msg' => 'Invalid ID Session')); 
			return;
		}
		
		$arrayReturn = array();
		for ($i=1;;$i++)
 		{
			$cmd = $uty->GetString("cmd$i");
			if ($cmd == '') break;

			$params = explode('|', $cmd, 2);
			if (count($params) < 2)
			{
				array_push($arrayReturn, array('return' => JSON_RETURN_ERROR, 'msg' => "Empty Command $i"));
				continue;
			}

			$idCmd = (int) $params[0];
			switch($idCmd)
			{
				case sqlCLOUD_EXECUTE:
				$this->cloud_Execute($params[1], $arrayReturn);
				break;

				case sqlCLOUD_SELECT:
				$this->cloud_Select($params[1], $arrayReturn);
				break;

				case sqlCLOUD_LOAD:
				$this->cloud_Load($params[1], $arrayReturn);
				break;
				
				case sqlCLOUD_LOAD_FIELDS:
				$this->cloud_LoadFields($params[1], $arrayReturn);
				break;

				case sqlCLOUD_SHOW_TABLES:
				$this->cloud_ShowTables($params[1], $arrayReturn);
				break;

				case sqlCLOUD_SESSION:
				$this->cloud_Session($params[1], $arrayReturn);
				break;

				case sqlCLOUD_LOGIN:
				$this->cloud_Login($params[1], $arrayReturn);
				break;

				case sqlCLOUD_NEW_LOGIN:
				$this->cloud_NewLogin($params[1], $arrayReturn);
				break;

				case sqlCLOUD_FORGET_LOGIN:
				$this->cloud_ForgetLogin($params[1], $arrayReturn);
				break;

				default:
				array_push($arrayReturn, array('return' => JSON_RETURN_ERROR, 'cmd' => $idCmd, 'msg' => "Invalid Command $i : $cmd"));
				break;
			}
		}

		echo json_encode($arrayReturn);
	}
}

?>
