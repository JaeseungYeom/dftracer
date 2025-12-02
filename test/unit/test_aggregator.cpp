#include <dftracer/core/aggregator/aggregator.h>
#include <dftracer/core/aggregator/rules.h>
#include <dftracer/core/utils/configuration_manager.h>
#include <dftracer/core/common/singleton.h>

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <string>

using namespace dftracer;

void test_rules_parsing() {
    std::cout << "=== Test: Rules Parsing ===\n" << std::endl;
    
    Rules rules;
    
    // Test adding different types of rules
    rules.addRule("category == 'posix'");
    rules.addRule("event_name LIKE 'read*'");
    rules.addRule("category == 'posix' AND event_name == 'read'");
    rules.addRule("duration > 1000");
    
    std::cout << "✓ Rules parsing test passed\n" << std::endl;
}

void test_rules_evaluation() {
    std::cout << "=== Test: Rules Evaluation ===\n" << std::endl;
    
    Rules inclusion_rules;
    inclusion_rules.addRule("category == 'posix'");
    
    Metadata metadata;
    metadata.insert_or_assign("test_key", std::string("test_value"));
    
    // Create AggregatedKey for testing
    AggregatedKey key("posix", "read", 0, 0, 0, &metadata, nullptr, nullptr);
    
    // Test if rules match
    bool matches = inclusion_rules.satisfies(&key);
    assert(matches == true);
    
    // Test with different category
    AggregatedKey key2("stdio", "write", 0, 0, 0, &metadata, nullptr, nullptr);
    bool matches2 = inclusion_rules.satisfies(&key2);
    assert(matches2 == false);
    
    std::cout << "✓ Rules evaluation test passed\n" << std::endl;
}

void test_like_pattern_matching() {
    std::cout << "=== Test: LIKE Pattern Matching ===\n" << std::endl;
    
    Rules rules;
    rules.addRule("category LIKE 'pos*'");
    
    Metadata metadata;
    metadata.insert_or_assign("test_key", std::string("test_value"));
    
    AggregatedKey key("posix", "read", 0, 0, 0, &metadata, nullptr, nullptr);
    
    bool matches = rules.satisfies(&key);
    assert(matches == true);
    
    AggregatedKey key2("stdio", "read", 0, 0, 0, &metadata, nullptr, nullptr);
    bool matches2 = rules.satisfies(&key2);
    assert(matches2 == false);
    
    std::cout << "✓ LIKE pattern matching test passed\n" << std::endl;
}

void test_aggregator_basic() {
    std::cout << "=== Test: Aggregator Basic Functionality ===\n" << std::endl;
    
    // Configure aggregation to FULL mode
    setenv("DFTRACER_ENABLE_AGGREGATION", "true", 1);
    setenv("DFTRACER_AGGREGATION_TYPE", "FULL", 1);
    setenv("DFTRACER_TRACE_INTERVAL_MS", "1000", 1);
    
    auto config = Singleton<ConfigurationManager>::get_instance();
    auto aggregator = Singleton<Aggregator>::get_instance();
    
    Metadata metadata;
    metadata.insert_or_assign("test", std::string("value"));
    
    ThreadID tid = 1;
    AggregatedKey key("posix", "read", 1000000, 5000, tid, &metadata, nullptr, nullptr);
    
    // In FULL mode, all events should be aggregated
    assert(aggregator->should_aggregate(&key) == true);
    
    // Test aggregate method
    aggregator->aggregate(key);
    
    // Get aggregated data
    AggregatedDataType data;
    aggregator->get_previous_aggregations(data, true);
    
    std::cout << "✓ Aggregator basic test passed\n" << std::endl;
    
    unsetenv("DFTRACER_ENABLE_AGGREGATION");
    unsetenv("DFTRACER_AGGREGATION_TYPE");
    unsetenv("DFTRACER_TRACE_INTERVAL_MS");
}

void test_aggregator_selective() {
    std::cout << "=== Test: Aggregator Selective Mode ===\n" << std::endl;
    
    // Configure selective aggregation
    setenv("DFTRACER_ENABLE_AGGREGATION", "true", 1);
    setenv("DFTRACER_AGGREGATION_TYPE", "SELECTIVE", 1);
    setenv("DFTRACER_AGGREGATION_INCLUSION_RULES", "category == 'posix'", 1);
    setenv("DFTRACER_TRACE_INTERVAL_MS", "1000", 1);
    
    auto config = Singleton<ConfigurationManager>::get_instance();
    auto aggregator = Singleton<Aggregator>::get_instance();
    
    Metadata metadata1;
    metadata1.insert_or_assign("test", std::string("value"));
    
    ThreadID tid = 1;
    
    // This should be aggregated (matches inclusion rule)
    AggregatedKey key1("posix", "read", 1000000, 5000, tid, &metadata1, nullptr, nullptr);
    assert(aggregator->should_aggregate(&key1) == true);
    
    // This should not be aggregated (doesn't match inclusion rule)
    Metadata metadata2;
    metadata2.insert_or_assign("test", std::string("value"));
    AggregatedKey key2("stdio", "write", 1000000, 3000, tid, &metadata2, nullptr, nullptr);
    assert(aggregator->should_aggregate(&key2) == false);
    
    std::cout << "✓ Aggregator selective mode test passed\n" << std::endl;
    
    unsetenv("DFTRACER_ENABLE_AGGREGATION");
    unsetenv("DFTRACER_AGGREGATION_TYPE");
    unsetenv("DFTRACER_AGGREGATION_INCLUSION_RULES");
    unsetenv("DFTRACER_TRACE_INTERVAL_MS");
}

int main() {
    std::cout << "\n=== Running Aggregator Unit Tests ===\n" << std::endl;
    
    try {
        test_rules_parsing();
        test_rules_evaluation();
        test_like_pattern_matching();
        test_aggregator_basic();
        test_aggregator_selective();
        
        std::cout << "\n=== All Aggregator Tests Passed ===\n" << std::endl;
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Test failed with exception: " << e.what() << std::endl;
        return 1;
    }
}
