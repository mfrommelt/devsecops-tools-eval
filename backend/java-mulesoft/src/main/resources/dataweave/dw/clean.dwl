%dw 2.0
output application/json
var stringVar = "hello"
var numberVar = 42
var arrayVar = [1, 2, 3]
---
{
    // Basic variables
    string: stringVar,
    number: numberVar,
    array: arrayVar,
    
    // Basic math
    addition: numberVar + 10,
    multiplication: numberVar * 2,
    
    // Basic array access
    firstItem: arrayVar[0],
    lastItem: arrayVar[2],
    
    // Basic conditionals
    comparison: if (numberVar > 40) "big" else "small",
    
    // Basic string operations using array syntax
    firstChar: stringVar[0],
    
    // Basic object construction
    nested: {
        value1: "test",
        value2: 123
    }
}