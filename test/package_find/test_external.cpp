#include <dftracer/dftracer.h>

#include <iostream>

int main() {
  // Initialize DFTracer
  DFTRACER_CPP_INIT(nullptr, nullptr, nullptr);

  // Test basic functionality
  DFTRACER_CPP_METADATA(test_meta, "app", "external_test");

  {
    DFTRACER_CPP_REGION(TEST_REGION);
    std::cout << "External test application successfully linked with dftracer"
              << std::endl;
  }

  DFTRACER_CPP_FINI();
  return 0;
}
