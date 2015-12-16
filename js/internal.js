// JavaScript Document
$(function(){ 			  	
	//Shadowbox.init();	
	
	/*$('#llnl-menu-tab').click(function(e)
	{
		$('#llnl-menu').slideToggle('fast');
		$(this).toggleClass('open');
			
		e.preventDefault();
	});	*/
	$('.carousel').carousel({
		interval: 10000
	});
	$('#llnl-menu-carousel').carousel({
		interval: false
	});
	$('.carousel-bullets a').click(function(q){
		q.preventDefault();
		targetSlide = $(this).attr('data-to')-1;
		var $carousel = $(this).parent().parent();
		$carousel.carousel(targetSlide);
	});
	$('.carousel').bind('slid', function() {
		// Get currently selected item
		var item = $('.carousel-inner .item.active');
	
		// Deactivate all nav links
		$('.carousel-bullets a').removeClass('active');
	
		// Index is 1-based, use this to activate the nav link based on slide
		var index = item.index() + 1;
		$('.carousel-bullets a:nth-child(' + index + ')').addClass('active');
	});
	
	$('[rel="tooltip"]').tooltip();
	$('[rel="popover"]').popover();
	$('[rel="modal"]').modal();
	$('[rel="collapse"]').collapse();

	$('a[data-toggle="tab"]').on('shown', function (e) {
    	e.target;
    	e.relatedTarget;
    });

    /* full carousel */
	if(typeof(swiperight) == "function"){
		$("#fullcarouselv2").swiperight(function() {
			$("#fullcarouselv2").carousel('prev');
		});
		$("#fullcarouselv2").swipeleft(function() {
			$("#fullcarouselv2").carousel('next');
		});
		$("#fullcarousel").swiperight(function() {
			$("#fullcarousel").carousel('prev');
		});
		$("#fullcarousel").swipeleft(function() {
			$("#fullcarousel").carousel('next');
		});
	}
				
});


function sizewin(url,w,h) {
	var width=w;
	var height=h;
	var left = (screen.width/2)-(w/2);
	var top = (screen.height/2)-(h/2);
	var toolbar='no';
	var location='no';
	var directories='no';
	var status='no';
	var menubar='no';
	var scrollbars='yes';
	var resizable='yes';
	var atts='width='+width+'show,height='+height+',top='+top+',screenY=';
	atts+= top+',left='+left+',screenX='+left+',toolbar='+toolbar;
	atts+=',location='+location+',directories='+directories+',status='+status;
	atts+=',menubar='+menubar+',scrollbars='+scrollbars+',resizable='+resizable;
	window.open(url,'win_name',atts);
}
	
