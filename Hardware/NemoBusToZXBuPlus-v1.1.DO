# ACCEL PCB V19.02.9589 Auto-Generated DO File
# Sun Sep 20 21:58:57 2020
#
bestsave on $\best.w
status_file $\progress.sts
#
unit mil
#
grid wire 5.000000 
grid via 5.000000 20-30mil_E
#
rule pcb (width 10.0)
#
bus diagonal
route 50
clean 4
route 50 16
clean 4
filter 5
route 100 16
clean 2
delete conflicts
#
write wire $\NemoBusToZXBuPlus-v1.1.w
spread 
miter
write wire $\NemoBusToZXBuPlus-v1.1.m
#
write session $\NemoBusToZXBuPlus-v1.1.ses
report status $\NemoBusToZXBuPlus-v1.1.sts
