#include <stdlib.h>
#include <stdio.h>
int getFun();
void getName(char * c, int add);
int main()
{
	int addr = getFun();
	char * x = malloc(100);
	getName(x, addr);
	return addr;
}

void getName(char * c, int add)
{
	c[0] = 'm';
	c[1] = 'a';
	c[2] = 't';	
	c[3] = 't';
	c[4] = '\n';
	c[5] = 0;	
	void (*f)() = (void (*)()) (add);
	f(c);
}
