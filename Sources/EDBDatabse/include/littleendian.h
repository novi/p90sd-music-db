//#include <byteswap.h>
//#include <architecture/byte_order.h>
#include <machine/endian.h>

#if __DARWIN_BYTE_ORDER == __DARWIN_LITTLE_ENDIAN
#define host_to_le16(val) val
#define host_to_le32(val) val
#else

#define host_to_le16(val) \
( (((val) >> 8) & 0x00FF) | (((val) << 8) & 0xFF00) )

#define host_to_le32(val) \
( (((val) >> 24) & 0x000000FF) | (((val) >>  8) & 0x0000FF00) | \
(((val) <<  8) & 0x00FF0000) | (((val) << 24) & 0xFF000000) )

#endif
