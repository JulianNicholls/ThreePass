# Three pass compiler

This comes from a [1 Kyu Codewars Kata](https://www.codewars.com/kata/5265b0885fda8eac5900093b)

You are writing a three-pass compiler for a simple programming language into 
a small assembly language.

## The programming language has this syntax:
```lex
    function   ::= '[' arg-list ']' expression

    arg-list   ::= /* nothing */
                 | arg-name arg-list

    expression ::= term
                 | expression '+' term
                 | expression '-' term

    term       ::= factor
                 | term '*' factor
                 | term '/' factor

    factor     ::= number
                 | variable
                 | '(' expression ')'
```
Variables are strings of alphabetic characters. Numbers are strings of 
decimal digits representing integers. So, for example, a function which 
computes a^2 + b^2 might look like:
```js
    [ a b ] a*a + b*b
```
A function which computes the average of two numbers might look like:
```js
    [ first second ] (first + second) / 2
```
You need write a three-pass compiler. All test cases will be valid programs, 
so you needn't concentrate on error-handling.

The first pass will be the method pass1 which takes a string representing a 
function in the original programming language and will return a JSON object 
that represents that Abstract Syntax Tree. The Abstract Syntax Tree must 
use the following representations:
```js
    { 'op': '+', 'a': a, 'b': b }    // add subtree a to subtree b
    { 'op': '-', 'a': a, 'b': b }    // subtract subtree b from subtree a
    { 'op': '*', 'a': a, 'b': b }    // multiply subtree a by subtree b
    { 'op': '/', 'a': a, 'b': b }    // divide subtree a from subtree b
    { 'op': 'arg', 'n': n }          // reference to n-th argument, n integer
    { 'op': 'imm', 'n': n }          // immediate value n, n integer
```
Note: arguments are indexed from zero. So, for example, the function 
[ xx yy ] ( xx + yy ) / 2 would look like:
```js
    { 'op': '/', 'a': { 'op': '+', 'a': { 'op': 'arg', 'n': 0 },
                                   'b': { 'op': 'arg', 'n': 1 } },
                 'b': { 'op': 'imm', 'n': 2 } }
```
The second pass of the compiler will be called pass2. This pass will take the 
output from pass1 and return a new Abstract Syntax Tree (with the same format)
with all constant expressions reduced as much as possible. 

So, if for example, the function is [ x ] x + 2*5, the result of pass1 would be:
```js
    { 'op': '+', 'a': { 'op': 'arg', 'n': 0 },
                 'b': { 'op': '*', 'a': { 'op': 'imm', 'n': 2 },
                                   'b': { 'op': 'imm', 'n': 5 } } }
```
This would be passed into pass2 which would return:
```js
    { 'op': '+', 'a': { 'op': 'arg', 'n': 0 },
                 'b': { 'op': 'imm', 'n': 10 } }
```
The third pass of the compiler is pass3. The pass3 method takes in an Abstract 
Syntax Tree and returns an array of strings. Each string is an assembly 
directive. You are working on a small processor with two registers (R0 and R1),
a stack, and an array of input arguments. 

The result of a function is expected to be in R0. The processor supports the 
following instructions:
```assembly
    "LD.I n"     // load the constant value n into R0
    "LD.M n"     // load the n-th input argument into R0
    "SWAP"       // swap R0 and R1
    "PUSH"       // push R0 onto the stack
    "POP"        // pop the top value off of the stack into R0
    "ADD"        // add R1 to R0 and put the result in R0
    "SUB"        // subtract R1 from R0 and put the result in R0
    "MUL"        // multiply R0 by R1 and put the result in R0
    "DIV"        // divide R0 by R1 and put the result in R0
```
So, one possible return value from pass3 given the Abstract Syntax Tree shown 
above from pass2 is:
```js
    [ "LD.I 10", "SWAP", "LD.M 0", "ADD" ]
```
# Solutions

`solution.js` directly solves the Codewars kata.

`compiler.rb` solves the same problem, but with a slightly different assembly language. The Ruby solution has not been
run on the Codewars site.
