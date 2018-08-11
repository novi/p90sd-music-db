#ifndef p90sd_database_h
#define p90sd_database_h

#include "inttypes.h"

enum P90EDBRecordType {
    P90EDBRecordTypeArtist,
    P90EDBRecordTypeAlbum,
    P90EDBRecordTypeGenre,
    P90EDBRecordTypeSong
};

typedef struct {
    uint32_t chunk_count;
    uint32_t unknown1;
    uint32_t unknown_magic;
    uint32_t file_size;
    uint32_t unknown2;
} p90edb_file_header;

typedef struct {
    uint32_t chunk_size;
    uint32_t unknown1;
    uint32_t seq;
    uint32_t unknown2;
    uint32_t last_chunk_size;
    uint32_t unknown_mask1;
    uint32_t unknown3;
    uint32_t unknown_mask2;
    uint32_t unknown4;
    uint16_t record_offset[1];
} p90edb_chunk_header;

typedef struct {
    uint16_t record_type;
    uint16_t record_seq;
    uint32_t id[1];
} p90edb_record_header;

typedef struct {
    p90edb_file_header file_header;
    void* buffer;
    uint32_t buffer_size;
    uint32_t file_size;
} p90ebd_database;

p90ebd_database* p90edb_create();

void p90edb_finalize(p90ebd_database* db);
uint32_t p90edb_get_file_size(p90ebd_database* db);
void* p90edb_get_file_buffer(p90ebd_database* db);

//void p90edb_write_to_buffer(p90ebd_database* db, void* dst);
void p90edb_destroy(p90ebd_database** db);


#endif /* p90sd_database_h */

