// ConsoleApplication1-Virtual.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <string>
using namespace std;
class tCalc {
protected:
	int a;
	int b;
	int c;
public:
	tCalc(int a1, int b1, int c1)
	{
		a = a1;
		b = b1;
		c = (int) sqrt(a * a + b * b);
	}
	virtual int tCalc::getDist(int a1, int b1)
	{
		return (int) sqrt(a1 * a1 + b1 * b1);
	}
};
class GPS {
protected:
	int x;
	int y;
public:
	GPS(int a, int b);
	virtual void print();
	virtual void print2() { cout << "default print2" << endl; }
};

GPS::GPS(int a, int b)
{
	x = a;
	y = b;
}

void GPS::print()
{
	cout << x << " " << y << endl;

}

class ALT_GPS : public GPS,tCalc 
{
private:
	int h;
public:
	ALT_GPS(int a, int b, int h) : GPS(a, b),tCalc(1,2,3)
	{
		this->h = h;
		this->x = 100;
		this->y = 101;
		this->a = 200;
		this->b = 201;
		this->c = 202;
	}
	virtual void print2();
};


void ALT_GPS::print2()
{
	cout << "[" << x << "," << y << "," << h << "]" << endl;

}
int main(int argc, char ** argv, char ** envp)
{
	GPS * g = new GPS(100, 0x55);
	g->print();
	ALT_GPS * a = new ALT_GPS(1, 2, 3);
	a->print2();

	GPS * fred = NULL;
	int choice;
	cin >> choice;
	switch (choice)
	{
	case 1:
		fred = g;
		break;
	case 2:
		fred = a;
		break;
	}
	fred->print2();


}