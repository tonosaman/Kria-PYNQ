#include "img_flip.hpp"

const int c_size = LEN_IN;

void img_flip(ap_uint<8> in[LEN_IN][LEN_IN], ap_uint<8> out[LEN_IN][LEN_IN]) {
#pragma HLS INTERFACE mode=s_axilite port=return bundle=ctrl
#pragma HLS INTERFACE mode=s_axilite port=in bundle=ctrl
#pragma HLS INTERFACE mode=s_axilite port=out bundle=ctrl
#pragma HLS INTERFACE mode=m_axi port=in offset=slave bundle=gmem depth=c_size
#pragma HLS INTERFACE mode=m_axi port=out offset=slave bundle=gmem depth=c_size
	for (int it0 = 0; it0 < LEN_IN; ++it0) {
#pragma HLS LOOP_TRIPCOUNT min=c_size max=c_size
		for (int it1 = 0; it1 < LEN_IN; ++it1) {
#pragma HLS LOOP_TRIPCOUNT min=c_size max=c_size
			out[it0][it1] = in[it0][LEN_IN - 1 - it1];
		}
	}
}
