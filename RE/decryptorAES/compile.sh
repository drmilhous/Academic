gcc -std=c99 -O3 -maes -march=native encrypt.c -o encrypt.out
gcc -std=c99 -O3 -maes -march=native encryptASCII.c -o encryptASCII.out
gcc -std=c99  -O3 -maes -march=native decrypt.c -o decrypt.out
gcc -std=c99  -O3 -maes -march=native decryptASCII.c -o decryptASCII.out
