/**
 * @file competition2.cpp
 * @author Hussein Hazimeh
 */

#include <iostream>
#include <string>
#include <vector>
#include "meta/caching/all.h"
#include "meta/classify/classifier/all.h"
#include "meta/index/forward_index.h"
using namespace meta;

int main(int argc, char* argv[])
{
    if (argc != 2)
    {
        std::cout << "Usage:\t" << argv[0] << " config.toml" << std::endl;
        return 1;
    }


    std::ofstream submission;
    submission.open("Assignment3/competition2.txt");
    if (!submission.is_open())
    {
        std::cout<<"Problem writing the output to the system. Make sure the program has enough writing privileges. Quiting..."<<std::endl;
        return 0;
    }


	auto config = cpptoml::parse_file(argv[1]);
	auto fidx = meta::index::make_index<index::memory_forward_index>(*config); // Pointer to the forward index


	auto class_config = config->get_table("classifier"); // Read the classifier type from config.toml
	//auto classifier = meta::classify::make_classifier(*class_config, fidx); // Pointer to the classifier
		
	
	auto docs = fidx->docs();
    auto test_begin = docs.begin() + 546;
	
	classify::multiclass_dataset training_dataset{fidx , docs.begin(), test_begin};
	classify::multiclass_dataset testing_dataset{fidx , test_begin,docs.end()};
	
	classify::multiclass_dataset_view train(training_dataset);
	classify::multiclass_dataset_view test(testing_dataset);
	
	auto cls = classify::make_classifier(*class_config, train);

	
	auto confusion_mtrx = cls->test(train); // Create the confusion matrix for the training data
	std::cout<<"Below are the statistics on the training data: "<<std::endl;
	confusion_mtrx.print();
	confusion_mtrx.print_stats();


	for (const auto& doc : testing_dataset) // Loop over the testing document IDs (i.e. the last 200)
	{
		submission<<cls->classify(doc.weights)<<'\n'; // Classify each document and print its label to file
	}

	submission.close();
    return 0;
}