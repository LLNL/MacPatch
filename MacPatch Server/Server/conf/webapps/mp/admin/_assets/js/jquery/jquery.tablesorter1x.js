/*
 *
 * TableSorter - Client-side table sorting with ease!
 *
 * Copyright (c) 2006 Christian Bach (http://motherrussia.polyester.se)
 * Dual licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) 
 * and GPL (http://www.opensource.org/licenses/gpl-license.php) licenses.
 * 
 * $Date: 2006-08-21 14:43:23 +0000 (Mon, 21 Aug 2006) $
 * $Author: Christian $
 * 
 */
$.fn.tableSorter = function(o) {
	
	var defaults =  {
		sortDir: 0,
		sortColumn: null,
		sortClassAsc: 'ascending',
		sortClassDesc: 'descending',
		headerClass: null,
		stripingRowClass: false,
		highlightClass: false,
		rowLimit: 0,
		minRowsForWaitingMsg: 0,
		disableHeader: -1,
		stripRowsOnStartUp: false,
		columnParser: false,
		rowHighlightClass: true,
		useCache: true,
		debug: false,
		textExtraction: 'simple',
		features: {
		
		},
		styles: {
		
		},
		
				
		// text extraction stuff
		/**
		* @param textExtraction
		* @type string
		* @example textExtraction: 'simple'		
		*/
		
		/**
		* @param textExtractionCustom
		* @type object
		* @example textExtractionCustom: { 1:function(o) { return o.innerHTML;} }		
		*/
		textExtractionCustom: false,
		
		dateFormat: 'mm/dd/yyyy' /** us default, uk dd/mm/yyyy */
	};		
	
	return this.each(function(){
		
		/** merge default with custom options */
		jQuery.extend(defaults, o);
		
		/** Private vars */
		var COLUMN_DATA = [];			/** array for storing columns */
		var COLUMN_CACHE = [];			/** array for storing sort caches.*/
		var COLUMN_INDEX;				/** int for storing current cell index */
		var COLUMN_SORTER_CACHE = [];	/** array for sorter parser cache */
		var COLUMN_CELL;				/** stores the current cell object */
		var COLUMN_DIR;					/** stores the current soring direction */
		var COLUMN_HEADER_LENGTH;		/** stores the columns header length */
		var ROW_LAST_HIGHLIGHT_OBJ = false;
		var COLUMN_LAST_INDEX = -1;
		var COLUMN_LAST_DIR = defaults.sortDir;
		
		/** table object holder.*/
		var oTable = this;				
		
		if(defaults.stripRowsOnStartUp && defaults.stripingRowClass) {
			$.tableSorter.utils.stripRows(oTable,defaults);
		}
		
		/** Store lenght of table rows. */
		var tableRowLength = oTable.rows.length-1;
		
		/** Index column data. */			
		buildColumnDataIndex();
		
		
		function buildColumnHeaders() {
			var oFirstTableRow = oTable.rows[0];
			var oDataSampleRow = oTable.rows[1];
			/** store column length */
			COLUMN_HEADER_LENGTH = oFirstTableRow.cells.length;	
			/** loop column headers */
			for( var i=0; i < COLUMN_HEADER_LENGTH; i++ ) {	
				var oCell = oFirstTableRow.cells[i];
				
				if(!$.tableSorter.utils.isHeaderDisabled(oCell,defaults.disableHeader,i)) {	
					/** get current cell from columns headers */
					$.tableSorter.utils.setParams(defaults);
					var oCellValue = $.tableSorter.utils.getElementText(oDataSampleRow.cells[i],'columns',i);
					/** check for default column. */
					if(typeof(defaults.sortColumn) == "string") {
						if(defaults.sortColumn.toLowerCase() == $.tableSorter.utils.getElementText(oCell,'header',i).toLowerCase()) {
							defaults.sortColumn = i;
						}
					}
					
					/** get sorting method for column. */
					COLUMN_SORTER_CACHE[i] = $.tableSorter.analyzer.analyseString(oCellValue,defaults);
					
					/** if we have a column parser, set it manual. */
					if(defaults.columnParser) {
						var a = defaults.columnParser;
						var l = a.length;
						for(var j=0; j < l; j++) {
							if(i == a[j][0]) {
								COLUMN_SORTER_CACHE[i] = $.tableSorter.analyzer.getById(a[j][1]);
								
								continue;
							}  
						} 	
					}
					// debug message
					if(defaults.debug) {
						console.log('Index, Sorter', i, COLUMN_SORTER_CACHE[i].id);
					}
					
					if(defaults.headerClass) {
						$(oCell).addClass(defaults.headerClass);
					}
					
					$(oCell).wrapInner({element: '<a href="#">', name: 'a', className: 'sorter'});
					//$(oCell).append('<div class="filterIcon">&nbsp;</div>');
				
					oCell.index = i;
					oCell.count = defaults.sortDir;
					/*
					$(".filterIcon",oCell).click(function(e) {
						filterColumn($(this).parent(),$(this).parent()[0].index);
						//e.preventDefault();
					});
					*/
					
					$(".sorter",oCell).click(function(e) {
						sortOnColumn( $(this).parent(), ($(this).parent()[0].count++) % 2, $(this).parent()[0].index );
						//e.stopPropagation();
					});
					 
				}
			}
			/** blah, add comment later, code is pretty self explanable. */
			addColGroup(oFirstTableRow);

			/** if we have a init sorting, fire it! */
			if(defaults.sortColumn != null) {
				$(oFirstTableRow.cells[defaults.sortColumn]).trigger("click");	
			}
			
			if(defaults.rowHighlightClass) {
				$("tbody/tr",oTable).click(function() {
					if(ROW_LAST_HIGHLIGHT_OBJ) {
						ROW_LAST_HIGHLIGHT_OBJ.removeClass(defaults.rowHighlightClass);	
					}
					ROW_LAST_HIGHLIGHT_OBJ = $(this).addClass(defaults.rowHighlightClass);
				});
			}
		}
		/** break out and put i $.tableSorter? */
		function buildColumnDataIndex() {
			/** make colum data. */
			var l = oTable.rows.length;
			for (var i=1;i < l; i++) {
				/** Add the table data to main data array */
				COLUMN_DATA.push(oTable.rows[i]); 
			}
			/** when done, build headers. */
			buildColumnHeaders();
		}
		function addColGroup(columnsHeader) {
			var oSampleTableRow = oTable.rows[1];
			/** adjust header to the sample rows */
			for(var i=0; i < COLUMN_HEADER_LENGTH; i++) {
				$(columnsHeader.cells[i]).css("width",oSampleTableRow.cells[i].clientWidth + "px");
			}
		}
		
		function filterColumn(oCell,index) {
		
			COLUMN_INDEX = index;
				
			var flatData = $.tableSorter.data.flatten(COLUMN_DATA,COLUMN_SORTER_CACHE,index);
			var l = flatData.length;
			var p = COLUMN_SORTER_CACHE[COLUMN_INDEX];
			var f = $.tableSorter.filter[p.filter];
			var o = $("#filter");
			o.show().empty();
			// sort to get min and max values.
			flatData.sort(p.sorter);
			
			f.render(o,flatData[0][1],flatData[l-1][1]);
			
			// add buttons.
			o.append('<div><input type="reset" value="clear"/><input type="submit" value="apply"/></div>');
				
			$('input[@type="submit"]',o).click(function() {
				var min = $('input[@name="min"]',o).val();
				var max = $('input[@name="max"]',o).val();
				$.tableSorter.filter.applyFilter(min,max);
			});
			
			$('input[@type="reset"]',o).click(function() {
				$.tableSorter.filter.resetFilter();
				o.hide();
			});
			
			var d = {
				oTable: oTable,
				defaults: defaults,
				f: f,
				data: flatData,
				type: p.filter,
				columnData: COLUMN_DATA,
				index: COLUMN_INDEX,
				lastIndex: COLUMN_LAST_INDEX
			}
			
			$.tableSorter.filter.setData(d);
			
		}
		function sortOnColumn(oCell,dir,index) {
			/** trigger event sort start. */
			if(tableRowLength > defaults.minRowsForWaitingMsg) {
				$.event.trigger( "sortStart");
			}
			/** define globals for current sorting. */
			COLUMN_INDEX = index;
			COLUMN_CELL = oCell;
			COLUMN_DIR = dir;
			/** clear all classes, need to be optimized. */
			$("th."+defaults.sortClassAsc,oTable).removeClass(defaults.sortClassAsc);
			$("th."+defaults.sortClassDesc,oTable).removeClass(defaults.sortClassDesc);
			/**add active class and append image. */
			$(COLUMN_CELL).addClass((dir % 2 ? defaults.sortClassAsc : defaults.sortClassDesc));
			/** remove highlighting */
			if(defaults.highlightClass) {
				if(COLUMN_LAST_INDEX != COLUMN_INDEX && COLUMN_LAST_INDEX > -1) {
					$("tbody/tr",o).find("td:eq(" + COLUMN_LAST_INDEX + ")").removeClass(defaults.highlightClass).end();
				}
			}	
			/** if this is fired, with a straight call, sortStart / Stop would never be fired. */
			setTimeout(doSorting,0);
		}
		function doSorting() {
			/** array for storing sorted data. */
			var columns;
			/** sorting exist in cache, get it. */
			if($.tableSorter.cache.exist(COLUMN_CACHE,COLUMN_INDEX) && defaults.useCache) {
				/** get from cache */
				var cache = $.tableSorter.cache.get(COLUMN_CACHE,COLUMN_INDEX);
				/** figure out the way to sort. */
				if(cache.dir == COLUMN_DIR) {
					columns = cache.data;
					cache.dir = COLUMN_DIR;
				} else {
					columns = cache.data.reverse();
					cache.dir = COLUMN_DIR;
				}
			/** sort and cache */
			} else {		
				/** return flat data, and then sort it. */
				var flatData = $.tableSorter.data.flatten(COLUMN_DATA,COLUMN_SORTER_CACHE,COLUMN_INDEX);
				/** do sorting, only onces per column. */
				flatData.sort(COLUMN_SORTER_CACHE[COLUMN_INDEX].sorter);
				/** if we have a sortDir, reverse the damn thing. */
				if(COLUMN_LAST_DIR != COLUMN_DIR) { 
					
					flatData.reverse();
				
				}
				/** rebuild data from flat. */
				columns = $.tableSorter.data.rebuild(COLUMN_DATA,flatData,COLUMN_INDEX,COLUMN_LAST_INDEX);
				/** append to table cache. */
				$.tableSorter.cache.add(COLUMN_CACHE,COLUMN_INDEX,COLUMN_DIR,columns);
				/** good practise */
				flatData = null;
			}
			/** append to table > tbody */
			$.tableSorter.utils.appendToTable(oTable,columns,defaults,COLUMN_INDEX,COLUMN_LAST_INDEX);
			/**defaults.tableAppender(oTable,columns,defaults,COLUMN_INDEX,COLUMN_LAST_INDEX); */
			
			/** good practise i guess */
			columns = null;
			/** trigger stop event. */
			if(tableRowLength > defaults.minRowsForWaitingMsg) {
				$.event.trigger("sortStop",[COLUMN_INDEX]);
			}
			COLUMN_LAST_INDEX = COLUMN_INDEX;
			
		}
	});
};

