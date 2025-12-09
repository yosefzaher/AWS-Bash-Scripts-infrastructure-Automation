#!/bin/bash
sudo fio --name=write_iops --size=4G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 --verify=0 --bs=4K \
 --iodepth=256 --rw=randwrite --group_reporting=1 --iodepth_batch_submit=256 --iodepth_batch_complete_max=256

# Results :-
################################################################################################################################
# write_iops: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=256
# fio-3.36
# Starting 1 process
# write_iops: Laying out IO file (1 file / 4096MiB)
# Jobs: 1 (f=1): [w(1)][100.0%][w=12.0MiB/s][w=3079 IOPS][eta 00m:00s]
# write_iops: (groupid=0, jobs=1): err= 0: pid=2090: Fri Oct 24 13:41:49 2025
#   write: IOPS=2998, BW=11.7MiB/s (12.3MB/s)(704MiB/60049msec); 0 zone resets
#     slat (usec): min=9, max=65313, avg=47943.84, stdev=16015.98
#     clat (usec): min=6, max=151414, avg=29223.84, stdev=28638.45
#      lat (msec): min=11, max=193, avg=77.18, stdev=27.37
#     clat percentiles (usec):
#      |  1.00th=[    13],  5.00th=[    16], 10.00th=[    18], 20.00th=[    20],
#      | 30.00th=[    22], 40.00th=[  7767], 50.00th=[ 20579], 60.00th=[ 36439],
#      | 70.00th=[ 63701], 80.00th=[ 64226], 90.00th=[ 64226], 95.00th=[ 64750],
#      | 99.00th=[ 77071], 99.50th=[ 83362], 99.90th=[101188], 99.95th=[127402],
#      | 99.99th=[128451]
#    bw (  KiB/s): min=10752, max=12376, per=100.00%, avg=12009.32, stdev=618.51, samples=120
#    iops        : min= 2688, max= 3094, avg=3002.32, stdev=154.65, samples=120
#   lat (usec)   : 10=0.10%, 20=26.62%, 50=6.79%, 100=0.91%, 500=0.14%
#   lat (usec)   : 750=0.28%, 1000=0.21%
#   lat (msec)   : 2=0.86%, 4=1.50%, 10=4.64%, 20=7.32%, 50=15.70%
#   lat (msec)   : 100=34.86%, 250=0.10%
#   cpu          : usr=0.35%, sys=3.87%, ctx=130736, majf=0, minf=36
#   IO depths    : 1=0.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=100.0%
#      submit    : 0=0.0%, 4=2.1%, 8=2.1%, 16=3.1%, 32=7.0%, 64=14.6%, >=64=71.3%
#      complete  : 0=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=99.9%
#      issued rwts: total=0,180031,0,0 short=0,0,0,0 dropped=0,0,0,0
#      latency   : target=0, window=0, percentile=100.00%, depth=256

# Run status group 0 (all jobs):
#   WRITE: bw=11.7MiB/s (12.3MB/s), 11.7MiB/s-11.7MiB/s (12.3MB/s-12.3MB/s), io=704MiB (738MB), run=60049-60049msec

# Disk stats (read/write):
#   xvda: ios=2/189077, sectors=16/1536360, merge=0/2962, ticks=15/3957964, in_queue=3957979, util=91.39%
################################################################################################################################

sudo fio --name=write_iops --size=4G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 --verify=0 --bs=256K \
 --iodepth=256 --rw=randwrite --group_reporting=1 --iodepth_batch_submit=256 --iodepth_batch_complete_max=256

# Results :-
################################################################################################################################
# write_iops: (g=0): rw=randwrite, bs=(R) 256KiB-256KiB, (W) 256KiB-256KiB, (T) 256KiB-256KiB, ioengine=libaio, iodepth=256
# fio-3.36
# Starting 1 process
# Jobs: 1 (f=1): [w(1)][100.0%][w=168MiB/s][w=671 IOPS][eta 00m:00s]
# write_iops: (groupid=0, jobs=1): err= 0: pid=2172: Fri Oct 24 13:53:51 2025
#   write: IOPS=498, BW=125MiB/s (131MB/s)(7533MiB/60124msec); 0 zone resets
#     slat (msec): min=2, max=518, avg=317.71, stdev=112.20
#     clat (usec): min=9, max=615663, avg=124638.10, stdev=160150.11
#      lat (msec): min=39, max=980, avg=442.33, stdev=144.87
#     clat percentiles (usec):
#      |  1.00th=[    13],  5.00th=[    16], 10.00th=[    18], 20.00th=[    20],
#      | 30.00th=[    22], 40.00th=[    25], 50.00th=[ 40109], 60.00th=[104334],
#      | 70.00th=[170918], 80.00th=[267387], 90.00th=[446694], 95.00th=[463471],
#      | 99.00th=[467665], 99.50th=[484443], 99.90th=[517997], 99.95th=[522191],
#      | 99.99th=[549454]
#    bw (  KiB/s): min=114176, max=239070, per=99.41%, avg=127538.82, stdev=33614.34, samples=120
#    iops        : min=  446, max=  933, avg=497.93, stdev=131.32, samples=120
#   lat (usec)   : 10=0.02%, 20=21.72%, 50=21.86%, 100=1.31%
#   lat (msec)   : 10=0.69%, 50=8.56%, 100=5.12%, 250=20.57%, 500=20.39%
#   lat (msec)   : 750=0.21%
#   cpu          : usr=0.78%, sys=2.16%, ctx=63361, majf=0, minf=36
#   IO depths    : 1=0.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=2.6%, 32=13.7%, >=64=83.6%
#      submit    : 0=0.0%, 4=0.4%, 8=1.2%, 16=4.8%, 32=6.8%, 64=13.2%, >=64=73.6%
#      complete  : 0=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.8%, >=64=99.2%
#      issued rwts: total=0,29999,0,0 short=0,0,0,0 dropped=0,0,0,0
#      latency   : target=0, window=0, percentile=100.00%, depth=256

# Run status group 0 (all jobs):
#   WRITE: bw=125MiB/s (131MB/s), 125MiB/s-125MiB/s (131MB/s-131MB/s), io=7533MiB (7899MB), run=60124-60124msec

# Disk stats (read/write):
#   xvda: ios=0/76388, sectors=0/16142912, merge=0/253634, ticks=0/3958662, in_queue=3958662, util=94.36%
################################################################################################################################
