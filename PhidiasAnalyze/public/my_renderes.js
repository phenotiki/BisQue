/*******************************************************************************

  BQ.renderers.multiroot.Image

  Author: Dima Fedorov

  Version: 1
  
  History: 
    2011-09-29 13:57:30 - first creation
    
*******************************************************************************/


// overwrite standard renderer with our own
BQ.renderers.resources.image = 'BQ.renderers.multiroot.Image';

// provide our renderer
Ext.define('BQ.renderers.multiroot.Image', {
    extend: 'BQ.renderers.Image',

    onerror: function (e) {
        this.setLoading(false);
        BQ.ui.error(e.message);  
    }, 

    fetchRoots : function(f) {
        this.setLoading('Analysing outputs');

        var url = this.gobjects[1].uri;
        var xpath = '//gobject/gobject[@name]|/*/gobject/gobject[@name]';
        var xmap = 'gobject-name';
        var xreduce = 'vector';
    
        this.accessor = new BQStatisticsAccessor( url, xpath, xmap, xreduce, 
                                                  { 'ondone': callback(this, f), 
                                                    'onerror': callback(this, "onerror"), 
                                                    root: this.root, } );
    },
    
    doPlotArea : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }
        var xpath = [];
        var titles = [];		  
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="area"]' );
            titles.push( results[0].vector[i] );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var url     = this.gobjects[1].uri;
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var title   = 'Areas';
        
        var opts = { title: 'Plant Area (t)', height:500, titles: titles };
        this.plotter = Ext.create('BQ.stats.Dialog', {
            url     : url,
            xpath   : xpath,
            xmap    : xmap,
            xreduce : xreduce,
            title   : title,
            root    : this.root,
            opts    : { titles: titles, },
        });          
    },    

    getPlotArea : function() {
        if (this.accessor) 
            this.doPlotArea(this.accessor.results);
        else
            this.fetchRoots('doPlotArea');
    },

    doPlotDiam : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }
        var xpath = [];
        var titles = [];		  
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="diameter"]' );
            titles.push( results[0].vector[i] );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var url     = this.gobjects[1].uri;
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var title   = 'Diameters';
        
        var opts = { title: 'Plant Diameters (t)', height:500, titles: titles };
        this.plotter = Ext.create('BQ.stats.Dialog', {
            url     : url,
            xpath   : xpath,
            xmap    : xmap,
            xreduce : xreduce,
            title   : title,
            root    : this.root,
            opts    : { titles: titles, },
        });          
    },    

    getPlotDiam : function() {
        if (this.accessor) 
            this.doPlotDiam(this.accessor.results);
        else
            this.fetchRoots('doPlotDiam');
    },	

    createMenuPlot : function(menu) {
        menu.add({
            text: 'Areas',
            scope: this,
            handler: this.getPlotArea,
        }); 
	  menu.add({
            text: 'Diameters',
            scope: this,
            handler: this.getPlotDiam,
        });
  	  menu.add({
            text: 'Perimeters',
            scope: this,
            handler: this.getPlotPerim,
        }); 
	  menu.add({
            text: 'Stockinesses',
            scope: this,
            handler: this.getPlotStock,
        });
	  menu.add({
            text: 'Compactiness',
            scope: this,
            handler: this.getPlotCompact,
        });
    },

    doPlotPerim : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }
        var xpath = [];
        var titles = [];		  
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="perimeter"]' );
            titles.push( results[0].vector[i] );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var url     = this.gobjects[1].uri;
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var title   = 'Perimeters';
        
        var opts = { title: 'Plant Perimeter (t)', height:500, titles: titles };
        this.plotter = Ext.create('BQ.stats.Dialog', {
            url     : url,
            xpath   : xpath,
            xmap    : xmap,
            xreduce : xreduce,
            title   : title,
            root    : this.root,
            opts    : { titles: titles, },
        });          
    },    

    getPlotPerim : function() {
        if (this.accessor) 
            this.doPlotArea(this.accessor.results);
        else
            this.fetchRoots('doPlotPerim');
    },

    doPlotStock : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }
        var xpath = [];
        var titles = [];		  
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="stockiness"]' );
            titles.push( results[0].vector[i] );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var url     = this.gobjects[1].uri;
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var title   = 'Stockiness';
        
        var opts = { title: 'Plant Stockiness (t)', height:500, titles: titles };
        this.plotter = Ext.create('BQ.stats.Dialog', {
            url     : url,
            xpath   : xpath,
            xmap    : xmap,
            xreduce : xreduce,
            title   : title,
            root    : this.root,
            opts    : { titles: titles, },
        });          
    },    

    getPlotStock : function() {
        if (this.accessor) 
            this.doPlotStock(this.accessor.results);
        else
            this.fetchRoots('doPlotStock');
    },

    doPlotCompact : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }
        var xpath = [];
        var titles = [];		  
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="compactiness"]' );
            titles.push( results[0].vector[i] );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var url     = this.gobjects[1].uri;
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var title   = 'Compactiness';
        
        var opts = { title: 'Plant Compactiness (t)', height:500, titles: titles };
        this.plotter = Ext.create('BQ.stats.Dialog', {
            url     : url,
            xpath   : xpath,
            xmap    : xmap,
            xreduce : xreduce,
            title   : title,
            root    : this.root,
            opts    : { titles: titles, },
        });          
    },    

    getPlotCompact : function() {
        if (this.accessor) 
            this.doPlotCompact(this.accessor.results);
        else
            this.fetchRoots('doPlotCompact');
    },		 
    	

    doCSVArea : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }                
        var xpath = [];
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="area"]' );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var url = '/stats/csv?url=' + this.gobjects[1].uri;
        if (this.root) url = this.root + url;        
        url += createArgs('xpath', xpath);
        url += createArgs('xmap', xmap);
        url += createArgs('xreduce', xreduce);                                        
        window.open(url);                
    },    

    getCSVArea : function() {
        if (this.accessor) 
            this.doCSV(this.accessor.results);
        else
            this.fetchRoots('doCSVArea');
    },

    doCSVDiam : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }                
        var xpath = [];
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="diameter"]' );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var url = '/stats/csv?url=' + this.gobjects[1].uri;
        if (this.root) url = this.root + url;        
        url += createArgs('xpath', xpath);
        url += createArgs('xmap', xmap);
        url += createArgs('xreduce', xreduce);                                        
        window.open(url);                
    },    

    getCSVDiam : function() {
        if (this.accessor) 
            this.doCSVDiam(this.accessor.results);
        else
            this.fetchRoots('doCSVDiam');
    },

	doCSVPerim : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }                
        var xpath = [];
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="perimeter"]' );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var url = '/stats/csv?url=' + this.gobjects[1].uri;
        if (this.root) url = this.root + url;        
        url += createArgs('xpath', xpath);
        url += createArgs('xmap', xmap);
        url += createArgs('xreduce', xreduce);                                        
        window.open(url);                
    },    

    getCSVPerim : function() {
        if (this.accessor) 
            this.doCSV(this.accessor.results);
        else
            this.fetchRoots('doCSVPerim');
    },

    doCSVStock : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }                
        var xpath = [];
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="stockiness"]' );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var url = '/stats/csv?url=' + this.gobjects[1].uri;
        if (this.root) url = this.root + url;        
        url += createArgs('xpath', xpath);
        url += createArgs('xmap', xmap);
        url += createArgs('xreduce', xreduce);                                        
        window.open(url);                
    },    

    getCSVStock : function() {
        if (this.accessor) 
            this.doCSV(this.accessor.results);
        else
            this.fetchRoots('doCSVStock');
    },

    doCSVCompact : function(results) {
        this.setLoading(false);
        if (!results || results.length<1) {
            BQ.ui.warning('Statistics service did not return any results');
            this.accessor = undefined;
            return;
        }                
        var xpath = [];
        for (var i=0; i<results[0].vector.length; i++) {
            if (!results[0].vector[i] || results[0].vector[i]=='') continue;
            if (!results[0].vector[i].indexOf("Plant-")==0) continue;
		xpath.push( '//gobject[@name="'+results[0].vector[i]+'"]//tag[@name="compactness"]' );
        }
        if (xpath.length<=0) {
            BQ.ui.error('Hm, no objects found...');
            return;  
        }
        
        var xmap    = 'tag-value-number';
        var xreduce = 'vector';
        var url = '/stats/csv?url=' + this.gobjects[1].uri;
        if (this.root) url = this.root + url;        
        url += createArgs('xpath', xpath);
        url += createArgs('xmap', xmap);
        url += createArgs('xreduce', xreduce);                                        
        window.open(url);                
    },    

    getCSVCompact : function() {
        if (this.accessor) 
            this.doCSV(this.accessor.results);
        else
            this.fetchRoots('doCSVCompact');
    },

    createMenuExportCsv : function(menu) {
        menu.add({
            text: 'Areas as CSV',
            scope: this,
            handler: this.getCSVArea,
        });
	  menu.add({
            text: 'Diameters as CSV',
            scope: this,
            handler: this.getCSVDiam,
        });
	  menu.add({
            text: 'Perimeters as CSV',
            scope: this,
            handler: this.getCSVPerim,
        });
	  menu.add({
            text: 'Stockiness as CSV',
            scope: this,
            handler: this.getCSVStock,
        });
	  menu.add({
            text: 'Compactness as CSV',
            scope: this,
            handler: this.getCSVCompact,
        });   
    }, 

});


