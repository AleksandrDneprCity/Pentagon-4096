# ACCEL PCB V19.02.9589 Auto-Generated DO File
# Wed Sep 16 02:25:21 2020
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
write wire $\MainBoard-v8.1.2.w
spread 
miter
write wire $\MainBoard-v8.1.2.m
#
write session $\MainBoard-v8.1.2.ses
report status $\MainBoard-v8.1.2.sts
