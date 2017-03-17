// JavaScript Document
// All this does is close the app to main login window. Otherwise it will display login
// in the iFrame.
var iFrameSessionCheck= (window.location != window.parent.location) ? true : false;
if(iFrameSessionCheck == true)
{
	alert('Your Session has expired. Please log in again.');
	window.parent.location.href = "/index.cfm";
}