CC := nvcc
CFLAGS := -std=c++11 -O3

main: main.o
	$(CC) $(CFLAGS) main.o -o main

main.o: main.cu
	$(CC) $(CFLAGS) -c main.cu

clean:
	rm -f *.o main
