<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<cflog application="no" file="SESSION" type="error" text="#session.Username#">
<script type="text/javascript">
	alert(window.location);
	alert(window.parent.location);
	var iFrameSessionCheck= (window.location != window.parent.location) ? true : false;
	if(iFrameSessionCheck == true)
	{
		alert('Your Session has expired. Please log in again.');
		window.parent.location.href = "/index.cfm";
	}
</script>
