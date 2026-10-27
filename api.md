Accessing the Europeana APIs using your API key
With minor exceptions (namely Thumbnail API, OAI-PMH, SPARQL), when accessing the Europeana APIs, you need to provide your access key (corresponding to your public key) or token (issued by the Auth Service) as part of the request.  

Using an API key (read-only access)
If you only want to access public information then supplying an access key is sufficient, however, if you need to access private information or contribute data to the APIs, then a token is mandatory. The preferred option for supplying an access key is using the “x-api-key” header but other options are also available. If you are accesing the Europeana APIs via a browser we recommend reading this guide. 

“X-Api-Key” header (preferred)
This option makes use of the standard “X-Api-Key” header to supply the key. This option is the preferred option due to its wide adoption and because it is a safer way to share your key within a request.    

Request



GET https://api.europeana.eu/...
X-Api-Key: [WSKEY]

-------------------------------
Type of resource

search

retrieval

display

recommendation

contribute

harvest / download

Record

Information about a cultural heritage object

 

✅Search API

✅SPARQL

✅Record API

✅IIIF APIs

✅Recommend API

❌

✅OAI-PMH

✅Downloads

Entity

Information about contextual resources that are related to the cultural heritage object

✅Entity API

✅SPARQL

✅Entity API

 

❌

✅Entity API

❌

User Set (ie. Gallery)

Information about galleries created by end-users

 

✅User Set API

✅User Set API

❌

✅User Set API

❌

Text Content

Digitized text extracted from images or a/v resources

✅Fulltext API
✅Fulltext Search API

✅Fulltext API

✅IIIF APIs

❌

✅Fulltext API

✅Downloads (partially)

Annotation

Complementary information about cultural heritage objects

✅Annotation API

✅Annotation API

❌

❌

✅Annotation API

❌
--------------------------------------------

API Documentaion (Seach online or ask me to retrive infomation you dont find here):
- https://europeana.atlassian.net/wiki/spaces/EF/pages/2385739812/Search+API+Documentation
- https://europeana.atlassian.net/wiki/spaces/EF/pages/2385674279/Record+API+Documentation
- https://europeana.atlassian.net/wiki/spaces/EF/pages/2385674279/Record+API+Documentation
- https://europeana.atlassian.net/wiki/spaces/EF/pages/2385674279/Record+API+Documentation