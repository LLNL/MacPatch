/*
 * Extra parser: checkbox
 * Credit: Christian Bach
 *
 */
jQuery.tableSorter.parsers.checkbox = {
    id: 'input',
    is: function(s) {
        return s.toLowerCase().match(/<input[^>]*checkbox[^>]*/i);;
    },
    format: function(s) {
        var integer = 0;
        if(s.toLowerCase().match(/<input[^>]*checked*/i)) {
                integer = 1;
        }
        return integer;
    },
    filter: 'checkbox',
    sorter: jQuery.tableSorter.sorters.numeric
};
jQuery.tableSorter.analyzer.add(jQuery.tableSorter.parsers.checkbox);

/*
 * Extra parser: Ratio
 * Credit: Mike Chabot 
 *
 */
jQuery.tableSorter.parsers.ratio = {
    id: 'ratio',
    is: function(s) {
        return s.match(new RegExp(/^\d+ \/ \d+$/));
    },
    format: function(s) {
                var a = s.split('/');
                var r = 0
                if(a.length != 2) r =  0;
                else if(a[1] == 0) r =  Number.MAX_VALUE;
                else r =  parseFloat(a[0]) / parseFloat(a[1]);
                return r;
        },
    filter: 'numeric',
    sorter: jQuery.tableSorter.sorters.numeric
};
jQuery.tableSorter.analyzer.add(jQuery.tableSorter.parsers.ratio); 