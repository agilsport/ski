<?php
// advBase : Class de Base pour interface MySQL 
// Version 1.1

class advBase
{
	// Variables pour la Connexion MySQL ...
    var $m_login;	
    var $m_password;		
    var $m_database;
    var $m_server;

    var $m_directory;		// Repertoire principal 
    var $m_url;				// URL principal

	var $m_link;			// Connexion MySQL 
	
    // Constructeur 
    function __construct()
    {
    }
	
    // Destructeur 
    function __destruct()
    {
        $this->Close();
    }
	
    // Connexion BDD MySQL 
    function Connect()
    { 
        $this->m_link = mysqli_connect($this->m_server, $this->m_login, $this->m_password, $this->m_database);
        if (mysqli_connect_errno()) 
        {
			die('Impossible de se connecter : ' . mysqli_connect_error());
        }

        mysqli_set_charset($this->m_link, "utf8");
    }  
	
    // Close
    function Close()
    { 
        if (isset($this->m_link))
        {
            mysqli_close($this->m_link);
            unset($this->m_link);
            return true;
        }

        return false;
    }
	
    // Query
    function Query($sql, $forceInjection=false)
    {
		if (strpos($sql, ';') === false || $forceInjection)
		{
			mysqli_set_charset($this->m_link, "utf8"); // bizarre mais sur infomaniak c'est mieux ...

			$result = mysqli_query($this->m_link, $sql) or die ("Error Query : ".$sql);
			return $result;
		}

		die ("Error Injection SQL : ");
    }
	
	// MultiQuerySelect
	function MultiQuerySelect($sql, &$record)
	{
		mysqli_set_charset($this->m_link, "utf8"); // bizarre mais sur infomaniak c'est mieux ...
		
		$record = array();
		
		$arrayRes = array();
		$result = mysqli_multi_query($this->m_link, $sql) or die ("Error Multi-Query : ".$sql);
		if ($result) 
		{
			do 
			{
				$result = mysqli_store_result($this->m_link);
				if ($result)
				{
					array_push($arrayRes, $result->fetch_row());
					$result->free();
				}

				if (!mysqli_more_results($this->m_link))
					break;
			} 
			while (mysqli_next_result($this->m_link));
	
			$nb = count($arrayRes);
			if ($nb > 0)
			{
				for ($i=0;$i<count($arrayRes[$nb-1]);$i++)
					array_push($record, $arrayRes[$nb-1][$i]);
			}
		}
	}		
	
    // NumRows
    function NumRows($result)
    {
        return mysqli_num_rows($result);
    }

    // FetchArray
    function FetchArray($result, $resulttype=MYSQLI_ASSOC)
    {
        return mysqli_fetch_array($result, $resulttype);
    }

    // FetchRow
    function FetchRow($result)
    {
        return mysqli_fetch_row($result);
    }
	
    // RealEscapeString
    function RealEscapeString($txt)
    {
        return mysqli_real_escape_string($this->m_link, $txt);
    }

    // GetLastAutoIncrement
    function GetLastAutoIncrement()
    {
        $result = $this->Query('Select LAST_INSERT_ID()');
        $row = $this->FetchRow($result);
        return (int) $row[0];
    }

    // ShowColumnsSQL
    function ShowColumnsSQL($tableName, &$arrayColumns)
    {
		if ($arrayColumns == null) $arrayColumns = array();
		
        $result = $this->Query("SHOW COLUMNS FROM $tableName");
        $num_results = $this->NumRows($result);
        for ($i=0;$i<$num_results;$i++)
        {
            array_push($arrayColumns, $this->FetchArray($result));
        }
        return $num_results;
    }
	
   // GetIndexColumn
    function GetIndexColumn($tableName, $columnName)
    {
		$arrayColumns = array();
		$this->ShowColumnsSQL($tableName, $arrayColumns);
		for ($i=0;$i<count($arrayColumns);$i++)
		{
			if ($arrayColumns['Field'] == $columnName)
				return $i;
		}
        return -1;
    }
	
    // IsNullSQL
    function IsNullSQL($value)
    {
        $typeValue = gettype($value);
        if ($typeValue == 'NULL') return true;
        elseif (($typeValue == 'string') && ($value == '')) return true;
		else return false;
    }

