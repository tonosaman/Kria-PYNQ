#include <ap_fixed.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>

#define LEN_IN 32

void img_flip(ap_uint<8> in[LEN_IN][LEN_IN], ap_uint<8> out[LEN_IN][LEN_IN]);
