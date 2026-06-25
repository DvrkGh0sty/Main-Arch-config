//TODO:
//

#include <iostream>
using namespace std;


//make refrence to the functions declared below
float add(float num1, float num2);
float subtract(float num1, float num2);
float multiply(float num1, float num2);
float divide(float num1, float num2);

int main()
{
    cout << "Welcome to v1 calculator" << endl;

    //variables
    float num1, num2;
    float result;
    char op;

    //input and output
    cout << "> ";
    cin >> num1;
    cout << "> ";
    cin >> num2;
    cout << "operation: ";
    cin >> op;

    //declarative if statements
    if(op=='+'){
        result = add(num1, num2);
    } else if(op=='-'){
        result = subtract(num1, num2); 
    } else if(op=='*'){
        result = multiply(num1, num2);
    } else if(op=='/'){
        result = divide(num1, num2);
    } else {
        cout << "placeholder" << endl;
    }


    float values[2] = {num1, num2};
    cout << values[0] << ", " << values[1] << endl;

    //output the results
    cout << "Results: " << result << endl;
    return 0;
}


//the functions (still don't know the difference between void function and normla :/ )
float add(float num1, float num2){
    return num1 + num2;
}
float subtract(float num1, float num2){
    return num1 - num2;
}
float divide(float num1, float num2){
    if(num2 == 0){
        cout << "Error, cannot divide by zero" << endl;
        return 0;
    } else {
        return num1/num2;
    }
}
float multiply(float num1, float num2){
    return num1*num2;
}
