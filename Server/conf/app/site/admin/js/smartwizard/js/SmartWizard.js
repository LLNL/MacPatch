/*
 * SmartWizard
 * a javascript wizard control
 * http://tech-laboratory.blogspot.com
 * 
 * Date: 04-AUG-2009
 * Version: 0.98
 */
 
 
(function($){  
    $.fn.smartWizard = function(options) {
        var defaults = {
              selectedStep: 0,  // Selected Step, 0 = first step
              errorSteps:[],    // Array Steps with errors
              enableAll:false,  // Enable All Steps, true/false
              animation:true,   // Animation Effect on navigation, true/false         
              validatorFunc:function(){return true;} // Step validation function, Step index will be passed
        };
        var options = $.extend(defaults, options);  
      
        return this.each(function() {
                obj = $(this); 
                var wizcurrent = 0;
      		      var steps = $("ul > li > a", obj);
      		      // Apply Default Style to Steps
      		      applyCSS($(steps, obj),"wiz-anc-default");
      		      // Hide All Steps on load
                hideAllSteps();
      		      
                $(steps, obj).bind("click", function(e){
                    e.preventDefault();
                    var isDone = $(this, obj).attr("isDone");
                    if(isDone == 1){
                        var selIdx = steps.index(this);  
                        applyCSS($(wizcurrent, obj),"wiz-anc-done"); 
                        selectStep(selIdx);
                    }
                });
                // activates steps up to the selected step
                for(i=0;i<steps.length;i++){
                  if(i<=options.selectedStep || options.enableAll==true){
                    activateStep(i);
                  }
                }
                // highlight steps with errors
                $.each(options.errorSteps, function(i, n){
                  //applyCSS(steps.eq(n),"wiz-anc-error");
                  setErrorStep(n)
                });
                
      		      selectStep(options.selectedStep);
                //Next Navigation
                $(".next", obj).bind("click", function(e){
                  e.preventDefault();  
                  var curStepIdx = $(steps, obj).index(wizcurrent);
                  if(options.validatorFunc(curStepIdx)){
                      var nextStepIdx = curStepIdx+1;
                      applyCSS($(wizcurrent, obj),"wiz-anc-done"); 
                      selectStep(nextStepIdx);
                  }
                });
                
                //Back Navigation
                $(".back", obj).bind("click", function(e){
                  e.preventDefault(); 
                  applyCSS($(wizcurrent, obj),"wiz-anc-done"); 
                  var prevIdx = $(steps, obj).index(wizcurrent)-1;
                  selectStep(prevIdx);
                });
            
                function selectStep(idx){
                    if(idx < steps.length && idx >= 0){
                      var selStepAnchor = $(steps, obj).eq(idx);
                      var selStepIdx =selStepAnchor.attr("href");
                      hideAllSteps();          
                      selStepAnchor.attr("isDone","1");
                      
                      if(options.animation==true){
                        $(selStepIdx, obj).fadeIn("fast");
                      }else{
                        $(selStepIdx, obj).show();
                      }
                      applyCSS($(selStepAnchor, obj),"wiz-anc-current");
                      wizcurrent = selStepAnchor;
                    }
                }
                
                function activateStep(idx){
                    var selStepAnchor = steps.eq(idx);
                    selStepAnchor.attr("isDone","1");
                    applyCSS($(selStepAnchor, obj),"wiz-anc-done");
                }

                function setErrorStep(idx){
                    var selStepAnchor = steps.eq(idx);
                    selStepAnchor.attr("isError","1"); 
                    $(selStepAnchor, obj).addClass("wiz-anc-error"); 
                }
                
                function unsetErrorStep(idx){
                    var selStepAnchor = steps.eq(idx);
                    selStepAnchor.attr("isError",""); 
                    $(selStepAnchor, obj).removeClass("wiz-anc-error"); 
                } 

                function hideAllSteps(){
            	    $(steps, obj).each(function(){
                        $($(this, obj).attr("href"), obj).hide();
                  });
                }
                
                function applyCSS(elm,css){
                    $(elm, obj).removeClass("wiz-anc-default");
                    $(elm, obj).removeClass("wiz-anc-current");
                    $(elm, obj).removeClass("wiz-anc-done");
                    $(elm, obj).addClass(css); 
                }
        });  
    };  
})(jQuery);
