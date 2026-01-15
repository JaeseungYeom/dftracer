import sys
import logging
import os
from mpi4py import MPI
from time import time
from dftracer.python import dftracer, dft_fn
import random
import statistics

log_inst = dftracer.initialize_log(logfile=None, data_dir=None, process_id=-1)

class Timer:
    def __init__(self):
        self.elapsed_time = 0
        self.start = 0
    def resume_time(self):
        self.start = time()

    def pause_time(self):
        self.elapsed_time += time() - self.start


def main(argc, argv):
    if argc < 5:
        raise Exception("python overhead.py <TEST_DIR> <NUM_OPS> <TRANSFER_SIZE> [--distribution]")
    logging.info(f"{argv}")
    dir = argv[2]
    num_operations = int(argv[3])
    transfer_size = int(argv[4])
    use_distribution = argc > 5 and argv[5] == "--distribution"
    
    logging.basicConfig(filename=f'{os.getcwd()}/overhead_python_{MPI.COMM_WORLD.rank}.log', encoding='utf-8', level=logging.DEBUG)
    path = f"{dir}/file_{MPI.COMM_WORLD.rank}-{MPI.COMM_WORLD.size}.bat"
    
    # Setup operation sizes distribution if enabled
    operation_sizes = []
    if use_distribution:
        # Create a mixed distribution: 80% small ops (<64K), 20% large ops (>=64K)
        small_ops = (num_operations * 80) // 100
        large_ops = num_operations - small_ops
        
        # Generate small operations
        for i in range(small_ops):
            operation_sizes.append(random.randint(1024, 65536))
        
        # Generate large operations
        for i in range(large_ops):
            operation_sizes.append(random.randint(65536, transfer_size))
        
        # Shuffle the operations
        random.shuffle(operation_sizes)
    
    iteration_times = []
    num_iterations = 10
    
    for iter_num in range(num_iterations):
        MPI.COMM_WORLD.barrier()
        if MPI.COMM_WORLD.rank == 0:
            logging.info(f"Starting iteration {iter_num}")
        
        operation_time = Timer()
        operation_time.resume_time()
        f = open(path, "w+")
        operation_time.pause_time()
        
        for i in range(num_operations):
            write_size = operation_sizes[i] if use_distribution else transfer_size
            buffer = 'w' * write_size
            
            operation_time.resume_time()
            f.write(buffer)
            operation_time.pause_time()

        operation_time.resume_time()
        f.close()
        operation_time.pause_time()
        
        total_time = MPI.COMM_WORLD.allreduce(operation_time.elapsed_time, op=MPI.SUM)
        if MPI.COMM_WORLD.rank == 0:
            iteration_times.append(total_time)
            logging.info(f"Iteration {iter_num} time: {total_time}")
        
        MPI.COMM_WORLD.barrier()
        if os.path.exists(path):
            os.remove(path)
    
    if MPI.COMM_WORLD.rank == 0:
        avg_time = statistics.mean(iteration_times)
        std_dev = statistics.stdev(iteration_times) if len(iteration_times) > 1 else 0.0
        print(f"[DFTRACER PRINT],{MPI.COMM_WORLD.size},{num_operations},{transfer_size},{avg_time},{std_dev},{'yes' if use_distribution else 'no'}")
    MPI.COMM_WORLD.barrier()
    log_inst.finalize()

if __name__ == "__main__":
    argc = len(sys.argv)
    argv = sys.argv
    main(argc, argv)