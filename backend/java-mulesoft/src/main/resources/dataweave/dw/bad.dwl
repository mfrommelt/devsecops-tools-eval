%dw 2.0
output application/json
var validVar = "I am valid"
ns soap http://schemas.xmlsoap.org/soap/envelope/
---
{
    // ERROR 1: Undefined variable reference
    undefinedVariable: someUndefinedVar,
    
    // ERROR 2: Undefined function
    badFunction: unknownFunction("test"),
    
    // ERROR 3: Type mismatch - trying to use string function on number
    typeError: upper(123),
    
    // ERROR 4: Invalid operator usage
    invalidOperation: "string" + true,
    
    // ERROR 5: Missing required function parameter
    missingParam: substring("hello"),
    
    // ERROR 6: Invalid array access
    badArrayAccess: [1,2,3][10].something,
    
    // ERROR 7: Invalid object access
    badObjectAccess: {}.nonExistentField.nested,
    
    // ERROR 8: Syntax error - unclosed parenthesis (comment out to test other errors)
    // syntaxError: upper("test"
    
    // ERROR 9: Invalid namespace usage (in XML context)
    badNamespace: {
        invalidNs#element: "value"
    },
    
    // ERROR 10: Type coercion error
    coercionError: "not a number" as Number,
    
    // ERROR 11: Invalid regex
    badRegex: "test" matches /[unclosed,
    
    // ERROR 12: Division by zero
    divisionByZero: 10 / 0,
    
    // ERROR 13: Invalid date format
    badDate: "not-a-date" as Date,
    
    // ERROR 14: Missing comma in object
    missingComma: "valid"
    anotherField: "this will cause error",
    
    // ERROR 15: Invalid variable scope reference
    scopeError: vars.nonExistentVariable,
    
    // Valid field for comparison
    validField: validVar
}