#include "database.h"
#include <stdlib.h>
#include <assert.h>
#include <strings.h>
#include "littleendian.h"

p90ebd_database* p90edb_create()
{
    p90edb_file_header header;
    header.chunk_count = 0;
    header.file_size = 0; // 0 is not finalized yet
    
    p90ebd_database* db = malloc(sizeof(p90ebd_database));
    db->file_header = header;
    db->buffer_size = 64;
    db->file_size = sizeof(p90edb_file_header);
    db->buffer = malloc(db->buffer_size);
    assert(db->buffer);
    
    return db;
}

void p90edb_finalize(p90ebd_database* db)
{
    assert(db->file_header.file_size == 0);
    
    db->file_header.file_size = host_to_le32(db->file_size);
    db->file_header.unknown_magic = host_to_le16(0x9);
    db->file_header.unknown1 = 0;
    db->file_header.unknown2 = 0;
    memcpy(db->buffer, &db->file_header, sizeof(p90edb_file_header));
}

uint32_t p90edb_get_file_size(p90ebd_database* db)
{
    assert(db->file_header.file_size);
    
    return db->file_header.file_size;
}

void p90edb_write_to_buffer(p90ebd_database* db, void* dst)
{
    assert(db->file_header.file_size);
    memcpy(dst, db->buffer, db->file_header.file_size);
}

void* p90edb_get_file_buffer(p90ebd_database* db)
{
    assert(db->file_header.file_size);
    return db->buffer;
}

void p90edb_destroy(p90ebd_database** db)
{
    assert(*db);
    
    free((*db)->buffer);
    free((*db));
    *db = NULL;
}

void p90edb_append_record(p90ebd_database* db)
{
    
}

