createDocument = """
Write a proper explanation document with description and explain the functionality of the code with each function and keyword for this code {topic}
write in this format
# code Explanation

## Description:
This document provides a comprehensive explanation of the code related to code. It outlines the functionality, use cases, working principles, and detailed explanations of each function and keyword utilized in the code.

## Usecases:
The code serves the following use cases:
- Use case 1: [Brief description of the first use case]
- Use case 2: [Brief description of the second use case]
- Use case 3: [Brief description of the third use case]
- ...

## Working:
The code operates based on the following working principles:
1. [Explanation of the first working principle]
2. [Explanation of the second working principle]
3. [Explanation of the third working principle]
   ...

## Each Function Explanation:
1. Function 1:
   - Purpose: [Brief description of the purpose of the function]
   - Parameters: [Description of the input parameters and their usage]
   - Return Value: [Description of the value returned by the function]
   - Example Usage: [Example code demonstrating how to use the function]

2. Function 2:
   - Purpose: [Brief description of the purpose of the function]
   - Parameters: [Description of the input parameters and their usage]
   - Return Value: [Description of the value returned by the function]
   - Example Usage: [Example code demonstrating how to use the function]
...
"""


createTest = """
Write unit test cases using the Chai assertion library in TypeScript for the Hardhat framework. Create test cases for all functions Include both negative and positive cases for this code : {topic}. 
"""


createIntegration = """
Write contract integration function in a web3 and typescript without ABIs for backend and frontend integration. along with a require error statement. The code should pertain to the topic: {topic}.
"""

