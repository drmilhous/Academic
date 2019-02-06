// ConsoleApplication1-RTTI.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include <typeinfo> // For std::bad_cast
#include <iostream> // For std::cout, std::err, std::endl etc.

class A {
public:
	// Since RTTI is included in the virtual method table there should be at least one virtual function.
	virtual ~A() { };
	void methodSpecificToA() { std::cout << "Method specific for A was invoked" << std::endl; };
};

class B : public A {
public:
	void methodSpecificToB() { std::cout << "Method specific for B was invoked" << std::endl; };
	virtual ~B() { };
};

void my_function(A *my_a)
{
	volatile int y;
	//try {
		y = 0xFF;
		B* my_b = dynamic_cast<B*>(my_a); // cast will be successful only for B type objects.
		y = 0xBB;
		if (my_b != NULL)
		{
			my_b->methodSpecificToB();
		}
		else
		{
			printf("bad");
		}
	//}
	//catch (const std::bad_cast& e) {
	//	std::cerr << "  Exception " << e.what() << " thrown." << std::endl;
	//	std::cerr << "  Object is not of type B" << std::endl;
	//}
}

int main()
{
	volatile int x;
	A *arrayOfA[3];          // Array of pointers to base class (A)
	arrayOfA[0] = new B();   // Pointer to B object
	arrayOfA[1] = new B();   // Pointer to B object
	arrayOfA[2] = new A();   // Pointer to A object
	x = 0xAA;
	for (int i = 0; i < 3; i++) {
		my_function(arrayOfA[i]);
		delete arrayOfA[i];  // delete object to prevent memory leak
	}
}
