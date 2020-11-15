all: cpng.o
	g++ cpng.o main.c -lz -lpng -O3 -o cdither

cpng.o: cpng.h cpng.c
	g++ -c cpng.c -lz -lpng -O3 -Wno-unused-result -o cpng.o

clean:
	rm -f *.o
