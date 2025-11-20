# Text Classification Experiments

This directory contains experimental implementations and tests of various text classification, clustering, and natural language processing libraries in Ruby.

## Overview

These experiments explore different approaches to text classification, from traditional Bayesian methods to Support Vector Machines (SVM) and modern deep learning techniques. The primary focus is comparing Ruby gems and their effectiveness for various NLP tasks.

## Classification Approaches Tested

### Bayesian Classifiers

Bayesian classifiers use probabilistic methods based on Bayes' theorem to categorize text.

#### **nbayes** - `nbayes_test.rb`
- Simple, lightweight Naive Bayes implementation
- Tests SPAM vs HAM email classification
- Supports model persistence via YAML
- Good for: Simple binary classification tasks

#### **bayesball** - `bayesball_test.rb`
- Sports classification (basketball, baseball, racquetball, football)
- Trains on large text corpus (Wikipedia-style content)
- Tests classification of short phrases based on domain-specific vocabulary
- Good for: Multi-class text categorization with substantial training data

#### **classifier-reborn** - `classifier_reborn_*.rb`
- Modern fork of the classic Classifier gem
- Supports both Bayes and LSI (Latent Semantic Indexing)
- **classifier_reborn_demo.rb**: Basic demonstration with interesting/uninteresting categories
- **classifier_reborn_bayes.rb**: Bayesian classification experiments
- **classifier_reborn_lsi.rb**: Semantic similarity and document clustering
- Auto-categorization feature for dynamic category creation
- Good for: General-purpose classification with semantic analysis

#### **lurn** - `lurn_test.rb`
- Machine learning toolkit with vectorization support
- Uses Bernoulli Naive Bayes with feature vectorization
- Separates vectorization from model training
- Tests computers vs sports classification
- Good for: Projects requiring custom feature engineering

#### **stuff-classifier** - `stuff_classifier_test.rb`
- Supports both Naive Bayes and TF-IDF implementations
- Persistent storage via SQLite database
- Word stemming and stop-word filtering
- Cats vs Dogs classification example
- Note: Contains compatibility fix for Ruby 3.x (`File.exists?` → `File.exist?`)
- Good for: Production systems requiring data persistence

#### **reclassifier** - `reclassifier_test.rb`
- Successor to the original Classifier gem
- Supports both Bayes and LSI methods
- Good for: Legacy compatibility

#### **omnicat-bayes** - `omnicat_classifier_bayes.rb`
- Part of the Omnicat framework
- Good for: Standardized classifier interfaces

### Support Vector Machines (SVM)

SVMs find optimal hyperplanes to separate classes in high-dimensional space.

#### **libsvm** - `libsvm_test.rb`
- Ruby wrapper for the popular LIBSVM library
- Two classification examples:
  1. Joke classifier (funny vs not funny)
  2. Sports classifier (basketball, baseball, racquetball, football)
- Manual feature vectorization from word dictionaries
- Good for: Complex multi-class problems with clear boundaries

#### **libsvmffi** - `libsvmffi_test.rb`
- FFI-based interface to LIBSVM
- Lower-level access to SVM functionality
- Good for: Performance-critical applications

#### **SVM Training Script** - `train_svm_classifier.rb`
- Comprehensive SVM training pipeline
- Good for: Custom SVM model development

### Deep Learning & Neural Network Approaches

#### **fasttext** - `fasttext/`
- Facebook's fastText library for efficient text classification
- Subword information and word embeddings
- Validation/test split support
- Good for: Large-scale text classification with limited training data

### Named Entity Recognition & Advanced NLP

#### **MITIE** - `mitie_test.rb`
- MIT Information Extraction library
- Three major capabilities:
  1. **Named Entity Recognition (NER)**: Identify people, organizations, locations
  2. **Binary Relation Detection**: Extract relationships (e.g., "PERSON was born in LOCATION")
  3. **Text Categorization**: Sentiment analysis and topic classification
- Supports custom model training for all three tasks
- Includes 21 pre-trained relation detectors for English
- Pre-trained models required (stored in external directory)
- Good for: Complex entity extraction and relationship mapping

### Clustering Algorithms

#### **K-means Clusterer** - `kmeans_clusterer_test.rb`
- Unsupervised document clustering
- Uses custom `BagOfWords` class for feature extraction
- IDF (Inverse Document Frequency) weighting
- CLI interface with configurable parameters:
  - `--max_runs`: Maximum clustering iterations
  - `--target_cluster_size`: Number of clusters to create
  - `--files`: Input documents
- Silhouette score for cluster quality assessment
- Groups similar documents without pre-defined categories
- Good for: Discovering natural document groupings, topic modeling

## Practical Applications

### Auto-Organizer - `auto_organizer/organizer.rb`

Automated file organization system that watches a directory and classifies incoming files.

**Features:**
- Uses `classifier-reborn` Bayes classifier
- Monitors directory for new files using the `listen` gem
- Automatically categorizes and moves files to topic-based subdirectories
- Supports both supervised (pre-trained) and unsupervised modes
- Includes LSI topic extraction for automatic category discovery

