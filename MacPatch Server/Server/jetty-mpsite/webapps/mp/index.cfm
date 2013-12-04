<cfinclude template="./assets/_public_header.cfm">
<script type="text/javascript">
<!--
	function toggle_visibility(id) {
	   var e = document.getElementById(id);
	   if(e.style.display == 'none')
		  e.style.display = 'block';
	   else
		  e.style.display = 'none';
	}
//-->
</script>
<!--- Get Connected Server --->
<cfscript>
	try {
		inet = CreateObject("java", "java.net.InetAddress");
		inet = inet.getLocalHost();
	} catch (any e) {
		inet = "localhost";
	}
</cfscript>
<br>
<p>
	<font size="+3" color="#000011">
		<b><i> Admin Login</i></b>
	</font>
</p>
<div style="padding:10px;">
<form action="./admin/" method="post">
	<table cellspacing="10">
    	<tr>
        	<td></td>
        	<td colspan="2">
            	<cfif StructKeyExists(session,"error")>
                    <div style='color:Red;font-size:12px; font-weight:bold'>
                        <p><cfoutput>#session.error#</cfoutput></p>
                    </div>
                    <cfset StructDelete(session,"error")>
                </cfif>
            </td>
        </tr>
        <tr valign="top">
			<td><div align="right">OID: </div></td> 
			<td><input type="text" name="_user" maxlength="30"></td>
			<td> User ID</td>
		</tr>
		<tr valign="top">
			<td><div align="right">PASSWORD: </div></td>
			<td><input type="password" name="_pass" maxlength="30"></td>        
			<td> Password</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>
				<input type="Submit" value="Login" name="Login">
			</td>
			<td>&nbsp;</td>
		</tr>
	</table>
	<div style="margin-top:100px;">
		<fieldset>
			<legend style="padding: 6px;font-size:12px;"><b>Browser Support</b></legend>
			<div style="padding:10px;font-size:11px;">This site is best viewed using the most recent version of Mozilla Firefox or Safari. Please note, Internet Explorer has some issues with displaying all of the content.</div> 
		</fieldset>
		<fieldset>
			<legend style="padding: 6px;font-size:12px;"><b>Screen Size</b></legend>
			<div style="padding:10px;font-size:11px;">Considering the data-centric nature of this application, it has been optimized for viewing on a monitor with a minimum screen resolution of 1024x768 pixels. This wider format allows us to present you with the information in a much more efficient manner.</div>
		</fieldset>
	</div>
	<div style="margin-top:40px;">
		<a href="#" onClick="toggle_visibility('foo');" style="color:black;font-size:10px;">Show Server Info</a>
		<div id="foo" style='display:none;color:black;font-size:10px;'>
		<cfoutput>#inet#</cfoutput>
	</div>
</form>
</div>

<cfinclude template="./assets/_public_footer.cfm">
