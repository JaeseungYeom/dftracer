#!/usr/bin/env python3
"""
Comprehensive Python API Coverage Test
Tests all Python API functions provided by dftracer
"""


import os
import sys
import time
import argparse

try:
    from dftracer.python import dftracer, dft_fn
except ImportError:
    print("ERROR: Could not import dftracer. Make sure it's installed.")
    sys.exit(1)

# Use recommended API initialization
log_inst = dftracer.initialize_log(logfile=None, data_dir=None, process_id=-1)


@dft_fn.log
def test_function_decorator():
    """Test @dft_fn decorator for automatic function tracing"""
    time.sleep(0.001)
    return "decorated"


def test_manual_function_tracing():
    """Test manual function entry/exit logging"""
    log_inst.enter_function()
    time.sleep(0.001)
    log_inst.exit_function()


def test_region_tracing():
    """Test region-based tracing"""
    # Test region context manager
    with log_inst.region("TEST_REGION"):
        time.sleep(0.001)

    # Test manual region start/end
    log_inst.region_start("MANUAL_REGION")
    time.sleep(0.001)
    log_inst.region_end("MANUAL_REGION")


def test_event_logging():
    """Test custom event logging"""
    log_inst.enter_event()
    start = log_inst.get_time()
    time.sleep(0.001)
    end = log_inst.get_time()
    log_inst.log_event("CUSTOM_EVENT_1", "cat1", start, end - start)
    log_inst.exit_event()
    log_inst.log_event("CUSTOM_EVENT_2", "cat2", start, end - start)


def test_io_operations(data_dir):
    """Test I/O operations with tracing"""
    filepath = os.path.join(data_dir, "python_api_test.dat")

    with log_inst.region("FILE_WRITE"):
        with open(filepath, "w") as f:
            f.write("Python test data\n")

    with log_inst.region("FILE_READ"):
        with open(filepath, "r") as f:
            data = f.read()

    # Cleanup
    if os.path.exists(filepath):
        os.remove(filepath)


def test_nested_operations():
    """Test nested function and region tracing"""
    log_inst.enter_function()

    with log_inst.region("OUTER"):
        time.sleep(0.001)
        with log_inst.region("MIDDLE"):
            time.sleep(0.001)
            with log_inst.region("INNER"):
                time.sleep(0.001)

    log_inst.exit_function()


def test_disable_enable():
    """Test disabling and enabling tracing"""
    # Should be traced
    log_inst.enter_function()
    log_inst.exit_function()

    # Disable tracing
    log_inst.disable()

    # Should NOT be traced
    log_inst.enter_function()
    log_inst.exit_function()

    # Re-enable
    log_inst.enable()

    # Should be traced again
    log_inst.enter_function()
    log_inst.exit_function()


def main():
    parser = argparse.ArgumentParser(description="Python API Coverage Test")
    parser.add_argument(
        "--data_dir", type=str, required=True, help="Directory for test data files"
    )
    args = parser.parse_args()

    # Ensure data directory exists
    os.makedirs(args.data_dir, exist_ok=True)

    print("Running Python API coverage tests...")

    # Run all test functions
    test_function_decorator()
    test_manual_function_tracing()
    test_region_tracing()
    test_event_logging()
    test_io_operations(args.data_dir)
    test_nested_operations()
    test_disable_enable()

    print("Python API coverage tests completed")

    log_inst.finalize()

    return 0


if __name__ == "__main__":
    sys.exit(main())
