# local_embeddings.rb

reqyure 'boxcars'

# Example of an in memory vector-ization

root  = "./embeddings" 
store = Boxcars::VectorStore::InMemory::BuildFromFiles
          .call( 
            training_data_path: "#{root}/Notion_DB/**/*.md", 
            split_chunk_size:   900, 
            embedding_tool:     :openai 
          ) 

in_memory_search  = Boxcars::VectorSearch.new(
                      type:             :in_memory, 
                      vector_documents: store
                    )

in_memory_search.call(
  query_vector: store[:vector_store][0][:embedding], 
  count: 1
)


# With hash array

input_array = [ 
  { 
    content: "hello", 
    metadata: { a: 1 } 
  }, 
  { 
    content: "hi", 
    metadata: { a: 1 } 
  }, 
  { 
    content: "bye", 
    metadata: { a: 1 } 
  }, 
  { 
    content: "what's this", 
    metadata: { a: 1 } 
  } 
] 

store = Boxcars::VectorStore::InMemory::BuildFromArray
          .call( 
            embedding_tool: :openai, 
            input_array: input_array 
          ) 

in_memory_search  = Boxcars::VectorSearch.new(
                      type: :in_memory, 
                      vector_documents: store
                    )

search_result = in_memory_search.call(
                  query: "hello", 
                  count: 1
                )

puts search_result.first[:document].content 
# => "hello" 

puts search_result.first[:document].metadata 
# => {:a=>1, :dim=>1536}

# Pgvector
# follow official pgvector extension for installing and setup.

cd /tmp
git clone --branch v0.4.1 https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install

and then create a database and run the following sql to create the table and index.

createdb boxcars_development

conn ||= PG::Connection.new("postgres://postgres@localhost/boxcars_development")
conn.exec("CREATE EXTENSION IF NOT EXISTS vector")

# noteice that the number of dimensions is 1536
# the query vector we use with openai should also be 1536
create_table_query = <<-SQL
      CREATE TABLE IF NOT EXISTS items (
        id bigserial PRIMARY KEY,
        content text,
        embedding vector(1536),
        metadata jsonb
      );
    SQL
conn.exec(create_table_query)

=begin

