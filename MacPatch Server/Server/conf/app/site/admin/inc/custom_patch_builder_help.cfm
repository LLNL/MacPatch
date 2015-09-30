<cfsetting showDebugOutput="No">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<style type="text/css">
table#sample 
{
    background-color:#FFFFFF;
    border: solid #000000 1px;
	border-collapse: collapse;
}
table#sampleInner 
{
    background-color:#FFFFFF;
    border: solid #000000 1px;
	border-collapse: collapse;
	width: 600px;
}
table#sample th {
    padding: 4px;
    border: solid #000000 1px;
	background-color: #CCCCCC;
}

table#sample td {
    padding: 4px;
    border: solid #000000 1px;
	background-color: #FFFFFF;
	font-size: 10pt;
}
</style>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Detailed Info</title>
</head>
<body>
<h2>MacPatch - Patch Criteria Help</h2>
<table id="sample">
	<tr>
		<th>Base Criteria</th>
		<th>Description</th>
	</tr>
	<tr>
		<td>BundleID</td>
		<td>
			<table id="sampleInner">
				<tr>
					<th>Query</th>
					<th>Value</th>
					<th>Query Result</th>
					<th>Example Syntax</th>
				</tr>
				<tr>
					<td>Exists</td>
					<td>BundleID Value</td>
					<td>True/False</td>
					<td>Exists@com.adobe.Reader@True</td>
				</tr>
				<tr>
					<td>Version</td>
					<td>BundleID Value</td>
					<td>Version;(EQ,LT,LTE,GT,GTE,NEQ)</td>
					<td>Version@com.adobe.Reader@9.3.0;LT</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td>File</td>
		<td>
			<table id="sampleInner">
				<tr>
					<th>Query</th>
					<th>Value</th>
					<th>Query Result</th>
					<th>Example Syntax</th>
				</tr>
				<tr>
					<td>Exists</td>
					<td>File Path</td>
					<td>True/False</td>
					<td>Exists@/Applications/Firefox.app@True</td>
				</tr>
				<tr>
					<td>Date</td>
					<td>File Path</td>
					<td>True/False</td>
					<td>Date@/Applications/Firefox.app@2010-03-22 12:00:00;LT</td>
				</tr>
				<tr>
					<td>Hash</td>
					<td>File Path</td>
					<td>MD5 Hash;True/False</td>
					<td>Hash@/Applications/Firefox.app@123432dsh2362h3h;TRUE</td>
				</tr>
				<tr>
					<td>Version</td>
					<td>File Path</td>
					<td>Version;(EQ,LT,LTE,GT,GTE,NEQ)</td>
					<td>Version@/Applications/Firefox.app@3.5.7;LT</td>
				</tr>
			</table>
		</td>
		<tr>
			<td>Script</td>
			<td>
				<table id="sampleInner">
					<tr>
						<th>Query</th>
						<th>Value</th>
						<th>Query Result</th>
						<th>Example Syntax</th>
					</tr>
					<tr>
						<td>Script</td>
						<td>Script Text</td>
						<td>True</td>
						<td>#!/bin/sh ...</td>
					</tr>
				</table>
			</td>
		</tr>
	</tr>
</table>
</body>
</html>