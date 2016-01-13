/*!
 * Common MacPatch Javascript functions
 */

function load(url,id) {
	window.open(url,'_self') ; 
}

function downloadURL(url) {
	var iframe;
  	iframe = document.getElementById("hiddenDownloader");
  	if (iframe === null)
	{
		iframe = document.createElement('iframe');  
		iframe.id = "hiddenDownloader";
		iframe.style.visibility = 'hidden';
		document.body.appendChild(iframe);
  	}
  	iframe.src = url;   
}