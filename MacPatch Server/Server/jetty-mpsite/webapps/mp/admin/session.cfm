<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title></title>
<cflog application="no" file="SESSION" type="error" text="#session.Username#">
<cfabort>

<script type="text/javascript">
	
	var iFrameSessionCheck= (window.location != window.parent.location) ? true : false;
	if(iFrameSessionCheck == true)
	{
		alert('Your Session has expired. Please log in again.');
		window.parent.location.href = "/index.cfm";
	}
</script>
</head>
<body>
</body>
</html>
