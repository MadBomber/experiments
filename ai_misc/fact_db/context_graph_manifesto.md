# The Context Graph Manifesto

**Author:** Daniel Davis ([@TrustSpooky](https://x.com/TrustSpooky))
**Source:** [X/Twitter Post](https://x.com/TrustSpooky/status/2006481858289361339)

---

When Mark Adams and I began working on what has become TrustGraph over 2 years ago, we knew that graph structures would be instrumental in realizing the potential of AI technology, specifically LLMs.

I've never been particularly fond of the term RAG. In fact, we've always shied away from labeling TrustGraph a "RAG platform" because it does so much more than that. And that's always been the point - to realize the potential of LLMs, you need more than just RAG.

And no, I'm not about to say all you need are graphs. I've never been fond of the term GraphRAG either (especially after Microsoft co-opted the term), because again, you need more than just graph structures.

Context Engineering has always felt like a better fit to me, but it just hasn't seemed to gain traction, until perhaps now? My attention was grabbed by my friend Kirk Marple's recent post, *The Context Layer AI Agents Actually Need*, which was written in response to a post Jaya Gupta and Ashu Garg of Foundation Capital that you might have read - *AI's trillion-dollar opportunity: Context graphs*.

## So... What is a Context Graph?

Considering that we've been working on this very problem for a bit and TrustGraph has been open source for nearly eighteen months, I feel qualified to offer a definition. Put simply, a context graph is a triples-representation of data that is optimized for usage with AI. That seems simple enough, right? That's what I thought when I started on the knowledge graph journey years ago as well...

## The Ambiguity Problem: What is a Knowledge Graph?

Good question. No, seriously—sit around a table of knowledge graph experts, ask that question, and just wait for the arguments to begin. And no, I'm very serious about the arguments part. The knowledge graph community is extremely evangelical about what the "right way" is to do things. Imagine discussing politics on Twitter except with obscure references to information theory and linguistics.

Perhaps the biggest promoter of the term has been Philip Rathle from Neo4j, which offers the best-known graph database system for storing knowledge graphs. But here's where the confusion starts: Is a knowledge graph something you store, or is it how you store something? It's not just a knowledge graph—it's also a graph database. That distinction matters, but the boundaries are blurry.

Despite Philip's best efforts, the term "knowledge graph" remains ambiguous. Neo4j's messaging emphasizes being a "graph database." The word "knowledge" itself is slippery. People have a good grasp of information and data, but what is knowledge? Is it the result of enriching data? Is knowledge when you can take action on data? These questions don't have clean answers, which is part of why the conversations get so heated.

## It's Only a Model

Ultimately, a knowledge graph is a data model—how you organize data. There are many ways to do this at many levels of scale. I could derail this discussion by going the Lakehouse route and talking about Apache Iceberg, dbt, and file/object stores. That's data too, right? Sure, when you're talking about Petabytes (or more commonly Exabytes now). And perhaps that's the most confusing part of all: the same terms get applied in different ways depending on the context.

## Data in 3 Parts: The Triple

It's all about the triple:

**Subject → Predicate → Object**

That's it. When people talk about knowledge graphs, they're generally talking about a collection of triples. A triple represents a relationship between two data points. As late as the 1990s, it was still common to use "verbs" instead of "predicates". For instance, if Alice is the mother of Bob, you might express it with verbs:

- Alice → has → child
- Bob → is → child

Or with a predicate:

- Alice → isMotherOf → Bob

There are many ways to model this relationship, but predicates allow you to model more information in a single triple. In the "verbs" example, Alice and Bob aren't directly connected and would require additional triples to robustly connect them. But again, there are many ways to do this—hence the evangelical arguments.

## From Verbs to Predicates

As I often say, these concepts aren't new. The term "predicates" comes from predicate logic which has its origins in the 19th century. The use of predicates in the knowledge graph sense appeared in the 1960s with the rise of the concept of "semantic networks". The rise of the internet and the dream of the semantic web took "predicates" to the "mainstream".

## The Semantic Web and RDF

As the internet grew in scale during the 1990s and 2000s, technologists began asking: how can autonomous systems exchange information with each other? Sound familiar? That question is foundational to modern interoperability challenges like MCP and A2A—except those approaches treat it as if it's new, when in fact the semantic web community was thinking about this in the 1990s. I've personally worked with interoperable networking "protocols" in the aerospace industry that have their origins in the 1960s and are still in use today.

RDF (the Resource Description Framework) adds structure to the triple concept by introducing classes, types, ranges, and strict syntax rules. The semantic web aimed to make knowledge representation mainstream by providing a standard framework that anyone could use. What many find odd about RDF is its use of URIs (Uniform Resource Identifiers)—often in the form of URLs. Why use web addresses as identifiers? The vision was interoperability: having globally unique identifiers ensured that two systems using the same URI would be referring to the same entity. Do the URLs themselves matter? No. That's a fair source of confusion.

RDF supports multiple serialization formats:
- **RDF/XML** follows XML structure but is an absolute eye-sore for humans
- **N-Triples** is just a list of triples with required URIs for subjects and predicates—simpler, but still painful to read
- **JSON-LD** for those who like JSON
- **Turtle** is the most human-readable format, which is elegant but syntactically sensitive with its indentation and whitespace requirements

RDF is incredibly mature and robust. However, learning it independently is nearly impossible — the very definition of tribal knowledge. Without Mark Adams, co-founder of TrustGraph, writing RDF guides specifically for me, I would never have figured it out. Accurate RDF tutorials are hard to find, and many online articles are either wrong or skewed by singular perspectives.

## Understanding the RDF Stack

When people talk about "RDF," they're usually referring to more than just the basic RDF standard. RDF itself defines triples, but it's layered with complementary standards:

- **RDFS** (RDF Schema) adds types, properties, and structural constraints on top
- **OWL** (Web Ontology Language) is an extension of RDFS that adds rich ontology capabilities

In practice, people don't say "I'm using RDF and RDFS"—they think of this as a single ecosystem. When we say "RDF," we typically mean this entire layered collection of technologies, each building on the previous one.

## Property Graphs

Before I start this discussion, please fasten your seatbelt and take a deep breath. No malice is intended—I'm just trying to help explain some very confusing concepts. Yes, I'm about to dive into some of those evangelical arguments.

While a triple is a subject, predicate, and object (S, P, O), other terminology is commonly used in graph work: nodes, edges, and arcs. A node is a subject. When two nodes are connected, the relationship between them is an edge (sometimes called an arc, more commonly in European literature). For the object in a triple, it gets complicated: objects can be properties (literal values linked to a node) or relationships (links to other nodes).

Here's where property graphs and RDF fundamentally diverge: Property graphs strictly differentiate between properties (connections to literal values) and relationships (connections to nodes). It's a clean distinction. In RDF, you could use OWL to specify how things relate and RDFS range declarations to define what types of objects are permitted, providing much more flexibility than property graphs allow. RDF is more powerful, but property graphs are easier to understand.

Another key difference: property graphs allow properties on edges. You can model something similar in RDF, but edge properties are a simple way of doing something that becomes quite complex in RDF. This is a genuine advantage of the property graph approach.

As for standards: RDF developed as a modular, layered set of standards—competing ideas were tested, and the best ones emerged through real-world usage. Property graphs lack a formal standard, though Cypher (from Neo4j) became a de facto standard through widespread adoption. Other property graphs implemented it with variants. Very recently, this real-world usage influenced the development of an ISO standard, GQL. Unlike the modular RDF ecosystem, Cypher and GQL function more like single standards without the layered development that has been so productive in RDF's evolution.

## Ontologies

There's been considerable talk about ontologies recently. We launched custom ontology features in TrustGraph, and some have even used the term "OntologyRAG." But what exactly is an ontology?

To understand ontologies, it helps to differentiate four related but distinct concepts:

- **Vocabularies:** Human-readable definitions of words
- **Taxonomies:** Human-readable hierarchies and definitions for domain-specific terms
- **Schemas:** Machine-readable representations of data for storage and retrieval
- **Ontologies:** Machine-readable definitions of terms, hierarchies of those terms, and their relationships

OWL (Web Ontology Language) is one of the most common ontologies—it's an extension of RDF designed for building structured taxonomies. SKOS (Simple Knowledge Organization System) is another interesting ontology that focuses more on concepts than OWL but never achieved widespread adoption. Schema.org is perhaps the best known ontology—it's a direct extension of the semantic web that attempts to create a granular taxonomy for all types of information featured on websites.

Ontologies are fundamentally a semantic web concept, born from the vision of interoperable information exchange. This doesn't mean they're only useful with triplestores—you can use ontologies with property graphs as well. The distinction is about the origin of the concepts and their primary use cases.

## There's No Single "Right Way"

There's no "right way" to do any of this. You can use RDF or property graphs to store the same information. This point is crucial: no matter what any "expert" claims, you can store the same information as a triplestore, property graph, or even as joined tables. The choice is about what fits your use case, your team's expertise, and your operational requirements.

In fact, the default graph store in TrustGraph is Apache Cassandra. I remember when I first told Philip Rathle from Neo4j that our default graph store is Cassandra—I genuinely think he thought I was joking. He was even more skeptical when I mentioned that one of our users has over a billion nodes and edges loaded in Cassandra with TrustGraph (don't worry Philip, I know Neo4j will always be #1 in your heart). What's remarkable: this user could have used Neo4j instead. TrustGraph builds graphs as triplestores with RDF in Cassandra or translates them for storage in Neo4j. Does it matter that one is a triplestore and the other is a property graph? The agents we build don't seem to care.

## Machine Readable vs. Human Readable

While we marvel at the generative capabilities of LLMs, perhaps the biggest disruption is their ability to work with both human-readable and machine-readable data. An LLM can understand text, images, software code, complex schemas, and ontologies. Not only can it understand them, but it can output responses in combinations of all these formats.

Information systems are no longer bound by building custom retrieval algorithms for specific schemas and ontologies. An LLM can generate both the structure and the retrieval logic dynamically. This raises an interesting question: are there reasons to store machine-readable data with human-readable data?

This is where our experimental work became revealing. We tested various context structures—CSVs, symbol-based representations like "->", bulleted lists, numbered lists. Surely, with more concise structures, LLM outputs would improve, right? Wrong. Providing context in structured formats like Cypher or RDF improved responses despite the token overhead. Why? Because the structure itself carries information. When an LLM encounters Cypher or RDF (which it can read fluently), the structure encodes information about what is a node, what is a property, what is a relationship. There's inherent meaning in the syntax itself.

## Decades of Mature Graph Algorithms

Before we discard decades of knowledge, we should acknowledge the mature graph retrieval algorithms waiting to be leveraged: graph traversal depth optimization, clustering analysis, density calculations, outlier detection, and much more. These techniques establish relationships in data from the graph structure itself. Should we be surprised that LLMs already seem to be doing this intuitively?

## The Frontier: Temporal Context

As I discussed earlier this year on the *How AI Is Built* podcast (*Temporal RAG: Embracing Time for Smarter, Reliable Knowledge Graphs* from Feb 13, 2025) with Nico Gerold, temporal relationships are the next frontier for understanding data. While uncomfortable to confront, the concept of "truth" is often murky. One way of establishing ground truth is to find an observation that remains constant: that data point always was and always will be. But can you establish truth from a single observation?

When we begin to observe how data changes over time, we can assess whether information is "fresh" or "stale." Our instinct is to assume newer data is more trustworthy. Yet that's not always the case. Consider a contemporary example: UFO/UAP research.

When I was growing up in the 1980s, the subject of UFOs and aliens was taboo. Even with shows like *The X-Files* on prime time in the mid 1990s, being a fan guaranteed being labeled "the weird one." Today, we have documentaries like *The Age of Disclosure* where current government officials openly discuss the topic. The culture has shifted from dismissing the subject as fringe to openly considering whether the government will eventually acknowledge it.

But here's the puzzle: the data hasn't actually changed much. The observations documented decades ago in painstakingly researched books are largely the same observations being discussed today. Does repeated observation over 50+ years establish fact? When asking an LLM to analyze this information, should we prioritize 50-year-old data that still appears "fresh" and corroborated, or newer data that lacks observational confirmation? Freshness and recency are not the same as accuracy and precision. Just because data is old and obscure, doesn't mean it's not still valid.

## A New Paradigm for Interoperability

MCP and A2A set out to achieve a noble goal—interoperability. History confirms this has never been simple. My personal experience with interoperable systems has taught me that no matter how noble the goal, designing interoperable standards that can evolve and not balloon in complexity to the point of being a burden is a nearly impossible balance. Just look at the semantic web's unrealized promise. Yet LLMs provide a new opportunity: they enable us to work with dynamic ontologies as never before.

Previously, ontologies needed to be static so that retrieval algorithms could be built to understand them. LLMs can "read" and understand ontologies dynamically—as we've demonstrated with our recent ontology capabilities in TrustGraph. Perhaps LLMs will finally enable the vision of the semantic web, but with slightly different data structures and more flexible implementation patterns.

## The Progression: From RAG to Context Graphs

The AI journey we're on follows a clear progression:

1. **LLMs can answer questions from their training data**
2. **RAG appears:** We stuff prompts with chunks of text to add knowledge, realizing that LLM training data alone is insufficient using semantic similarity search over vector embeddings to find the text chunks
3. **GraphRAG emerges:** Breaking away from text chunks and semantic similarity search alone, we use flexible knowledge representations that can be navigated and refined for better control that capture rich relationships between entities, concepts, etc.
4. **Ontology RAG:** We take control over what gets loaded into graphs, using structured ontologies for precision and improved recall in how the relationships are annotated with improved granularity for retrieval

This progression is revealing. Step 3 (GraphRAG) makes minimal use of existing graph algorithms. Step 4 pulls ontologies from the toolbox. We're genuinely scratching the surface of what graph tooling can do.

This is where we are today. What comes next?

5. **Information retrieval analytics tuned to different data types:** We develop specialized retrieval strategies for temporal data, accuracy-sensitive data, anomalies, clustering, and other domain-specific information retrieval challenges
6. **Self-describing information stores:** Information systems that carry metadata about their own structure, allowing retrieval algorithms to adapt automatically to the information they encounter
7. **Dynamic information retrieval strategies:** LLMs can derive complete information retrieval strategies for information types they've never seen before, generalizing from learned patterns
8. **Closing the loop to enable autonomous learning:** As the system reingests its outputs, annotating the generative data with metadata, that can then adjust how that new information is retrieved in comparison to "old" data, and the ability to adjust the "old" structures as well is the holy grail of a true autonomous system that can learn

Context graphs represent the visions that so many information theorists dedicated their lives to pursuing. The opportunity is enormous.

## The Age of Building

As Kirk and I discussed in our recent [2025 State of RAG](https://youtu.be/W6m_BzaedUc) podcast, we both tend to believe the promised innovations are going to come - but just not as quickly as the hype train tends to predict. LLMs are an example of both forces in action. LLMs have achieved high levels of maturity incredibly quickly. However, the speed at which LLMs have reached that maturity have left a void in how to realize their potential. Enter Context Graphs.

If we look to AI leaders like [Ilya Sutskever](https://x.com/ilyasut) and [Yann Lecun](https://x.com/ylecun), both have moved on from LLMs to chasing the "next big thing" in AI with ventures that are very much designed as long term research organizations. When will that next big thing come? Likely it will require quantum computing to hit scale - which is a gigantic question mark. Most current quantum computing is still blending quantum approaches with varying amounts of classical computing (the way we've been doing computing since the invention of the transistor).

Or perhaps it won't be "one thing" that is the enabler. It rarely ever is. LLMs skyrocketed to maturity on the back of availability of data, rapidly increasing compute power, and a massive influx of capital. Will context graphs be a critical enabler to the next big thing in AI? We think so.

---

*Original post from [TrustGraph's](https://trustgraph.ai) site [here](https://trustgraph.ai/news/context-graph-manifesto/).*

*This article was retrieved from X/Twitter and converted to markdown.*
