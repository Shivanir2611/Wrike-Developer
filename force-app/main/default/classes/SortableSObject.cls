/**
 * Created by andrey.kuleshov on 11/07/2018.
 */
public class SortableSObject implements Comparable {
    private final sObject record;
    private final SObjectField sortingField;
    private final Boolean descSorting;

    public SortableSObject(final sObject record, final SObjectField sortingField, final Boolean descSorting) {
        this.record = record;
        this.sortingField = sortingField;
        this.descSorting = descSorting;
    }

    public sObject getRecord() {
        return record;
    }

    public Integer compareTo(final Object other) {
        if(other == null) {
            return 1;
        }
        final Integer result = compare(this.record, ((SortableSObject)other).getRecord());
        return descSorting ? result*(-1) : result;
    }

    private Integer compare(final sObject first, final sObject second) {
        final SOAPType type = sortingField.getDescribe().getSOAPType();
        final Object firstValue = first.get(sortingField);
        final Object secondValue = second.get(sortingField);
        if(firstValue == null && secondValue == null ) {
            return 0;
        }
        if(firstValue == null) {
            return -1;
        }
        if(secondValue == null) {
            return 1;
        }
        if(firstValue.equals(secondValue)) {
            return 0;
        }
        if(type == SOAPType.String) {
            return ((String)firstValue).toUpperCase().compareTo(((String)secondValue).toUpperCase());
        } else if(type == SOAPType.Double || type == SOAPType.Integer) {
            return ((Decimal)firstValue) > ((Decimal)secondValue) ? 1 : -1;
        } else if(type == SOAPType.Boolean) {
            return ((Boolean)firstValue) ? 1 : -1;
        } else if(type == SOAPType.DateTime) {
            return ((DateTime)firstValue).millisecond()  > ((DateTime)secondValue).millisecond() ? 1 : -1;
        } else if(type == SOAPType.Date) {
            return ((Date)firstValue).daysBetween((Date)secondValue);
        }
        return 0;
    }
}