set ip img_flip
open_project ${ip}
set_top ${ip}
add_files ${ip}/${ip}.cpp
add_files -tb ${ip}/${ip}_test.cpp
open_solution "solution1"
set_part {xczu7ev-ffvc1156-2-i}
create_clock -period 3.3
csynth_design
export_design -format ip_catalog -description "image flip ip" -display_name "${ip}"
exit
