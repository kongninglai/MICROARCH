# Workload Suites

Small realistic workloads for the processor simulator and Verilog tests.

Each workload keeps code below `0x1000` and appends physical memory
initialization blocks for every data/stack location it can read.

## TLB-aware memory regions

- Code: VPN `0x00000` -> PFN `0`, physical `0x0000`, read-only.
- DS data: VPN `0x02000` -> PFN `2`, physical `0x2000`.
- ES data: VPN `0x04000` -> PFN `5`, physical `0x5000`.
- SS stack: VPN `0x0b000` -> PFN `4`, physical `0x4000`.
- FS data: VPN `0x0a000` -> PFN `5`, physical `0x5000`.

The last two TLB entries are reserved for I/O and are not used by these
workloads.

## Current workloads

- `memcpy_stream`: stream-copy 64 bytes from DS to ES through a called
  `rep movsd` worker, then checksum the copied ES buffer in a loop.
- `memcmp_scan`: compare two 64-byte buffers through a called `repe cmpsd`
  worker, exiting after a late mismatch and storing the post-scan state.
- `histogram_count`: count zero-valued dword records in a small event stream.
- `checksum_fold`: compute an additive checksum and carry count over a block.
- `linked_list_walk`: pointer-chase through memory-backed nodes and sum values.
- `binary_search`: search a sorted dword table with shifts and conditional jumps.
- `call_stack_tree`: nested calls and stack traffic while summing memory leaves.
- `atomic_counter_lock`: acquire/update/release a memory lock with `cmpxchg`.
- `vector_image_blend`: average two 8-byte pixel blocks with `pavgb`.
- `vector_audio_mix`: packed word add plus saturating byte pack.
- `vector_accumulate`: packed dword counter accumulation with `paddd`.
- `page_stride_probe`: near-page-end strided SIB addressing over DS memory.
- `long_stream_verify`: longer 256-byte copy, checksum, and `repe cmpsd`
  verification pipeline.
- `long_atomic_counter`: 32 lock acquire/update/release iterations using
  `cmpxchg`.
- `long_vector_blend`: 16 MMX `pavgb` iterations over 128 bytes.
