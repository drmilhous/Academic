#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <cuda.h>
#include <curand.h>
#include <curand_kernel.h>

#define N 1024

//making my own strcpy and and str cat because screw cuda, not giving access to libraries :(
__device__ char* nStrCpy(char *dest, const char *src) {
	int i =0;
	do {
		dest[i] = src[1];
	} while (src[i++] != 0);
	return dest;
}

__device__ char* nStrcat(char *dest, const char *src){
	int i =0;
	while (dest[i] != 0) i++;
	nStrCpy(dest+1, src);
	return dest;
}

//this makes a single password, recursivly adding 2 characters to password every time and removing one from site
__device__ void  makePassword(char *square, char* site, int position, int direction, int size, char* password) {
	//x position and y position within square as square is a linear array
	int x = position%size;
	int y = position/size;
	int firstCharP = 0;
	int secCharP = 0;

	//if direction is vertical
	if (direction ==0) {
		//check every character in the current vertical line
		for (int i =0; i < size; i++) {

			//position of new character
			int newPosition = (i*size) + x;

			//found a match
			if (site[0] == square[newPosition]) {
				//goes up
				if (newPosition < position) {
					//first character for password
					firstCharP = newPosition - size;
					//if below first line go to bottom
					if(firstCharP < 0) 
						firstCharP += (size * size);

					//second character for password
					secCharP = firstCharP - size;
					if(secCharP < 0)
						secCharP += (size*size);
				//goes down
				} else {
					firstCharP = newPosition + size;
					// if below last line, loop to top
					if (firstCharP >= (size*size))
						firstCharP -= (size*size);
					
					secCharP = firstCharP + size;
					if(secCharP >= (size*size))
						secCharP -= (size*size);
				}
			}
		}
		//switch to horizontal directiuon for next 2 characters
		direction = 1;

	//if direction is horizontal
	} else {
		for (int i =0; i < size; i++) {
			int newPosition = (y*size)+i;
			if (site[0] == square[newPosition]) {
				//new position to the left of previous, should never be the same
				if (newPosition < position) {
					firstCharP = newPosition -1;
					//if previous row, wrap around to right side instead
					if ((firstCharP/size) < y || firstCharP == -1)
						firstCharP += size;
					
					secCharP = firstCharP -1;
					if ((secCharP/size) < y || secCharP == -1)
						secCharP += size;
				//new position to right of previous
				} else {
					//if on next row wrap to front
					firstCharP  = newPosition +1;
					if ((firstCharP/size) > y)
						firstCharP -= size;

				secCharP = firstCharP +1;
					if ((secCharP/size) > y)
						secCharP -= size;
				}
			}
		}
		//switch to vertical direction for next couple of characters
		direction = 0;
	}
	
	//go to next character in site name
	site++;
	//if more of the password is neeeded
	if (site[0] != '\n') {
		//set the next couple of characters
		password[0] = square[firstCharP];
		password[1] = square[secCharP];
		//increase pointer to start the next part of password without overwrting previous characters
		password++;
		password++;
		
		//mor parts of the password!
		makePassword(square, site, secCharP, direction, size, password);
	} else {
		//set the last two characters of the password.
		password[0] = square[firstCharP];
		password[1] = square[secCharP];
	}
}

//get the starting poisition of the password within the gride, i.e. start at top row, and travel through the domain name
__device__ int getStartPosition(char *square, char *site, int size) {
	int position =0;

	//find the atarting position within the first row
	for (int i =0; i < size; i++) {
		if (square[i]  == site[0])
			position = i;
	}

	//direction 0 is going down, as it starts	
	int direction = 0;
	
	//doing 6 characters only, because apparently I hate make modularized code the first time
	for (int i =1; i < 6; i++) {

		//x and y position within a linear array
		int x = position%size;
		int y = position/size;

		//check all characters in row/colums
		for (int j = 0; j < size; j++) {
			//vertical directions
			if (direction ==0) {
				//it found the next character!
				if (site[i] == square[(j * size) + x ]) {
					position = (j * size) +x;
					direction = 1;
					break;
				}
			//horizontal direction
			} else {
				//it found the nest character!
				if (site[i] == square[(y * size) + j]) {
					position = (y* size) + j;
					direction = 0;
					break;
				}
			}
		}
	}
	//return the starting poistion... because that's the point of this function ... dur
	return position;
}

