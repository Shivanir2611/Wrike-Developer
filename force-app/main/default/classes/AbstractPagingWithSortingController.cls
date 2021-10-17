/**
 * Created by andrey.kuleshov on 12/07/2018.
 */
public abstract class AbstractPagingWithSortingController extends AbstractPagingController {
	private final sObjectType objectType;
	protected SObjectField sortingField;
	protected Boolean descSorting;

	public AbstractPagingWithSortingController(final sObjectType objectType, final Integer pageSize) {
		super(pageSize);
		this.objectType = objectType;
	}

	public AbstractPagingWithSortingController(final sObjectType objectType,
											   final Integer pageSize,
											   final SObjectField sortingField,
											   final Boolean descSorting) {
		this(objectType, pageSize);
		this.sortingField = sortingField;
		this.descSorting = descSorting;
	}

	protected List<SObject> getSortedRecords(final List<sObject> objects) {
		final List<SortableSObject> sortableContacts = new List<SortableSObject>();
		for(sObject obj : objects) {
			sortableContacts.add(new SortableSObject(obj, sortingField, descSorting));
		}
		sortableContacts.sort();
		final List<sObject> result = new List<sObject>();
		final Integer offset = getOffset();
		for(Integer i = 0; i < sortableContacts.size(); i++) {
			if(i >= offset && result.size() < pageSize) {
				result.add(sortableContacts.get(i).getRecord());
			}
		}
		return result;
	}

	public String getSortingFieldName() {
		return sortingField != null ? sortingField.getDescribe().getName() : null;
	}

	public Boolean getDescSorting() {
		return descSorting;
	}

	public void sort() {
		final String fieldName = System.currentPageReference().getParameters().get('fieldName');
		this.sortingField = objectType.getDescribe().fields.getMap().get(fieldName);
		this.descSorting = (this.descSorting == false) ? true : false;
	}
}