public class JsonApi {

    public static FieldMapConfig parseList() {
        return new ListParser();
    }

    public static FieldMapConfig parseFields() {
        return new FieldMapParser();
    }

    public static WithSingleField parseField(final String fieldName, final Type fieldType) {
        return new SingleFieldParser(fieldName, fieldType);
    }

    public static Parser typeParser(final Type type) {
        return new TypeParser(type);
    }

    public interface Parser {

        Object parse(String jsonString);
    }

    public interface WithSingleField {

        Parser parser();

        WithSingleField required();

    }

    public interface FieldMapConfig {

        WithField field(String fieldName, Type fieldType);

    }

    public interface WithField extends FieldMapConfig {

        Parser parser();

        WithField required();

        WithField required(Boolean required);

        WithField requiredValue(Object fieldValue);

    }

    public class TypeParser implements Parser {
        private final Type type;

        private TypeParser(final Type type) {
            this.type = type;
        }

        public Object parse(String jsonString) {
            return JSON.deserialize(jsonString, type);
        }
    }

    public class SingleFieldParser implements WithSingleField, Parser {
        private final WithField withField;
        private final String fieldName;

        private SingleFieldParser(final String fieldName, final Type fieldType) {
            this.withField = JsonApi.parseFields().field(fieldName, fieldType);
            this.fieldName = fieldName;
        }

        public WithSingleField required() {
            withField.required();
            return this;
        }

        public Parser parser() {
            return this;
        }

        public Object parse(final String jsonString) {
            final Map<String, Object> fieldMap = (Map<String, Object>)withField.parser().parse(jsonString);
            return fieldMap.get(fieldName);
        }
    }

    public virtual class FieldMapParser implements WithField, Parser {
        private Map<String, Field> fieldTypeMap = new Map<String, Field>();
        private Field currentField;

        private FieldMapParser() {
        }

        public WithField field(final String fieldName, final Type fieldType) {
            final Field field = new Field(fieldName, fieldType);
            this.currentField = field;
            fieldTypeMap.put(fieldName, field);
            return this;
        }

        public WithField required() {
            return required(true);
        }

        public WithField required(final Boolean required) {
            this.currentField.setRequired(required);
            return this;
        }

        public WithField requiredValue(final Object fieldValue) {
            required();
            this.currentField.setRequiredValue(fieldValue);
            return this;
        }

        public Parser parser() {
            return this;
        }

        public virtual Object parse(final String jsonString) {
            final Map<String, Object> valueMap = new Map<String, Object>();
            final JSONParser parser = JSON.createParser(jsonString);
            if (parser.nextToken() != null) {
                System.assertEquals(JSONToken.START_OBJECT, parser.getCurrentToken(), 'Invalid object json.');
            }
            while (parser.nextToken() != null) {
                final JSONToken currentToken = parser.getCurrentToken();
                if (currentToken == JSONToken.FIELD_NAME) {
                    parseFieldValue(parser, valueMap);
                } else if (currentToken == JSONToken.START_ARRAY || currentToken == JSONToken.START_OBJECT) {
                    parser.skipChildren();
                }
            }
            return valueMap;
        }

        protected void parseFieldValue(final JSONParser parser, final Map<String, Object> valueMap) {
            final String fieldName = parser.getText();
            final Field field = fieldTypeMap.get(fieldName);
            if (field != null) {
                parser.nextToken();
                final Object fieldValue = parser.readValueAs(field.getFieldType());
                if(field.getRequired() && fieldValue == null) {
                    throw new JsonApiException(fieldName + ' required field not found');
                }
                if(field.getRequiredValue() != null && field.getRequiredValue() != fieldValue) {
                    throw new JsonApiException(fieldName + ' can not be ' + fieldValue);
                }
                valueMap.put(fieldName, fieldValue);
            }
        }
    }

    public class ListParser extends FieldMapParser {

        private ListParser() {
        }

        public override Object parse(final String jsonString) {
            final JSONParser parser = JSON.createParser(jsonString);
            if (parser.nextToken() != null) {
                System.assertEquals(JSONToken.START_ARRAY, parser.getCurrentToken(), 'Invalid object json.');
            }

            final List<Map<String, Object>> valueMapList = new List<Map<String, Object>>();
            Map<String, Object> valueMap = null;

            while (parser.nextToken() != null) {
                final JSONToken currentToken = parser.getCurrentToken();
                if (currentToken == JSONToken.START_OBJECT) {
                    if (valueMap == null) {
                        valueMap = new Map<String, Object>();
                    } else {
                        parser.skipChildren();
                    }
                } else if (currentToken == JSONToken.FIELD_NAME) {
                    parseFieldValue(parser, valueMap);
                } else if (currentToken == JSONToken.START_ARRAY) {
                    parser.skipChildren();
                } else if (currentToken == JSONToken.END_OBJECT) {
                    valueMapList.add(valueMap);
                    valueMap = null;
                }
            }
            return valueMapList;
        }
    }

    public class Field {
        private final String fieldName;
        private final Type fieldType;
        private boolean required = false;
        private Object requiredValue;

        private Field(final String fieldName, final Type fieldType) {
            this.fieldName = fieldName;
            this.fieldType = fieldType;
        }

        public String getFieldName() {
            return fieldName;
        }

        public Type getFieldType() {
            return fieldType;
        }

        public boolean getRequired() {
            return required;
        }

        public void setRequired(final boolean required) {
            this.required = required;
        }

        public Object getRequiredValue() {
            return requiredValue;
        }

        public void setRequiredValue(final Object requiredValue) {
            this.requiredValue = requiredValue;
        }
    }

    public class JsonApiException extends Exception {
    }
}