With local markdown files
# path is relative to the code that you are running training_data_path = "./embeddings/Notion_DB/**/*.md" db_url = "postgres://postgres@localhost/boxcars_development" table_name = "items" embedding_column_name = "embedding" content_column_name = "content" metadata_column_name = "metadata" Boxcars::VectorStore::Pgvector::BuildFromFiles.call( training_data_path: training_data_path, split_chunk_size: 900, embedding_tool: :openai, database_url: db_url, table_name: table_name, embedding_column_name: embedding_column_name, content_column_name: content_column_name, metadata_column_name: metadata_column_name ) openai_client = Boxcars::Openai.open_ai_client(openai_access_token: ENV['OPENAI_API_KEY']) vector_documents = { type: :pgvector, vector_store: { database_url: db_url, table_name: table_name, embedding_column_name: embedding_column_name, content_column_name: content_column_name } } search = Boxcars::VectorSearch.new(openai_connection: openai_client, vector_documents: vector_documents) first_query = search.call(query: "How many holidays would I get?", count: 1) puts first_query.first[:document].content # => "there is money in our bank account and it’s up to us to spend it wisely. So yes, there is a budget. Just let us know if you think it’s reasonable for Blendle to pitch in.\n- **Blendle outings:** \nthe party agenda is pretty full. You’ll be invited when there is a party ahead.\n- **Flexible Holidays:** \nwe think 4-6 weeks off per year is kinda the sweet spot, with at least once 2 weeks in a row. So that’s what we put in your contract.\n- **Flexible hours**: \nwe want you to find out what works for you best. Just know that we don't keep track of hours. We trust you.\n- **Laptop**: \nwe provide you with a laptop that suits your job. Ask HR for further info.\n- **Workplace**: \nwe've built a pretty nice office to make sure you like being at Blendle HQ. Feel free to sit where you want. Even better: dare to switch your workplace every once in a while.\n\n# Work at Blendle\n\n---" second_query = search.call(query: "What should I do if someone is bullying me?", count: 1) puts second_query.first[:document].content # => "- **Talk to the offender**. If you suspect that an offender doesn’t realise they are guilty of harassment, you could talk to them directly in an effort to resolve the issue. This tactic is appropriate for cases of minor harassment (e.g. inappropriate jokes between colleagues, something you read on #overheard).\n- **Talk to your team lead**. Your team lead will assess your situation and may contact HR if appropriate. Explain the situation in as much detail as possible. If you have any hard evidence (e.g. emails), forward it or bring it with you to the meeting.\n- **Talk to HR**. Feel free to reach out to HR in any case of harassment no matter how minor it may seem. For your safety, contact HR as soon as possible in cases of serious harassment (e.g. sexual advances) or if your team lead is involved in your claim. Anything you disclose will remain confidential."
# With hash array
input_array = [ { content: "hello", metadata: { a: 1 } }, { content: "hi", metadata: { a: 1 } }, { content: "bye", metadata: { a: 1 } }, { content: "what's this", metadata: { a: 1 } } ] Boxcars::VectorStore::Pgvector::BuildFromArray.call( embedding_tool: :openai, input_array: input_array, database_url: db_url, table_name: table_name, embedding_column_name: embedding_column_name, content_column_name: content_column_name, metadata_column_name: metadata_column_name ) vector_documents = { type: :pgvector, vector_store: { database_url: db_url, table_name: table_name, embedding_column_name: embedding_column_name, content_column_name: content_column_name } } search = Boxcars::VectorSearch.new(openai_connection: openai_client, vector_documents: vector_documents) query = search.call(query: "bye", count: 1)
Hnswlib
Build the Vector Store
root = "./embeddings" store = Boxcars::VectorStore::Hnswlib::BuildFromFiles.call( training_data_path: "#{root}/Notion_DB/**/*.md", index_file_path: "#{root}/hnswlib_notion_db_index.bin", force_rebuild: true ) puts :built

Building Hnswlib vector store...
Added 50 files to data. Splitting text into chunks...
Loaded 50 files from /Users/francis/src/notebooks/boxcars/embeddings/Notion_DB/**/*.md
Split 50 files into 140 chunks
Generated 140 vectors
Added 140 vectors to vector store
built

Query the Store
openai_client = Boxcars::Openai.open_ai_client(openai_access_token: ENV['OPENAI_API_KEY']) similarity_search = Boxcars::VectorSearch.new( openai_connection: openai_client, vector_documents: store) ss = similarity_search.call query: "Do I get a laptop?", count: 1 ss.first[:document].content

"we provide you with a laptop that suits your job. Ask HR for further info.\n- **Workplace**: \nwe've built a pretty nice office to make sure you like being at Blendle HQ. Feel free to sit where you want. Even better: dare to switch your workplace every once in a while.\n\n# Work at Blendle\n\n---\n\nIf you want to work at Blendle you can check our [job ads here](https://blendle.homerun.co/). If you want to be kept in the loop about Blendle, you can sign up for [our behind the scenes newsletter](https://blendle.homerun.co/yes-keep-me-posted/tr/apply?token=8092d4128c306003d97dd3821bad06f2)."

Answer a Question from Search Results
va = Boxcars::VectorAnswer.new(embeddings: "#{root}/hnswlib_notion_db_index.json", vector_documents: store) va.conduct("Do I get a laptop?").to_answer

> Entering VectorAnswer#run
Do I get a laptop?
{"status":"ok","answer":"Yes, you will be provided with a laptop that suits your job. You can ask HR for further information.","explanation":"Answer: Yes, you will be provided with a laptop that suits your job. You can ask HR for further information."}
< Exiting VectorAnswer#run

"Yes, you will be provided with a laptop that suits your job. You can ask HR for further information."

More

You could of course use text files and get similar results. Other libraries can be brought it to handle PDFs and other binary formats. Add Issues and/or PRs for other types that you want supported.

=end
