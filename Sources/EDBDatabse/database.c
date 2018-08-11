#include "database.h"
#include <stdlib.h>
#include <assert.h>
#include <strings.h>
#include "littleendian.h"

typedef enum {
    p90edb_record_type_artist = 0x60,
    p90edb_record_type_album = 0x40,
    p90edb_record_type_genre = 0x80,
    p90edb_record_type_song = 0x20
} p90edb_record_type;

void p90edb_finalize_chunk(p90edb_database* db);

p90edb_database* p90edb_create()
{
    p90edb_database* db = malloc(sizeof(p90edb_database));
    db->buffer_size = 0xfffff; // TODO: size
    db->buffer = malloc(db->buffer_size);
    db->file_header = (void*)db->buffer;
    db->file_header->chunk_count = 0;
    db->file_header->file_size = 0; // 0 is not finalized yet
    db->current_ptr = sizeof(p90edb_file_header);
    db->record_seq = 0;
    db->current_record_count = 0;
    db->current_chunk = NULL;
    assert(db->buffer);
    
    return db;
}

void p90edb_finalize(p90edb_database* db)
{
    if (db->current_chunk) {
        p90edb_chunk_header* last_chunk = db->current_chunk;
        p90edb_finalize_chunk(db);
        
        // update last chunk size
        last_chunk->last_chunk_size = db->current_ptr - db->chunk_head_ptr;
    }
    
    assert(db->file_header->file_size == 0);
    
    db->file_header->file_size = host_to_le32(db->current_ptr);
    db->file_header->unknown_magic = host_to_le16(0x9);
    db->file_header->unknown2 = 0;
}

uint32_t p90edb_get_file_size(p90edb_database* db)
{
    assert(db->file_header->file_size);
    
    return db->file_header->file_size;
}

void p90edb_write_to_buffer(p90edb_database* db, void* dst)
{
    assert(db->file_header->file_size);
    memcpy(dst, db->buffer, db->file_header->file_size);
}

void* p90edb_get_file_buffer(p90edb_database* db)
{
    assert(db->file_header->file_size);
    return db->buffer;
}

void p90edb_destroy(p90edb_database** db)
{
    assert(*db);
    
    free((*db)->buffer);
    free((*db));
    *db = NULL;
}

void p90edb_start_chunk(p90edb_database* db)
{
    assert(db->current_chunk == NULL);
    
    db->current_chunk = (void*)&db->buffer[db->current_ptr]; // fixed size chunk
    db->current_record_count = 0;
    for (uint32_t i = 0; i < RECORD_COUNT_IN_CHUNK; i++) {
        db->current_chunk->record_offset[i] = 0;
    }
    db->chunk_head_ptr = db->current_ptr;
    db->current_ptr += sizeof(p90edb_chunk_header);
    db->file_header->chunk_count += 1;
}

void p90edb_finalize_chunk(p90edb_database* db)
{
    assert(db->current_chunk);
    assert(db->current_record_count > 0);
    
    uint32_t prev_chunk_count = db->file_header->chunk_count - 1;
    
    //uint8_t chunk_header_valid_size = ( 4 * 9 /* chunk header without record offset*/ ) + db->current_record_count*2;
    uint8_t chunk_header_valid_size = 0xa4;
    uint8_t chunk_seq = ((prev_chunk_count * 2) + 4 ) % 0xff;
    db->current_chunk->chunk_header_size_seq = host_to_le32( (chunk_header_valid_size << 0) | (chunk_seq << 8) );
    // TODO:
    db->current_chunk->record_count_offset = host_to_le32( (db->current_record_count) );
    db->current_chunk->id = host_to_le32(prev_chunk_count * 4);
    db->current_chunk->unknown_record_count_in_chunk = host_to_le32( (db->current_record_count << 16) );
    db->current_chunk->last_chunk_size = 0;
    db->current_chunk->unknown_mask1 = host_to_le32(0xffffffff);
    db->current_chunk->unknown3 = host_to_le32(0);
    db->current_chunk->unknown_mask2 = host_to_le32(0x88888888);
    db->current_chunk->unknown4 = host_to_le32(0);
    
    db->current_chunk = NULL;
}

