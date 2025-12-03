#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

int main(int argc, char *argv[]) {
    int duration = 30;
    if (argc >= 2) duration = atoi(argv[1]);
    time_t end = time(NULL) + duration;
    char filename[] = "tmp_io_XXXXXX";
    int fd = mkstemp(filename);
    if (fd == -1) {
        perror("mkstemp");
        return 1;
    }
    FILE *f = fdopen(fd, "w+");
    if (!f) { perror("fdopen"); return 1; }

    char buffer[4096];
    memset(buffer, 'A', sizeof(buffer));
    long writes = 0;
    while (time(NULL) < end) {
        fseek(f, 0, SEEK_SET);
        fwrite(buffer, 1, sizeof(buffer), f);
        fflush(f);
        fseek(f, 0, SEEK_SET);
        fread(buffer, 1, sizeof(buffer), f);
        writes++;
    }
    fclose(f);
    remove(filename);
    printf("io_ops=%ld\n", writes);
    return 0;
}