    // ValueSQL
    function ValueSQL($value, $type, $null)
    {
        if ($this->IsNullSQL($value))
        {
            if ($null == 'YES') 
                return 'null';
            else 
                return "''";
        }

        $pos = strpos($type, 'int');
        if (($pos !== false) && ($pos == 0)) return $value;

        $pos = strpos($type, 'float');
        if (($pos !== false) && ($pos == 0)) return $value;

        $pos = strpos($type, 'double');
        if (($pos !== false) && ($pos == 0)) return $value;

        // On force le casting en string ...
        settype($value, "string");

        return "'".$this->RealEscapeString($value)."'";
    }

    // SetSQL
    function SetSQL($tableName, &$record, $bIgnoreNull=true, &$arrayColumns=null)
    {
        if ($arrayColumns == null)
        {
            $arrayColumns = array();
            $this->ShowColumnsSQL($tableName, $arrayColumns);
        }

        $sql = '';

        // Uniquement les colonnes présentes dans $record et $arrayColumns ...
        $count = 0;
        foreach($record as $key => $value)
        {
            if ($bIgnoreNull && $this->IsNullSQL($value))
                continue;

            for ($j=0;$j<count($arrayColumns);$j++)
            {
                if ($arrayColumns[$j]['Field'] == $key)
                {
                    if ($count == 0)
                        $sql .= 'Set ';
                    else
                        $sql .= ',';
                    ++$count;

                    $sql .= '`'.$key.'`=';
                    $sql .= $this->ValueSQL($value, $arrayColumns[$j]['Type'], $arrayColumns[$j]['Null']);

                    break;
                }				
            }
        }

        return $sql;
    }

    // InsertSQL
    function InsertSQL($tableName, &$record, $bIgnoreNull=true, &$arrayColumns=null)
    {
        return "Insert Into $tableName ".$this->SetSQL($tableName, $record, $bIgnoreNull, $arrayColumns);
    }

    function Insert($tableName, &$record, $bIgnoreNull=true, &$arrayColumns=null)
    {
        return $this->Query($this->InsertSQL($tableName, $record, $bIgnoreNull, $arrayColumns));
    }

    // UpdateSQL
    function UpdateSQL($tableName, &$record, $bIgnoreNull=false, &$arrayColumns=null)
    {
        return "Update $tableName ".$this->SetSQL($tableName, $record, $bIgnoreNull, $arrayColumns);
    }

    // ReplaceSQL
    function ReplaceSQL($tableName, &$record, $bIgnoreNull=false, &$arrayColumns=null)
    {
        return "Replace Into $tableName ".$this->SetSQL($tableName, $record, $bIgnoreNull, $arrayColumns);
    }
	
	function Replace($tableName, &$record, $bIgnoreNull=true, &$arrayColumns=null)
    {
        return $this->Query($this->ReplaceSQL($tableName, $record, $bIgnoreNull, $arrayColumns));
    }

    // InsertBlocSQL
    function InsertBlocSQL($tableName, &$tData, &$sql)
    {
        $sql = '';
        $nbData = count($tData);
        if ($nbData == 0) return;

        $arrayColumns = array();
        $this->ShowColumnsSQL($tableName, $arrayColumns);
        $nbColumns = count($arrayColumns);

        $sql .= "Insert Into $tableName (";
        for ($j=0;$j<$nbColumns;$j++)
        {
                if ($j >0) $sql .= ',';
                $sql .= $arrayColumns[$j]['Field'];
        }
        $sql .= ') Values ';

        for ($i=0;$i<$nbData;$i++)
        {
            $record = &$tData[$i];

            if ($i > 0) $sql .= ',';
            $sql .= '(';
            for ($j=0;$j<$nbColumns;$j++)
            {
                if ($j > 0) $sql .= ',';	

                $key = $arrayColumns[$j]['Field'];
                if (isset($record[$key]))
                    $sql .= $this->ValueSQL($record[$key], $arrayColumns[$j]['Type'], $arrayColumns[$j]['Null']);
                else
                    //					$sql .= $this->ValueSQL('', $arrayColumns[$j]['Type'], $arrayColumns[$j]['Null']);
                    $sql .= 'null';
            }
            $sql .= ')';
        }
    }
	
	// InsertBloc
	function InsertBloc($tableName, &$tData)
	{
		$sql = '';
		$this->InsertBlocSQL($tableName, $tData, $sql);
		return $this->Query($sql);
	}
	
