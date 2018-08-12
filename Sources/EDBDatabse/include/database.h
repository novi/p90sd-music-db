#ifndef p90sd_database_h
#define p90sd_database_h

#include "inttypes.h"

#define RECORD_COUNT_IN_CHUNK (16)

typedef enum {
    p90edb_data_encoding_ascii = 0,
    p90edb_data_encoding_utf16 = 1
} p90edb_data_encoding;

// TODO: describe edb structures

typedef struct {
    uint32_t chunk_count;
    uint32_t record_count;
    uint32_t unknown_magic;
    uint32_t file_size;
    uint32_t unknown2;
} p90edb_file_header;

typedef struct {
    uint32_t chunk_header_size_seq;
    uint32_t record_count_offset;
    uint32_t id;
    uint32_t unknown_record_count_in_chunk;
    uint32_t last_chunk_size;
    uint32_t unknown_mask1;
    uint32_t unknown3;
    uint32_t unknown_mask2;
    uint32_t unknown4;
    uint16_t record_offset[RECORD_COUNT_IN_CHUNK]; // max RECORD_COUNT_IN_CHUNK records
} p90edb_chunk_header;

typedef struct {
    uint16_t type;
    uint16_t seq;
    uint32_t id[1]; // 1...5
    // uint8_t data_len_field[1...4] after ids
} p90edb_record_header;

typedef struct {
    uint8_t* buffer;
    uint32_t buffer_size;
    
    uint8_t is_finalized;
    uint32_t chunk_count;
    uint32_t record_count_in_database;
    
    uint32_t current_ptr;
    
    uint32_t prev_chunk_ptr;
    uint32_t prev_record_count_in_chunk;
    
    uint32_t chunk_head_ptr;    
    uint16_t current_record_count; // in current chunk
    
    uint32_t record_seq;
} p90edb_database;

p90edb_database* p90edb_create();

void p90edb_finalize(p90edb_database* db);
uint32_t p90edb_get_file_size(p90edb_database* db);
void* p90edb_get_file_buffer(p90edb_database* db);
void p90edb_destroy(p90edb_database** db);

void p90edb_append_artist(p90edb_database* db, uint32_t id, const uint8_t* data, uint8_t data_length, p90edb_data_encoding encoding);
void p90edb_append_genre(p90edb_database* db, uint32_t id, const uint8_t* data, uint8_t data_length, p90edb_data_encoding encoding);
void p90edb_append_album(p90edb_database* db, uint32_t artist_id, uint32_t genre_id, uint32_t album_id, const uint8_t* data, uint8_t data_length, p90edb_data_encoding encoding);
void p90edb_append_song(p90edb_database* db, uint32_t artist_id, uint32_t genre_id, uint32_t album_id, uint32_t song_id, const uint8_t* path, uint8_t path_length, const uint8_t* title, uint8_t title_length, p90edb_data_encoding encoding);

#endif /* p90sd_database_h */

