#include <sqlite3.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void require_ok(int result, sqlite3 *database, const char *operation) {
    if (result != SQLITE_OK) {
        fprintf(
            stderr,
            "%s failed: %d/%d %s\n",
            operation,
            result,
            sqlite3_extended_errcode(database),
            sqlite3_errmsg(database)
        );
        exit(1);
    }
}

static void configure(sqlite3 *database, int operation, int value, const char *name) {
    int actual = -1;
    int result = sqlite3_db_config(database, operation, value, &actual);
    printf("dbconfig %s result=%d actual=%d\n", name, result, actual);
    require_ok(result, database, name);
    if (actual != value) {
        fprintf(stderr, "%s mismatch\n", name);
        exit(1);
    }
}

static void set_limit(sqlite3 *database, int category, int value, const char *name) {
    int previous = sqlite3_limit(database, category, value);
    int actual = sqlite3_limit(database, category, -1);
    printf("limit %s previous=%d actual=%d\n", name, previous, actual);
    if (actual != value) {
        fprintf(stderr, "%s mismatch\n", name);
        exit(1);
    }
}

static int print_pragma(
    void *context,
    int column_count,
    char **values,
    char **column_names
) {
    (void)context;
    for (int index = 0; index < column_count; index += 1) {
        printf(
            "pragma %s=%s\n",
            column_names[index],
            values[index] == NULL ? "NULL" : values[index]
        );
    }
    return 0;
}

static int progress_callback(void *context) {
    int *count = context;
    *count += 1;
    return 0;
}

static int authorizer_callback(
    void *context,
    int action,
    const char *first,
    const char *second,
    const char *database,
    const char *trigger
) {
    (void)context;
    (void)first;
    (void)second;
    (void)database;
    (void)trigger;
    return action == SQLITE_ATTACH ? SQLITE_DENY : SQLITE_OK;
}

static void verify_header(const char *path) {
    unsigned char header[100];
    FILE *file = fopen(path, "rb");
    if (file == NULL || fread(header, sizeof(header), 1, file) != 1) {
        perror("read header");
        exit(1);
    }
    fclose(file);

    int page_size = (header[16] << 8) | header[17];
    unsigned int user_version =
        (header[60] << 24)
        | (header[61] << 16)
        | (header[62] << 8)
        | header[63];
    unsigned int application_id =
        (header[68] << 24)
        | (header[69] << 16)
        | (header[70] << 8)
        | header[71];
    printf(
        "header page_size=%d reserve=%u write=%u read=%u user_version=%u "
        "application_id=%u\n",
        page_size,
        header[20],
        header[18],
        header[19],
        user_version,
        application_id
    );
    if (
        memcmp(header, "SQLite format 3\0", 16) != 0
        || page_size != 4096
        || header[18] != 1
        || header[19] != 1
        || header[20] != 0
        || user_version != 3
        || application_id != 707275168
    ) {
        fprintf(stderr, "header mismatch\n");
        exit(1);
    }
}

