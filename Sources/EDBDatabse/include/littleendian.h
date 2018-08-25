//#include <byteswap.h>
//#include <architecture/byte_order.h>
#ifndef __linux__
#include <machine/endian.h>
#endif

#include <inttypes.h>

#if __DARWIN_BYTE_ORDER == __DARWIN_LITTLE_ENDIAN

__attribute__((always_inline)) uint16_t host_to_le16(uint16_t val)
{
    return val;
}

__attribute__((always_inline)) uint32_t host_to_le32(uint32_t val)
{
    return val;
}

#else

__attribute__((always_inline)) uint16_t host_to_le16(uint16_t val)
{
    return ( (((val) >> 8) & 0x00FF) | (((val) << 8) & 0xFF00) );
}

__attribute__((always_inline)) uint32_t host_to_le32(uint32_t val)
{
    return ( (((val) >> 24) & 0x000000FF) | (((val) >>  8) & 0x0000FF00) | \
            (((val) <<  8) & 0x00FF0000) | (((val) << 24) & 0xFF000000) );
}

#endif