$.fn.sortStart = function(fn) {
	return this.bind("sortStart",fn);
};
$.fn.sortStop = function(fn) {
	return this.bind("sortStop",fn);
};



$.tableSorter = {
	params: {},
	/** cache functions, okey for now. */
	cache: {
		add: function(cache,index,dir,data) {
			var oCache = {};
			oCache.dir = dir;
			oCache.data = data;
			cache[index] = oCache;
		},
		get: function (cache,index) {
			return cache[index]; 
		},
		exist: function(cache,index) {
			var oCache = cache[index];
			if(!oCache) {
				return false
			} else {
				return true
			}
		}
	},
	data: {

		flatten: function(columnData,columnCache,columnIndex) {
			var flatData = [];
			var l = columnData.length;
			for (var i=0;i < l; i++) {
				flatData.push([i,columnCache[columnIndex].format($.tableSorter.utils.getElementText(columnData[i].cells[columnIndex],'columns',columnIndex))]);
			}
			return flatData;
		},
		rebuild: function(columnData,flatData,columnIndex,columnLastIndex) {
			var l = flatData.length;
			var sortedData = [];
			for (var i=0;i < l; i++) {
				sortedData.push(columnData[flatData[i][0]]);
			}
			return sortedData;
		}
	},

	sorters: {},
	
	parsers: {},
	
	analyzer: {
	
		analyzers: [],
		add: function(analyzer) {
			this.analyzers.push(analyzer);
		},
		analyseString: function(s,params) {
			/** set defaults params. */
			$.tableSorter.utils.setParams(params);
			var l=this.analyzers.length;
			var foundAnalyzer = false;
			for(var i=0; i < l; i++) {
				
				var analyzer = this.analyzers[i];	
	
				if(analyzer.is(s)) {
					foundAnalyzer = true;
					return analyzer;
					continue;
				}
			}
			if(!foundAnalyzer) {
				return $.tableSorter.parsers.generic;
			}
		},
		getById: function(s) {
			var l=this.analyzers.length;
			for(var i=0; i < l; i++) {
				var analyzer = this.analyzers[i];	
				if(analyzer.id == s) {
					return analyzer;
					continue;
				}	
			}
		}	
	},
	utils: {
		setParams: function(o) {
			 $.tableSorter.params = o;
		},
		getParams: function() {
			return $.tableSorter.params;
		},
		getElementText: function(o,type,index) {
			
			var defaults = $.tableSorter.utils.getParams();
			var elementText = "";
			
			if(type == 'header') {
				elementText = $(o).text();	
			} else if(type == 'columns') { 
			
				if(defaults.textExtractionCustom && typeof(defaults.textExtractionCustom[index]) == "function") {
					elementText = defaults.textExtractionCustom[index](o);
				} else {
					if(defaults.textExtraction == 'simple') {	
						if(o.childNodes[0].hasChildNodes()) {
							elementText = o.childNodes[0].innerHTML;
						} else {
							elementText = o.innerHTML;
						}
						
					} else if(defaults.textExtraction == 'complex') {
						// make a jquery object, this will take forever with large tables.
						elementText = $(o).text();
					}
					
				}
				
			}
			return elementText;
		},
		appendToTable: function(o,c,defaults,index,lastIndex) {
			var l = c.length;
			$("tbody",o).empty().append(c);
			/** jquery way, need to bench mark! */
			if(defaults.stripingRowClass) {
				/** remove old! */
				$("tbody/tr",o).removeClass(defaults.stripingRowClass[0]).removeClass(defaults.stripingRowClass[1]);
				/** add new! */
				$.tableSorter.utils.stripRows(o,defaults);
			}
			if(defaults.highlightClass) {
				/**
				if(lastIndex != index && lastIndex > -1) {
					$("tbody/tr",o).find("td:eq(" + lastIndex + ")").removeClass(defaults.highlightClass).end();
				}
				*/
				$("tbody/tr",o).find("td:eq(" + index + ")").addClass(defaults.highlightClass).end();
			}
			/** empty object, good practice! */
			c=null;
		},
		stripRows: function(o,defaults) {
			$("tbody/tr:even",o).addClass(defaults.stripingRowClass[0]);
			$("tbody/tr:odd",o).addClass(defaults.stripingRowClass[1]);
		},
		isHeaderDisabled: function(o,arg,index) {
			if(typeof(arg) == "number") {
				return (arg == index)? true : false;
			} else if(typeof(arg) == "string") {
				return (arg.toLowerCase() == $.tableSorter.utils.getElementText(o,'header',index).toLowerCase()) ? true : false;
			} else if(typeof(arg) == "object") {
				var l = arg.length;
				if(!this.lastFound) { this.lastFound = -1; }
				for(var i=0; i < l; i++) {
					var val = $.tableSorter.utils.isHeaderDisabled(o,arg[i],index);
					if(this.lastFound != i && val) {
						this.lastFound = i;
						return val;
					}
				}
			} else {
				return false	
			}
		}
	},
	sorters: {
		generic: function(a,b) {
			return ((a[1] < b[1]) ? -1 : ((a[1] > b[1]) ? 1 : 0));
 		},
 		numeric: function(a,b) { 
			return a[1]-b[1];
		} 		
	}
};

