var oXmlHttp

function showLogEvents(str)
{
	if (str == "Select...") {
		return false;
	}
	var url="includes/_admin_logging_get.cfm?&type=" + str
	oXmlHttp=GetHttpObject(stateChanged)
	oXmlHttp.open("GET", url , true)
	oXmlHttp.send(null);
}

function stateChanged()
{
	if (oXmlHttp.readyState==4 || oXmlHttp.readyState=="complete") {
		document.getElementById("logList").innerHTML=oXmlHttp.responseText;
	}
}

function GetHttpObject(handler)
{
	try 
	{
		var oRequester = new XMLHttpRequest();
		oRequester.onload=handler
		oRequester.onerror=handler
		return oRequester
	}
	catch (error) 
	{
		return false;
	}
}
//