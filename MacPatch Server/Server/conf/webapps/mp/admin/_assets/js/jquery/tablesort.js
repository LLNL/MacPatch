/* (c) gosha bine, 2007 | www.tagarga.com/blok */

var TableSort =
{
	css: ['sortable', 'sorted_asc', 'sorted_desc'],
	compare: {
		alpha: function(a, b) {
			return a > b ? 1 : a < b ? -1 : 0;
		},
		nocase: function(a, b) {
			return TableSort.compare.alpha(a.toLowerCase(), b.toLowerCase());
		},
		numeric: function(a, b) {
			return (Number(a) || 0) - (Number(b) || 0);
		},
		natural: function(a, b) {
			function prepare(s) {
				var q = [];
				s.replace(/(\D)|(\d+)/g, function($0, $1, $2) {
					q.push($1 ? 1 : 2);
					q.push($1 ? $1.charCodeAt(0) : Number($2) + 1)
				});
				q.push(0);
				return q;
			}
			var aa = prepare(a), bb = prepare(b), i = 0;
			do {
				if(aa[i] != bb[i])
					return aa[i] - bb[i];
			} while(aa[i++] > 0);
			return 0;
		},
		currencyValue: function(s) {
			// -$1.234,56 or -1.234,56$
			var m = '';
			s = s.replace(/\./g, '').replace(/,/g, '.');
			if(m = s.match(/^(-?)\D(\d+(\.\d+)?)$/)) {
				return parseFloat(m[1] + m[2]);
			}
			if(m = s.match(/^(-?\d+(\.\d+)?)\D$/))
				return parseFloat(m[1]);
			return parseFloat('NaN');
		},
		currency: function(a, b) {
			return (TableSort.compare.currencyValue(a) || 0) -
				(TableSort.compare.currencyValue(b) || 0);
		},
		date: function(a, b) {
			return Date.parse(a) - Date.parse(b);
		},
		eudate: function(a, b) {
			a = a.split(/\D+/);
			b = b.split(/\D+/);
			return (a[2] - b[2]) || (a[1] - b[1]) || (a[0] - b[0]);
		},
		usdate: function(a, b) {
			a = a.split(/\D+/);
			b = b.split(/\D+/);
			return (a[2] - b[2]) || (a[0] - b[0]) || (a[1] - b[1]);
		}
	},
	enable: function(table, column, compare, preserveHandlers) {
		if(!document.getElementById || ![].push)
			return;
		if(!table) return TableSort.each(
			document.getElementsByTagName('TABLE'),
			function(t) { TableSort.enable(t, column, compare, preserveHandlers) }
		);
		var table = TableSort.$(table);
		if(!table || !table.tHead)
			return;
		var col = TableSort.getColumnNumber(table, column);
		TableSort.first(TableSort.headCells(table), function(td, c) {
			if(col < 0 || col == c) {
				if(!preserveHandlers || !td.onclick) {
					var cmp = compare || TableSort.guessSortRule(table, c);
					td.onclick = function(e) { TableSort.onclick(e, cmp); }
				}
				TableSort.addClass(td, TableSort.css[0]);
			}
			return col == c;
		});
	},
	sort: function(table, column, compare) {
		var table = TableSort.$(table);
		if(!table)
			return;
		var col = TableSort.getColumnNumber(table, column);
		var tbody = table.tBodies[0];
		var rows = [];
		TableSort.each(tbody.rows, function(tr) {
			rows.push({
				text: TableSort.getText(tr.cells[col]), 
				td: tr.cells[col],
				tr: tr
			});
		});
		compare = compare || TableSort.guessSortRule(table, col);
		if(typeof compare == 'string')
			compare = TableSort.compare[compare];
		rows.sort(function(a, b) {
			return compare(a.text + '', b.text + '', a.td, b.td);
		});
		var ths = TableSort.headCells(table);
		var isAsc = TableSort.hasClass(ths[col], TableSort.css[1]);
		TableSort.each(ths, function(td, c) {
			TableSort.removeClass(td, TableSort.css[1] + '|' + TableSort.css[2]);
			if(c == col)
				TableSort.addClass(td, TableSort.css[isAsc ? 2 : 1]);
		});
		if(isAsc)
			rows.reverse();
		TableSort.each(rows, function(row) {
			tbody.appendChild(row.tr);
		});
	},
	onclick: function(event, compare) {
		event = event || window.event;
		var elem = event.srcElement || event.target;
		var column = 0;
		while(elem) {
			var tag = (elem.tagName || '').toUpperCase();
			if(tag == 'TD') column = elem.cellIndex + 1;
			if(tag == 'TABLE') return TableSort.sort(elem, column, compare);
			elem = elem.parentNode;
		}
	},
	guessSortRule: function(table, col) {
		var rows = table.tBodies[0].rows;
		for(var i = 0; i < rows.length; i++) {
			var text = TableSort.getText(rows[i].cells[col]);
			if(text.length) return TableSort.guessFormat(text);
		}
		return 'nocase';
	},
	guessFormat: function(text) {
		if(!isNaN(Number(text)))
			return 'numeric';
		if(text.match(/^\d{2}[\/-]\d{2}[\/-]\d{2,4}$/))
			return 'usdate';
		if(text.match(/^\d\d?\.\d\d?\.\d{2,4}$/))
			return 'eudate';
		if(!isNaN(Date.parse(text)))
			return 'date';
		if(!isNaN(TableSort.compare.currencyValue(text)))
			return 'currency';
		if(text.match(/^[a-z_]+\d+(\.\w+)$/))
			return 'natural';
		return 'nocase';
	},
	getColumnNumber: function(table, column) {
		if(!column)
			return -1;
		if(parseInt(column) > 0)
			return column - 1;
		column = column.toString().toUpperCase();
		return TableSort.first(TableSort.headCells(table), function(td) {
			return TableSort.getText(td).toUpperCase() === column;
		});
	},
	getText: function(elem) {
		var t = elem.textContent || elem.innerText || elem.innerHTML.replace(/\<[^<>]+>/g, '');
		return t.replace(/^\s+/, '').replace(/\s+$/, '');
	},
	headCells: function(table) {
		var th = table.tHead;
		return th ? th.rows[th.rows.length - 1].cells : [];
	},
	addClass: function(elem, className) {
		TableSort.removeClass(elem, className);
		elem.className = (elem.className || '') + ' ' + className;
	},
	removeClass: function(elem, className) {
		elem.className = (elem.className || '').replace(TableSort.wordPattern(className), '');
	},
	hasClass: function(elem, className) {
		return (elem.className || '').match(TableSort.wordPattern(className), '');
	},
	regexCache: {},
	wordPattern: function(s) {
		return TableSort.regexCache[s] ||
			(TableSort.regexCache[s] =  new RegExp('\\b(' + s + ')\\b', 'g'));
	},
	$: function(s) {
		return (typeof s == 'string') ? document.getElementById(s) : s;
	},
	each: function(coll, func) {
		for(var i = 0; i < coll.length; i++)
			func(coll[i], i);
	},
	first: function(coll, func) {
		for(var i = 0; i < coll.length; i++)
			if(func(coll[i], i)) return i;
		return -1;
	}
}

if(typeof TableSortNoAutoStart == 'undefined' || !TableSortNoAutoStart) {
	TableSortInit = function() { TableSort.enable(null, null, null, true); }
	if(window.addEventListener)
		window.addEventListener('load', TableSortInit, false);
	if(window.attachEvent)
		window.attachEvent('onload', TableSortInit);
}