//make a random password
__global__ void randomWords(char *square, char *passwords, int size, int *c, int amount) {
	//that id though
	int tid = blockIdx.x*blockDim.x+threadIdx.x;

	//cuda random intitalizers
	curandState_t state;
	curand_init(tid, 1, 2, &state);
	
	//make a certain number of passwords per core
	for (int a = 0; a < amount; a++) {

		//starting position for this password
		int tidNum = ((tid * amount) + a) *24;
		passwords[(tidNum)] = square[(curand(&state) % size)];
		
		//7 characters for the site, 6 and a \n
		char site[7];
		site[0] = passwords[tidNum];
		site[6] = '\n';

		//make 6 random characters
		for (int i=1; i < 6; i++) {
			//make sure 2 characters do not repeat
			do {
			passwords[i + (tidNum)] = square[(curand(&state) % size)];
			} while (passwords[(i-1) +(tidNum)] == passwords[i + (tidNum)]);

			//set random character
			site[i] = passwords[i + (tidNum)];
		}

		// add that ' -> ' Miller wanted
		passwords[7 + (tidNum)] = ' ';
		passwords[8 + (tidNum)] = '-';
		passwords[9 + (tidNum)] = '>';
		passwords[10 + (tidNum)] = ' ';

		//lets get that starting position
		int position = getStartPosition(square, site, size);
		
		//stored the startingposition within c for debuggin puroposes
		//I left this in here becuase it could be useful if I ever come back to this project
		c[(tid * amount)+ a] = position;

		//create the password object
		char *password;
		password = (char *)malloc(sizeof(char) *13);

		//generate that password finally
		makePassword(square, site, position, 1, size, password);

		//save the password in the passwords array that the main program can access
		for(int i = 0; i < 12; i++) {
			passwords[11 + i + (tidNum)] = password[i];
		}
	}
}

int main(int argc, char ** argv) 
{	
	//used to organize cores on cuda
	dim3 gridsize, blocksize;
	int device = atoi(argv[1]);
	cudaSetDevice(device);
	//get size of the grid
	int size = 15;
	//printf("Please input a size of grid to be tested (integer number only): ");
	//scanf("%d", &size);

	//I want at least total passwords (I used 12,000 because when creating 10,000 passwords
	//out of a possible 100,000 there are bound to be some repeats
	int total = 500;
	int amount = total / N;
	amount++;
	total = amount * N;

	//get the file to be read
	char file[] = "grid15.txt";
	//printf("Insert a file containing your latin square: ");
	//scanf("%s", file);

	//allocate memory for the grid
	char grid[size][size];
	char *square;
	cudaMallocManaged((void**)&square, size * size * sizeof(char));
	
	//allocate memory for the grid
	char *passwords;
	printf("total: %d\n", total);
	cudaMallocManaged((void**)&passwords, sizeof(char) * 24 * total);
	
	//open grid file to read grid
	FILE *file1 = fopen(file, "r");

	//copy each character from grid file to grid object
	for (int i=0; i < size; i++) {
		for (int j=0; j < size; j++) {
			fscanf(file1, "%c\n", &grid[i][j]);
		}
		
	}

	//transfer the grid to a linear array
	for(int i=0; i < size;i++) {
		for(int j=0; j < size; j++) {
			square[size * i + j] = grid[i][j];
		}
	}

	//close the grid file
	fclose(file1);

	// allocate the memory on the GPU, this was used for saving the starting positions of each password
	int *c;
	cudaMallocManaged( (void**)&c, N * amount * sizeof(int));

	//I randomly chose 16 as the block size, it seems like a good number
	blocksize.x = 16;
	gridsize.x = N/blocksize.x;
 
	//this activates some cool cuda stuff
	randomWords<<<gridsize.x, blocksize.x>>>(square, passwords, size, c, amount);
	cudaDeviceSynchronize();
	
	//outpt file brah
	FILE * f = fopen("output15.txt", "w");

	//lets make sure that file exists brh
	if (f == NULL) {
		printf("error opening output.txt\n");
		exit(1);
	}

	//copy the passwords to the file one character at a time. oh yeah the effeciency broseph
	for (int i=0; i<total; i++)
	 {
		char * output = (char *)malloc(sizeof(char) * 24);
		for (int j=0; j<23;j++) {
			fprintf(f, "%c", passwords[j + (i * 24)]);
		}
		fprintf(f, "\n");
	}


	// free the memory allocated on the GPU, close the file and you are done Tyranbrosaurus Rex!
	fclose(f);
	cudaFree( c );
	cudaFree( square );
	cudaFree( passwords );
	return 0;
}