void p90edb_append_record(p90edb_database* db, p90edb_record_type type, const uint32_t* ids, uint8_t id_count, const uint8_t* data, uint8_t data_length, p90edb_data_encoding encoding, uint8_t is_truncate)
{
    if (db->current_chunk == NULL) {
        p90edb_start_chunk(db);
    }
    
    p90edb_record_header* header = (void*)&db->buffer[db->current_ptr];
    
    uint8_t data_len_field[4] = {0,0,0,0};
    uint8_t data_len_field_size;
    if (encoding == p90edb_data_encoding_ascii) {
        data_len_field_size = 1;
        uint16_t len = data_length * 2 + 3;
        assert(len <= 255);
        data_len_field[0] = len;
    } else if (encoding == p90edb_data_encoding_utf16) {
        data_len_field_size = 4;
        data_len_field[0] = 0x90;
        uint16_t len = data_length + 4;
        assert(len <= 255);
        data_len_field[1] = len;
    } else {
        assert(0);
    }
    
    uint16_t record_length = ( 4 + (sizeof(uint32_t)*id_count) + data_len_field_size + data_length );
    // truncate to multiply 4
    if (is_truncate && record_length % 4 != 0) {
        record_length += 4 - (record_length % 4);
    }
    memset(header, 0, record_length); // fill zero for the current record
    
    header->type = host_to_le16(type);
    header->seq = host_to_le16(db->record_seq % 0xffff);
    
    db->record_seq += 0x20;
    
    for (uint8_t i = 0; i < id_count; i++) {
        header->id[i] = host_to_le32(ids[i]); // copy ids
    }
    
    uint8_t* data_len_field_ptr = ((uint8_t*)header) + 4 + (sizeof(uint32_t)*id_count);
    memcpy(data_len_field_ptr, &data_len_field, data_len_field_size);
    
    uint8_t* data_ptr = data_len_field_ptr + data_len_field_size;
    memcpy(data_ptr, data, data_length);
    
    // fill record offset in chunk
    db->current_chunk->record_offset[db->current_record_count] = db->current_ptr - db->chunk_head_ptr;
    db->current_record_count += 1;
    db->file_header->record_count += 1;
    
    db->current_ptr += record_length;
}


void p90edb_append_artist(p90edb_database* db, uint32_t id, const uint8_t* data, uint8_t data_length, p90edb_data_encoding encoding)
{
    uint32_t ids[1];
    ids[0] = id;
    p90edb_append_record(db, p90edb_record_type_artist, ids, 1, data, data_length, encoding, 1);
}

void p90edb_append_genre(p90edb_database* db, uint32_t id, const uint8_t* data, uint8_t data_length, p90edb_data_encoding encoding)
{
    uint32_t ids[1];
    ids[0] = id;
    p90edb_append_record(db, p90edb_record_type_genre, ids, 1, data, data_length, encoding, 1);
}

void p90edb_append_album(p90edb_database* db, uint32_t artist_id, uint32_t genre_id, uint32_t album_id, const uint8_t* data, uint8_t data_length, p90edb_data_encoding encoding)
{
    uint32_t ids[3];
    ids[0] = genre_id;
    ids[1] = artist_id;
    ids[2] = album_id;
    p90edb_append_record(db, p90edb_record_type_album, ids, 3, data, data_length, encoding, 1);
}


void p90edb_append_song(p90edb_database* db, uint32_t artist_id, uint32_t genre_id, uint32_t album_id, uint32_t song_id, const uint8_t* path, uint8_t path_length, const uint8_t* title, uint8_t title_length, p90edb_data_encoding encoding)
{
    uint32_t ids[5];
    ids[0] = genre_id;
    ids[1] = artist_id;
    ids[2] = album_id;
    ids[3] = song_id;
    ids[4] = 0;
    
    uint32_t record_head_ptr = db->current_ptr;
    
    // append path
    p90edb_append_record(db, p90edb_record_type_song, ids, 5, path, path_length, encoding, 0);
    
    // append title
    
    uint8_t title_data_len;
    if (encoding == p90edb_data_encoding_ascii) {
        uint16_t len = title_length * 2 + 3;
        assert(len <= 255);
        title_data_len = len;
    } else if (encoding == p90edb_data_encoding_utf16) {
        uint16_t len = title_length + 4;
        assert(len <= 255);
        title_data_len = len;
    } else {
        assert(0);
    }
    
    uint8_t title_len_field[2];
    uint32_t file_path_record_len = db->current_ptr - record_head_ptr;
    title_len_field[0] = file_path_record_len + 1;
    title_len_field[1] = title_data_len;
    
    memcpy(&db->buffer[db->current_ptr], title_len_field, 2);
    db->current_ptr += 2;
    file_path_record_len += 2;
    
    
    memcpy(&db->buffer[db->current_ptr], title, title_length);
    db->current_ptr += title_length;
    file_path_record_len += title_length;
    
    // truncate multi 4
    if (file_path_record_len % 4 != 0) {
        uint8_t extra_len = 4 - (file_path_record_len % 4);
        memset(&db->buffer[db->current_ptr], 0, extra_len);
        db->current_ptr += extra_len;
    }
    
    // append dummy, TODO:
    uint16_t dummy_len = 1536;
    memset(&db->buffer[db->current_ptr], 0, dummy_len);
    db->current_ptr += dummy_len;
}
