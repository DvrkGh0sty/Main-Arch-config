#include <iostream>
using namespace std;

int main(){
    int grades[5] = {1, 2, 3, 4, 5};
    int len = sizeof(grades)/sizeof(grades[0]);

    cout << len;

    return 0;
}