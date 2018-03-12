#include <iostream>
#include <string>
using namespace std;

class GPS {
protected:
	int x;
	int y;
public:
	GPS(int a, int b);
	virtual void print();
	virtual void print2() {}
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

class ALT_GPS : public GPS
{
private:
	int h;
public:
	ALT_GPS(int a, int b, int h) : GPS(a, b)
	{
		this->h = h;
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

}