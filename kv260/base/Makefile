# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

overlay_name := base
version := 2.7

all: pynq_hls block_design bitstream check_timing
	@echo
	@tput setaf 2 ; echo "Built $(overlay_name) successfully!"; tput sgr0;
	@echo

pynq_hls:
	make -C ../../pynq/boards/ZCU104/base/ hls_ip
	vivado -mode batch -source ./ip/build_hls_ip.tcl -notrace

block_design:
	vivado -mode batch -notrace \
		-source $(overlay_name).tcl \
		-source add_img_flip.tcl

bitstream:
	vivado -mode batch -source build_bitstream.tcl -notrace

check_timing:
	vivado -mode batch -source check_timing.tcl -notrace

clean:
	rm -rf *.jou *.log NA .Xil *.zip

zip: dtbo
	zip kv260_$(overlay_name)_$(version).zip $(overlay_name).bit $(overlay_name).hwh $(overlay_name).dtbo LICENSE

dtbo:
	make -C dts/
	cp dts/$(overlay_name).dtbo .

distclean: clean
	rm -rf $(overlay_name) $(overlay_name).bit $(overlay_name).hwh $(overlay_name).xsa