$.fn.wrapInner = function(o) {
    return this.each(function(){
                 var jQ = $(this);
                 var c = jQ.html();
                 jQ.empty().append(o.element).find(o.name).html(c).addClass(o.className).end();
    });
}; 

/**
Sample code for sorting on two columns.
function sortByLastNameThenFirst(a, b) {
	var x = a.LastName.toLowerCase();
	var y = b.LastName.toLowerCase();
	return ((x < y) ? -1 : ((x > y) ? 1 : sortByFirstName(a, b)));
}

$.tableSorter.sorters.generic = function(a,b) {
	return ((a[1] < b[1]) ? -1 : ((a[1] > b[1]) ? 1 : 0));
};
$.tableSorter.sorters.numeric = function(a,b) { 
	return a[1]-b[1];
};
*/
$.tableSorter.parsers.generic = {
	id: 'generic',
	is: function(s) {
		return true;
	},
	format: function(s) {
		return s.toLowerCase();
	},
	filter: 'text',
	sorter: $.tableSorter.sorters.generic
};


$.tableSorter.parsers.currency = {
	id: 'currency',
	is: function(s) {
		return s.match(new RegExp(/^[£$]/));
	},
	format: function(s) {
		return parseFloat(s.replace(new RegExp(/[^0-9.]/g),''));
	},
	filter: 'numeric',
	sorter: $.tableSorter.sorters.numeric
};
$.tableSorter.parsers.int = {
	id: 'int',
	is: function(s) { 
		return s.match(new RegExp(/^\b\d+\d\b$/));
	},
	format: function(s) {
		return parseInt(s);
	},
	filter: 'numeric',
	sorter: $.tableSorter.sorters.numeric
};
$.tableSorter.parsers.float = {
	id: 'float',
	is: function(s) { 
		return s.match(new RegExp(/(\+|-)?[0-9]+\.[0-9]+((E|e)(\+|-)?[0-9]+)?/));
	},
	format: function(s) {
		return parseFloat(s.replace(new RegExp(/,/),''));
	},
	filter: 'numeric',
	sorter: $.tableSorter.sorters.numeric
};