    // ReplaceBlocSQL
    function ReplaceBlocSQL($tableName, &$tData, &$sql)
    {
        $sql = '';
        $nbData = count($tData);
        if ($nbData == 0) return;

        $arrayColumns = array();
        $this->ShowColumnsSQL($tableName, $arrayColumns);
        $nbColumns = count($arrayColumns);

        $sql .= "Replace Into $tableName (";
        for ($j=0;$j<$nbColumns;$j++)
        {
                if ($j >0) $sql .= ',';
                $sql .= $arrayColumns[$j]['Field'];
        }
        $sql .= ') Values ';

        for ($i=0;$i<$nbData;$i++)
        {
            $record = &$tData[$i];

            if ($i > 0) $sql .= ',';
            $sql .= '(';
            for ($j=0;$j<$nbColumns;$j++)
            {
                if ($j > 0) $sql .= ',';	

                $key = $arrayColumns[$j]['Field'];
                if (isset($record[$key]))
                    $sql .= $this->ValueSQL($record[$key], $arrayColumns[$j]['Type'], $arrayColumns[$j]['Null']);
                else
                    //					$sql .= $this->ValueSQL('', $arrayColumns[$j]['Type'], $arrayColumns[$j]['Null']);
                    $sql .= 'null';
            }
            $sql .= ')';
        }
    }
	
	// ReplaceBloc
	function ReplaceBloc($tableName, &$tData)
	{
		$sql = '';
		$this->ReplaceBlocSQL($tableName, $tData, $sql);
		return $this->Query($sql);
	}
 	
	// Colonnes Partagées entre 2 Tables 
    function SharedColumnsSQL($tableName1, $tableName2)
    {
		$arrayColumns1 = array();
        $this->ShowColumnsSQL($tableName1, $arrayColumns1);
 
		$arrayColumns2 = array();
        $this->ShowColumnsSQL($tableName2, $arrayColumns2);

		$arrayColumns = array();
		for ($i=0;$i<count($arrayColumns1);$i++)
		{
			$column = $arrayColumns1[$i]['Field'];
			for ($j=0;$j<count($arrayColumns2);$j++)
			{
				if ($arrayColumns2[$j]['Field'] == $column )
				{
					array_push($arrayColumns, $column);
 					break;
				}
			}
		}
		
        $sql = '';
        for ($j=0;$j<count($arrayColumns);$j++)
        {
            if ($sql != '')
                $sql .= ',';
            $sql .= $arrayColumns[$j];
        }
        return $sql;
    }

    // ColumnsSQL
    function ColumnsSQL($tableName, &$arrayColumns=null)
    {
        if ($arrayColumns == null)
        {
            $arrayColumns = array();
            $this->ShowColumnsSQL($tableName, $arrayColumns);
        }

        $sql = '';
        for ($j=0;$j<count($arrayColumns);$j++)
        {
            if ($sql != '')
                $sql .= ',';

            $sql .= $arrayColumns[$j]['Field'];
        }
        return $sql;
    }
	
	// ColumnsNames
	function ColumnsNames($tableName, &$arrayNames)
	{
		$arrayColumns = array();
		$this->ShowColumnsSQL($tableName, $arrayColumns);

		$arrayNames = array();
		for ($j=0;$j<count($arrayColumns);$j++)
		{
			array_push($arrayNames, $arrayColumns[$j]['Field']);
		}
	}

    // ColumnsRecordSQL
    function ColumnsRecordSQL(&$record, $bIgnoreNull=false)
    {
        $sql = '';
        foreach($record as $key => $value)
        {
            if ($bIgnoreNull && $this->IsNullSQL($value))
                continue;

            if ($sql != '')
                $sql .= ',';

            $sql .= $key;
        }

        return $sql;
    }

    // LoadTable
    function LoadTable($sql, &$arrayLoad, $resulttype=MYSQLI_ASSOC)
    {
        $result = $this->Query($sql);
        $num_results = $this->NumRows($result);

        $arrayLoad = array();
        for ($i=0;$i<$num_results;$i++)
        {
            array_push($arrayLoad, $this->FetchArray($result, $resulttype));
        }
    }
	
    // LoadTableFields
	function LoadTableFields($sql, &$arrayData, &$arrayFields, $resulttype=MYSQLI_NUM)
	{
		$result = $this->Query($sql);
		$num_results = $this->NumRows($result);
		
		$arrayFields = &mysqli_fetch_fields($result);
		
		$arrayData = array();
		for ($i=0;$i<$num_results;$i++)
		{
			array_push($arrayData, $this->FetchArray($result, $resulttype));
		}
	}

    // LoadRecord
	function LoadRecord($sql, &$record, $resulttype=MYSQLI_ASSOC)
	{
		$result = $this->Query($sql);
		if ($this->NumRows($result) >= 1)
			$record = $this->FetchArray($result, $resulttype);
		else
			$record = array();
	}
}
?>
