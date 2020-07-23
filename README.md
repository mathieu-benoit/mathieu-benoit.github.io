[![Build Status](https://dev.azure.com/mabenoit-ms/MyOwnBacklog/_apis/build/status/myblog?branchName=master)](https://dev.azure.com/mabenoit-ms/MyOwnBacklog/_build/latest?definitionId=127&branchName=master)

Build and run locally:

```
git clone https://github.com/mathieu-benoit/myblog
git submodule init
git submodule update
docker build -t blog .
docker run -d -p 8080:8080 blog
```