**Use case:** Organizing downloads, documents, or user uploads by content without manual sorting.

## Training Data

Located in `training_data/` directory with animal-themed text samples:

- **cats/** - Information about domestic cats
- **dogs/** - Information about dogs and breeds
- **horses/** - Equine information
- **cows/** - Bovine information
- **camels/** - Camelid information
- **unknown_*.txt** - Test samples for classification

This consistent dataset allows fair comparison across different classification approaches.

## Dependencies & System Requirements

### Ruby Gems
See `gems.rb` for complete dependency list. Major requirements include:

- **Databases**: `activerecord`, `pg`, `rethinkdb`, `nobrainer`, `sqlite3`
- **Utilities**: `debug_me`, `amazing_print`, `cli_helper`, `minitest`
- **Bayesian**: `nbayes`, `bayesball`, `lurn`, `omnicat-bayes`, `classifier-reborn`, `stuff-classifier`, `reclassifier`
- **SVM**: `libsvm-ruby-swig`, `libsvmffi`, `rb-libsvm`, `hoatzin`, `svm_helper`, `svmlab`, `omnicat-svm`
- **Clustering**: `kmeans-clusterer`
- **NLP/ML**: `mitie`, `fasttext`, `crystalruby`
- **Math**: `numo-narray`, `numo-linalg`

### System Packages (Fedora/macOS)
- `catdoc` - MS Word document conversion
- `html2txt` - HTML to text conversion
- `pdf2txt` - PDF text extraction
- `sqlite3` - SQLite database
- `lapack`, `openblas` - Linear algebra libraries
- `libsvm` - SVM library

## Running the Experiments

### Individual Tests

```bash
# Bayesian classifiers
./nbayes_test.rb
./bayesball_test.rb
./classifier_reborn_demo.rb
./stuff_classifier_test.rb
./lurn_test.rb

# Support Vector Machines
./libsvm_test.rb
./libsvmffi_test.rb

# Advanced NLP
./mitie_test.rb

# Clustering
./kmeans_clusterer_test.rb --files training_data/**/*.txt --target_cluster_size 5

# FastText
cd fasttext && ./fasttest.rb
```

### Batch Execution

```bash
./run.rb              # Run all tests
./run_tests.sh        # Shell script runner
```

## Key Findings & Recommendations

### Best for Production Use
- **stuff-classifier**: Persistent storage, mature API
- **bayesball**: Clean interface, good documentation
- **libsvm**: Industry-standard SVM implementation

### Best for Research/Experimentation
- **classifier-reborn**: Active development, modern features
- **lurn**: Flexible feature engineering
- **mitie**: Comprehensive NLP capabilities

### Best for Specific Use Cases
- **Email filtering**: nbayes, stuff-classifier
- **Topic classification**: bayesball, classifier-reborn
- **Semantic similarity**: classifier-reborn (LSI)
- **Entity extraction**: mitie
- **Document clustering**: kmeans-clusterer
- **Large-scale classification**: fasttext

## Performance Considerations

- **Bayesian classifiers**: Fast training, fast prediction, moderate accuracy
- **SVM**: Slower training, fast prediction, high accuracy
- **K-means**: Iterative, requires tuning, no labels needed
- **MITIE**: Requires large pre-trained models, high memory usage
- **FastText**: Fast with good accuracy, requires substantial training data

## Model Persistence

Several classifiers support saving trained models:

- **nbayes**: YAML dump
- **stuff-classifier**: SQLite database
- **mitie**: Binary `.dat` files
- **fasttext**: Native model format

Trained models in this directory:
- `stuff_classifier.db` - Cats/Dogs classifier
- `tdv_text_categorization_model.dat` - MITIE sentiment model
- `tdv_binary_relation_detector.svm` - MITIE relation detector

## Future Experiments

Potential areas for exploration:

- [ ] CrystalRuby integration for performance-critical classifiers
- [ ] Comparative benchmarking across all classifiers
- [ ] Deep learning approaches (TensorFlow, PyTorch via Ruby bindings)
- [ ] Real-time streaming classification
- [ ] Multi-label classification
- [ ] Cross-validation and accuracy metrics
- [ ] Feature importance analysis
- [ ] Ensemble methods combining multiple classifiers

## Notes

- Some gems may require specific Ruby versions or system libraries
- MITIE requires downloading large pre-trained models separately
- K-means results vary between runs (use multiple runs and select best)
- The `system_package` helper in `gems.rb` requires the `system_package` gem from MadBomber/lib_ruby

## References

- Naive Bayes: Probabilistic classification based on Bayes' theorem
- SVM: Maximum-margin classification using kernel methods
- LSI: Singular Value Decomposition for semantic analysis
- TF-IDF: Term frequency-inverse document frequency weighting
- K-means: Centroid-based clustering algorithm
- FastText: Subword-based neural text classification
- MITIE: Structured prediction and information extraction
