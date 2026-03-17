# code scope

## socraticode

Give any AI instant automated knowledge of your entire codebase

* ref: https://github.com/giancarloerra/SocratiCode

```
claude mcp add socraticode -- npx -y socraticode
```

```
> claude
"Index this codebase"
"What is the codebase index status?"
```

### demo

```
git clone git@github.com:SOLEROM/ccpan.git  
cld
> "Index this codebase"


● Indexing in progress — 581 chunks across 124 files, currently generating embeddings. Let me check again in a moment.                                                                    

> docker ps
b44bb220fa10   ollama/ollama:latest     "/bin/ollama serve"   socraticode-ollama
68b19920421e   qdrant/qdrant:v1.17.0    "./entrypoint.sh" socraticode-qdrant


> What is the codebase index status?

● 54% complete — batch 2/3, 312/581 chunks embedded, 280 chunks already stored. Still in progress.

   Semantic search across an indexed codebase. Only use after codebase_index is complete (check codebase_status first). Returns relevant code chunks matching a natural language query.




> how authentication is handled?

❯ Search for how authentication is handled                                                                                                                                                      

● socraticode - codebase_search (MCP)(projectPath: "/tmp/a", query: "authentication login session token security middleware", limit: 10)
  ⎿  Search results for "authentication login session token security middleware" (10 matches):
        

```

