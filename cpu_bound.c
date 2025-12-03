#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int is_prime(long n) {
    if (n <= 1) return 0;
    if (n <= 3) return 1;
    if (n % 2 == 0) return 0;
    for (long i = 3; i * i <= n; i += 2)
        if (n % i == 0) return 0;
    return 1;
}

int main(int argc, char *argv[]) {
    int duration = 30; // segundos por padrão
    if (argc >= 2) duration = atoi(argv[1]);
    time_t end = time(NULL) + duration;
    long count = 0;
    long n = 1000000; // ponto inicial razoável para carga
    while (time(NULL) < end) {
        if (is_prime(n)) count++;
        n++;
    }
    printf("primes_found=%ld\n", count);
    return 0;
}