int main(void) {
    printf("sqlite=%s number=%d\n", sqlite3_libversion(), sqlite3_libversion_number());
    int dbstat_enabled = sqlite3_compileoption_used("ENABLE_DBSTAT_VTAB");
    printf("compile ENABLE_DBSTAT_VTAB=%d\n", dbstat_enabled);
    if (!dbstat_enabled) {
        fprintf(stderr, "DBSTAT unavailable\n");
        return 1;
    }

    const char *home = getenv("HOME");
    if (home == NULL) {
        fprintf(stderr, "HOME unavailable\n");
        return 1;
    }
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/snapdrill-hardening-XXXXXX", home);
    int descriptor = mkstemp(path);
    if (descriptor < 0) {
        perror("mkstemp");
        return 1;
    }
    close(descriptor);
    unlink(path);

    sqlite3 *database = NULL;
    int result = sqlite3_open_v2(
        path,
        &database,
        SQLITE_OPEN_READWRITE
            | SQLITE_OPEN_CREATE
            | SQLITE_OPEN_NOFOLLOW
            | SQLITE_OPEN_EXRESCODE,
        NULL
    );
    require_ok(result, database, "create");

    int reserve_bytes = 0;
    result = sqlite3_file_control(
        database,
        "main",
        SQLITE_FCNTL_RESERVE_BYTES,
        &reserve_bytes
    );
    printf("reserve result=%d previous=%d\n", result, reserve_bytes);
    require_ok(result, database, "reserve");

    configure(database, SQLITE_DBCONFIG_DEFENSIVE, 1, "DEFENSIVE");
    configure(database, SQLITE_DBCONFIG_TRUSTED_SCHEMA, 0, "TRUSTED_SCHEMA");
    configure(database, SQLITE_DBCONFIG_WRITABLE_SCHEMA, 0, "WRITABLE_SCHEMA");
    configure(database, SQLITE_DBCONFIG_ENABLE_TRIGGER, 0, "ENABLE_TRIGGER");
    configure(database, SQLITE_DBCONFIG_ENABLE_VIEW, 0, "ENABLE_VIEW");
    int load_extension_omitted =
        sqlite3_compileoption_used("OMIT_LOAD_EXTENSION");
    printf("compile OMIT_LOAD_EXTENSION=%d\n", load_extension_omitted);
    if (!load_extension_omitted) {
        configure(
            database,
            SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION,
            0,
            "ENABLE_LOAD_EXTENSION"
        );
    }
    configure(database, SQLITE_DBCONFIG_DQS_DDL, 0, "DQS_DDL");
    configure(database, SQLITE_DBCONFIG_DQS_DML, 0, "DQS_DML");
    configure(database, SQLITE_DBCONFIG_ENABLE_FKEY, 1, "ENABLE_FKEY");

    set_limit(database, SQLITE_LIMIT_LENGTH, 67108864, "LENGTH");
    set_limit(database, SQLITE_LIMIT_SQL_LENGTH, 4096, "SQL_LENGTH");
    set_limit(database, SQLITE_LIMIT_COLUMN, 32, "COLUMN");
    set_limit(database, SQLITE_LIMIT_EXPR_DEPTH, 20, "EXPR_DEPTH");
    set_limit(database, SQLITE_LIMIT_COMPOUND_SELECT, 4, "COMPOUND_SELECT");
    set_limit(database, SQLITE_LIMIT_VDBE_OP, 50000, "VDBE_OP");
    set_limit(database, SQLITE_LIMIT_FUNCTION_ARG, 8, "FUNCTION_ARG");
    set_limit(database, SQLITE_LIMIT_ATTACHED, 0, "ATTACHED");
    set_limit(database, SQLITE_LIMIT_LIKE_PATTERN_LENGTH, 256, "LIKE_PATTERN");
    set_limit(database, SQLITE_LIMIT_VARIABLE_NUMBER, 32, "VARIABLE_NUMBER");
    set_limit(database, SQLITE_LIMIT_TRIGGER_DEPTH, 0, "TRIGGER_DEPTH");
    set_limit(database, SQLITE_LIMIT_WORKER_THREADS, 0, "WORKER_THREADS");

    sqlite3_int64 mmap_size = 0;
    result = sqlite3_file_control(database, "main", SQLITE_FCNTL_MMAP_SIZE, &mmap_size);
    printf("mmap result=%d previous=%lld\n", result, mmap_size);
    require_ok(result, database, "mmap");

    require_ok(
        sqlite3_exec(
            database,
            "PRAGMA page_size=4096;"
            "PRAGMA application_id=707275168;"
            "PRAGMA user_version=3;"
            "PRAGMA journal_mode=DELETE;"
            "PRAGMA synchronous=EXTRA;"
            "PRAGMA fullfsync=ON;"
            "CREATE TABLE probe(id INTEGER PRIMARY KEY, value TEXT NOT NULL) STRICT;"
            "INSERT INTO probe(value) VALUES('ok');",
            NULL,
            NULL,
            NULL
        ),
        database,
        "fixture"
    );
    require_ok(
        sqlite3_exec(
            database,
            "PRAGMA synchronous; PRAGMA fullfsync; PRAGMA journal_mode;",
            print_pragma,
            NULL,
            NULL
        ),
        database,
        "durability readback"
    );
    require_ok(sqlite3_close(database), database, "close writer");
    database = NULL;
    verify_header(path);

    char uri[1024];
    snprintf(
        uri,
        sizeof(uri),
        "file:%s?mode=ro&immutable=1&cache=private",
        path
    );
    result = sqlite3_open_v2(
        uri,
        &database,
        SQLITE_OPEN_READONLY
            | SQLITE_OPEN_URI
            | SQLITE_OPEN_PRIVATECACHE
            | SQLITE_OPEN_NOFOLLOW
            | SQLITE_OPEN_EXRESCODE,
        NULL
    );
    require_ok(result, database, "readonly open");
    int main_readonly = sqlite3_db_readonly(database, "main");
    int temp_readonly = sqlite3_db_readonly(database, "temp");
    printf("readonly main=%d temp=%d\n", main_readonly, temp_readonly);
    if (main_readonly != 1 || temp_readonly != -1) {
        fprintf(stderr, "readonly mismatch\n");
        return 1;
    }

    int progress_count = 0;
    sqlite3_progress_handler(database, 1, progress_callback, &progress_count);
    require_ok(
        sqlite3_set_authorizer(database, authorizer_callback, NULL),
        database,
        "authorizer"
    );
    require_ok(
        sqlite3_exec(
            database,
            "SELECT COUNT(*) AS dbstat_rows FROM dbstat('main');",
            print_pragma,
            NULL,
            NULL
        ),
        database,
        "DBSTAT query"
    );
    printf("progress callbacks=%d\n", progress_count);
    if (progress_count == 0) {
        fprintf(stderr, "progress handler unavailable\n");
        return 1;
    }

    result = sqlite3_exec(
        database,
        "ATTACH ':memory:' AS denied;",
        NULL,
        NULL,
        NULL
    );
    printf("authorizer attach result=%d\n", result);
    if (result != SQLITE_AUTH) {
        fprintf(stderr, "authorizer did not deny ATTACH\n");
        return 1;
    }
    sqlite3_progress_handler(database, 0, NULL, NULL);
    require_ok(
        sqlite3_set_authorizer(database, NULL, NULL),
        database,
        "remove authorizer"
    );

    require_ok(sqlite3_close(database), database, "close reader");
    unlink(path);
    return 0;
}
