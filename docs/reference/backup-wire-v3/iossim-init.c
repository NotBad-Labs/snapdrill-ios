#include <sqlite3.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s output.sqlite\n", argv[0]);
        return 2;
    }

    unlink(argv[1]);
    sqlite3 *database = NULL;
    int result = sqlite3_open_v2(
        argv[1],
        &database,
        SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
        NULL
    );
    if (result != SQLITE_OK) {
        fprintf(stderr, "open: %d\n", result);
        return 1;
    }

    int reserve_bytes = 0;
    result = sqlite3_file_control(
        database,
        "main",
        SQLITE_FCNTL_RESERVE_BYTES,
        &reserve_bytes
    );
    if (result != SQLITE_OK || reserve_bytes != 0) {
        fprintf(
            stderr,
            "reserve bytes: result=%d effective=%d\n",
            result,
            reserve_bytes
        );
        sqlite3_close(database);
        return 1;
    }

    printf(
        "sqlite_version=%s\nreserved_bytes=%d\n",
        sqlite3_libversion(),
        reserve_bytes
    );

    char *message = NULL;
    result = sqlite3_exec(
        database,
        "PRAGMA page_size=4096;"
        "PRAGMA encoding='UTF-8';"
        "PRAGMA auto_vacuum=NONE;"
        "PRAGMA journal_mode=DELETE;"
        "VACUUM;",
        NULL,
        NULL,
        &message
    );
    if (result != SQLITE_OK) {
        fprintf(stderr, "initialize: %d %s\n", result, message);
        sqlite3_free(message);
        sqlite3_close(database);
        return 1;
    }

    sqlite3_close(database);
    return 0;
}
