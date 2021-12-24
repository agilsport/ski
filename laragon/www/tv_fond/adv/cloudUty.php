<?php

class cloudUty
{
	var $m_parameters;
	
	function __construct()
	{
		isset($_GET['get']) ? $this->m_parameters = &$_GET : $this->m_parameters = &$_POST;
	}
	
	function GetKeyWord($key)
	{
		if ($key == 'OR') return '|';
		if ($key == 'AND') return '&';
		if ($key == 'QU') return '?';
		if ($key == 'EQ') return '=';
		if ($key == 'DI') return '#';
		if ($key == 'PL') return '+';
		if ($key == 'MI') return '-';
		if ($key == 'SQ') return '\'';
		if ($key == 'DQ') return '"';
		if ($key == 'PC') return '%';
		
		return '|'.$key.'|'; // Bizarre ???
	}

	// cmdi=idCmd|command avec pipe keywords ...
	function GetString($key, $default="")
	{
		if (isset($this->m_parameters[$key]))
		{
			$src = $this->m_parameters[$key];
			$params = explode('|', $src);

			$dest = '';
			for ($i=0;$i<count($params);$i++)
			{
				if ($i == 0)
				{
					$dest .= $params[$i];	// idCmd : 1=sqlCLOUD_EXECUTE, 2=sqlCLOUD_SELECT, etc ...
					$dest .= '|';
				}
				elseif ($i == 1)
					$dest .= $params[$i];
				elseif ($i%2) 
					$dest .= $params[$i];
				else
					$dest .= $this->GetKeyWord($params[$i]);
			}
			return $dest;
		}
		else
			return $default;
	}
		
	function GetInt($key, $default=0)
	{
		if (isset($this->m_parameters[$key]))
			return (int) $this->m_parameters[$key];
		else
			return (int) $default;
	}
}

?>
