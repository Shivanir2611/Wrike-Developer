public class DateTimeController {
    public DateTime dateTimeValue { get; set; }
    
    public String getFormattedValue() {
        return dateTimeValue != null ? dateTimeValue.format('MM/dd/yyyy hh:mm a') : '';
    }
}