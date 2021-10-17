public abstract class AbstractPagingController {
    protected Integer pageSize;
    protected Integer pageIndex = 0; 
    protected Integer total;
    
    public AbstractPagingController(final Integer pageSize) {
        this.pageSize = pageSize;
    }
    
    public AbstractPagingController(final Integer pageSize, final Integer total) {
        this(pageSize);
        this.total = total;
    }
    
    public Boolean getHasNext() {
        return total - getOffset() > pageSize;
    }
    
    public Boolean getHasPrevious() {
        return pageIndex > 0;
    }
    
    public Integer getPageIndex() {
        return pageIndex;
    }
    
    public Integer getTotal() {
        return total;
    }
    
    public void setTotal(final Integer total) {
        this.total = total;
    }
    
    public Integer getPages() {
        final Integer remainder = Math.mod(total, pageSize);
        return (total / pageSize) + (remainder > 0 ? 1 : 0);
    }
    
    public Integer getOffset() {
        return this.pageSize * this.pageIndex;
    }
    
    protected abstract List<SObject> getRecords();
    
    public void next() {
        if(getHasNext()) {
            pageIndex =  this.pageIndex + 1;
        }
    }

    public void previous() {
        pageIndex = Math.max(this.pageIndex - 1, 0);
    }
}