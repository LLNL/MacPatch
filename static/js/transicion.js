$(document).ready(function() {
    
    $("body").css("display", "none");
    $("body").fadeIn(900);
    
    $("a.transicion").click(function(event){
        event.preventDefault();
        linkDestino = this.href;
        $("body").fadeOut(500, redireccionarPag);      
    });
        
    function redireccionarPag() {
        window.location = linkDestino;
    }
    
});