$.tableSorter.parsers.ipAddress = {
	id: 'ipAddress',
	is: function(s) {
		return s.match(new RegExp(/^\d{2,3}[\.]\d{2,3}[\.]\d{2,3}[\.]\d{2,3}$/));
	},
	format: function(s) {
		var a = s.split('.');
		var r = '';
		for (var i = 0, item; item = a[i]; i++) {
		   if(item.length == 2) {
				r += '0' + item;
		   } else {
				r += item;
		   }
		}	
		return parseFloat(r);
	},
	filter: 'numeric',
	sorter: $.tableSorter.sorters.numeric
};
$.tableSorter.parsers.url = {
	id: 'url',
	is: function(s) {
		return s.match(new RegExp(/(https?|ftp|file):\/\//));
	},
	format: function(s) {
		return s.replace(new RegExp(/(https?|ftp|file):\/\//),'');
	},
	filter: 'text',
	sorter: $.tableSorter.sorters.generic
};
$.tableSorter.parsers.isoDate = {
	id: 'isoDate',
	is: function(s) {
		return s.match(new RegExp(/^\d{4}[/-]\d{1,2}[/-]\d{1,2}$/));
	},
	format: function(s) {
		return parseFloat(new Date(s.replace(new RegExp(/-/g),'/')).getTime());
	},
	filter: 'date',
	sorter: $.tableSorter.sorters.numeric
};
$.tableSorter.parsers.usLongDate = {
	id: 'usLongDate',
	is: function(s) {
		return s.match(new RegExp(/^[A-Za-z]{3,10}\.? [0-9]{1,2}, ([0-9]{4}|'?[0-9]{2}) (([0-2]?[0-9]:[0-5][0-9])|([0-1]?[0-9]:[0-5][0-9]\s(AM|PM)))$/));
	},
	format: function(s) {
		return parseFloat((new Date(s)).getTime());
	},
	filter: 'date',
	sorter: $.tableSorter.sorters.numeric
}; 
$.tableSorter.parsers.shortDate = {
	id: 'shortDate',
	is: function(s) {
		return s.match(new RegExp(/^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$/));
	},
	format: function(s) {
		s = s.replace(new RegExp(/-/g),'/');
		var defaults = $.tableSorter.utils.getParams();
		if(defaults.dateFormat == "mm/dd/yyyy" || defaults.dateFormat == "mm-dd-yyyy") {
			/** reformat the string in ISO format */
			s = s.replace(new RegExp(/(\d{1,2})[/-](\d{1,2})[/-](\d{4})/), '$3/$1/$2');
		} else if(defaults.dateFormat == "dd/mm/yyyy" || defaults.dateFormat == "dd-mm-yyyy") {
			/** reformat the string in ISO format */
			s = s.replace(new RegExp(/(\d{1,2})[/-](\d{1,2})[/-](\d{4})/), '$3/$2/$1');
		}
		return parseFloat((new Date(s)).getTime());
	},
	filter: 'date',
	sorter: $.tableSorter.sorters.numeric
};
$.tableSorter.parsers.time = {
    id: 'time',
    is: function(s) {
        return s.toUpperCase().match(new RegExp(/^(([0-2]?[0-9]:[0-5][0-9])|([0-1]?[0-9]:[0-5][0-9]\s(AM|PM)))$/));
    },
    format: function(s) {
        return parseFloat((new Date("2000/01/01 " + s)).getTime());
    },
    filter: 'date',
    sorter: $.tableSorter.sorters.numeric
}; 
$.tableSorter.parsers.checkbox = {
    id: 'input',
    is: function(s) {
        return s.toLowerCase().match(/<input[^>]*checkbox[^>]*/i);;
    },
    format: function(s) {
        var int = 0;
        if(s.toLowerCase().match(/<input[^>]*checked*/i)) {
        	int = 1;
        }
        return int;
    },
    filter: 'checkbox',
    sorter: $.tableSorter.sorters.numeric
}; 

/** add parsers */
$.tableSorter.analyzer.add($.tableSorter.parsers.currency);
$.tableSorter.analyzer.add($.tableSorter.parsers.int);
$.tableSorter.analyzer.add($.tableSorter.parsers.float);
$.tableSorter.analyzer.add($.tableSorter.parsers.isoDate);
$.tableSorter.analyzer.add($.tableSorter.parsers.shortDate);
$.tableSorter.analyzer.add($.tableSorter.parsers.usLongDate);
$.tableSorter.analyzer.add($.tableSorter.parsers.ipAddress);
$.tableSorter.analyzer.add($.tableSorter.parsers.url);
$.tableSorter.analyzer.add($.tableSorter.parsers.time);
$.tableSorter.analyzer.add($.tableSorter.parsers.checkbox);
