#include "FastGrid.h"
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
int convertUpper(char u)
	{
		int x = (int) u;
		int A = (int) 'A';
		x = x - A;
		return x;
	}
char convertChar(char u)
	{
		int x = (int) u;
		int A = (int) 'A';
		x = x + A;
		return (char) x;
	}

Path * getPath(char * line)
	{
		char * domain = line;
		char * pass = strstr(domain, "-");
		long offset = (long) pass - (long) domain;
		domain[offset - 2] = 0;
		pass += 3;

		int domainLen = strlen(domain);

		//printf("[%s]->[%s]\n", domain, pass);
		Path * head = NULL;
		Path * tail = NULL;
		char previous = domain[domainLen - 1];
		int direction = domainLen % 2 == 1 ? UP : LEFT;
		for (int i = 0; i < domainLen; i++)
			{
				char next = domain[i];
				Path * current = allocate(previous, next, &pass[i * 2], direction);
				previous = pass[i*2+1];
				if (head == NULL)
					{
						head = current;
						cudaMallocManaged((void **) &head->domain, domainLen + 1);
						strcpy(head->domain, domain);
						cudaMallocManaged((void **) &head->pass, strlen(pass) + 1);
						strcpy(head->pass, pass);
					}
				if (tail == NULL)
					{
						tail = head;
					}
				else
					{
						tail->next = current;
						tail = current;
					}
				direction = direction == UP ? LEFT : UP;
			}

		return head;
	}

void printPath(Path * p)
	{
		if (p != NULL)
			{
				char dir = p->direction == UP ? 'U' : 'L';
				if (p->domain != NULL)
					{
						printf("[%s]->[%s]\n", p->domain, p->pass);
					}
				int value = (int) p->letters[0];
				if (value > 30)
					{
						printf("[%c]->[%c%c%c]%c\n", p->letters[0], p->letters[1], p->letters[2], p->letters[3], dir);
					}
				else
					{
						printf("[%c]->[%c%c%c]%c\n", convertChar(p->letters[0]), convertChar(p->letters[1]), convertChar(p->letters[2]), convertChar(p->letters[3]), dir);
						//printf("[%d]->[%d%d%d]%c\n", p->letters[0], p->letters[1], p->letters[2], p->letters[3], dir);

					}
				printPath(p->next);
			}
	}

Path * allocate(char c, char c1, char* c2, int direction)
	{
		Path *p;
		cudaMallocManaged((void **) &p, 1);
		p->next = NULL;
		p->letters[0] = convertUpper(c);
		p->letters[1] = convertUpper(c1);
		p->letters[2] = convertUpper(c2[0]);
		p->letters[3] = convertUpper(c2[1]);
		p->direction = direction;
		p->domain = NULL;
		p->pass = NULL;
		return p;
	}

Path ** scanChars()
	{
		char test[100] = "HEBJCE  -> BJAGDHCHJEGJ";
		int count = 100;
		int index = 0;
		Path ** PathList;
		cudaMallocManaged((void **) &PathList, (sizeof(Path *)) * count);
		Path * p = getPath(test);
		
		FILE * database;
		char buffer[30];

		database = fopen("output.txt", "r");

		if (NULL == database)
			{
				perror("opening database");
				return NULL;
			}
		int max = 10;
		while (EOF != fscanf(database, "%[^\n]\n", buffer) && index < max)
			{
				char * b = buffer;
				while (*b != '-')
					{
						if (*b == 0)
							{
								*b = ' ';
							}
						b++;
					}
				if (index < max)
					{
						p = getPath(buffer);
						PathList[index] = p;
						index++;
						if (index == count)
							{
								Path ** temp;
								cudaMallocManaged((void **) &temp, (sizeof(Path *) * count * 1.5));
								for (int i = 0; i < count - 1; i++)
									{
										temp[i] = PathList[i];
									}
								cudaFree(PathList);
								PathList = temp;
								count *= 1.5;

							}

						//printf("> %s\n", buffer);
						//	getPath(buffer);
					}
			}

		/*for (int i = 0; i < count; i++)
		 {
		 printPath(PathList[i]);
		 }*/
		printf("Count is  = %d\n", index);
		fclose(database);
		printPath(PathList[0]);
		return PathList;
	}

void printGrid(Grid * g, int N)
	{
		printf("-- Grid -- \n");
		for (int i= 0; i < N; i++)
		{
			printf(" %03X ",g->col[i]);
		}
		for (int row = 0; row < N; row++)
			{
				printf("%01d|%03X| ", row,g->row[row]);
				for (int col = 0; col < N; col++)
					{
						char c = g->Cells[row][col];
						printf("  %c  ", c);
					}
				printf("\n");
			}
	}







