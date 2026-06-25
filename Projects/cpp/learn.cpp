#include <iostream>
using namespace std;

void guess_num(int guess, int secret);

int main()
{
    int secret = 45;
    int guess;
    bool isCorrect = false;

    cout << "Welcome to the number guesser" << endl;

    while(guess != secret){
        cout << "Enter your guess: ";
        cin >> guess;

        guess_num(guess, secret);

        if(guess == secret){
            cout << "Well, Done!" << endl;
        }
    }

    return 0;
}

void guess_num(int guess, int secret){
    if(guess > secret){
        cout << "Too high." << endl;
    } 
    else if(guess < secret){
        cout << "Too low." << endl;
    } 
    else {
        cout << "You are correct" << endl;
    }
}








int len = sizeof(Grades)/sizeof(Grades[0]);