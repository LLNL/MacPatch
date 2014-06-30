<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<title>Web Authentication Service</title>
	<link href="/css/login.css" rel="stylesheet" type="text/css" />
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
<div id="layout" class="layout">
	<div class="login_dialog">
		<h1>MacPatch Admin Console</h1>
		<form accept-charset="UTF-8" action="/admin/" method="post"">
		<div class="icon"><div class="img"></div></div>
		<h2><cfoutput>#CGI.SERVER_NAME#</cfoutput></h2>
		<div class="form_input">
			<div class="form_row">
				<label for="username">User Name</label>
				<input id="username" name="_user" type="text" placeholder="User Name" autocorrect="off" autocapitalize="off" autocomplete="off" />
			</div>
			<div class="form_row">
				<label for="password">Password</label>
				<input id="password" name="_pass" placeholder="Password" type="password" value="" />
			</div>
		</div>
		<p class="error">
        	<cfif StructKeyExists(session,"error")>
                    <cfoutput>#session.error#</cfoutput>
                <cfset StructDelete(session,"error")>
            </cfif>
        </p>
		<div class="buttons">
			<span class="spinner" id="login_spinner"></span>
			<input id="login_button" type="submit" class="login" value="Log In">
		</div>
		</form>	
        <hr>
        <div style="margin-top:10px; margin-bottom:10px; text-align:center;">
        	<a href="https://<cfoutput>#CGI.SERVER_NAME#</cfoutput>/clients" class="headermenuIndentMiddle">Client Download</a>
        </div>
	</div>
</div>
</body>
</html>