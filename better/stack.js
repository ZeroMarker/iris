// Create a new Error object
var err = new Error();

// Capture the stack trace
var stackTrace = err.stack;

// Print or process the stack trace as needed
// console.log(stackTrace);
const regex = /scripts\/.*\.js/g;
stackTrace = stackTrace.match(regex);
stackTrace = stackTrace.join(',');

