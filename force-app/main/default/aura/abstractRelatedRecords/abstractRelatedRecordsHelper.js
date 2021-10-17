({  
    sortBy: function(field, reverse, primer) {
        const key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

    handleSortData: function(component, event, fieldName, direction) {
        const cloneData = component.get('v.data').slice(0);
        cloneData.sort((this.sortBy(fieldName, direction === 'asc' ? 1 : -1)));
        
        component.set('v.data', cloneData);
        component.set('v.sortDirection', direction);
        component.set('v.sortedBy', fieldName);
    },
    
    renderPageData: function(component) {
        const records = component.get("v.returnData"),
            pageNumber = component.get("v.pageNumber"),
            pageRecords = records.slice((pageNumber-1)*10, pageNumber*10);
        component.set("v.data", pageRecords);
    },    
})